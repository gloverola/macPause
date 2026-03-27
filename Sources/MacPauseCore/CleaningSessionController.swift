import Combine
import Foundation

@MainActor
public final class CleaningSessionController: ObservableObject {
    public enum Phase: String, Sendable {
        case idle
        case permissionsRequired
        case arming
        case active
        case unlocking
        case timedOut
    }

    enum SessionEndReason {
        case completed
        case interrupted(String)
        case timedOut
        case cancelled
    }

    @Published public private(set) var phase: Phase = .idle
    @Published public private(set) var armingSecondsRemaining = 0
    @Published public private(set) var timeRemaining: TimeInterval = 0
    @Published public private(set) var unlockProgress = 0.0
    @Published public private(set) var permissionStatus: PermissionStatus
    @Published public private(set) var statusMessage = "Ready to clean."
    @Published public private(set) var configuration: CleaningConfiguration

    public private(set) var defaultConfiguration: CleaningConfiguration

    private let inputBlocker: InputBlocking
    private let permissionsController: PermissionControlling

    private var armingTimer: Timer?
    private var sessionTimer: Timer?
    private var idleResetTimer: Timer?
    private var armingDeadline: Date?
    private var sessionDeadline: Date?

    public init(
        configuration: CleaningConfiguration = .init(),
        inputBlocker: InputBlocking,
        permissionsController: PermissionControlling
    ) {
        self.configuration = configuration
        self.defaultConfiguration = configuration
        self.inputBlocker = inputBlocker
        self.permissionsController = permissionsController
        self.permissionStatus = permissionsController.refreshStatus()
        self.inputBlocker.updateUnlockHoldDuration(configuration.unlockHoldDuration)
        self.inputBlocker.updateInteractionMode(configuration.interactionMode)

        inputBlocker.onUnlockProgress = { [weak self] progress in
            Task { @MainActor [weak self] in
                self?.handleUnlockProgress(progress)
            }
        }

        inputBlocker.onUnlockCompleted = { [weak self] in
            Task { @MainActor [weak self] in
                self?.finishSession(reason: .completed)
            }
        }

        inputBlocker.onBlockerInterruption = { [weak self] message in
            Task { @MainActor [weak self] in
                self?.finishSession(reason: .interrupted(message))
            }
        }
    }

    public var canStartCleaning: Bool {
        permissionStatus.canBlockInput && [
            Phase.idle,
            .permissionsRequired,
            .timedOut
        ].contains(phase)
    }

    public var isOverlayVisible: Bool {
        [
            Phase.arming,
            .active,
            .unlocking,
            .timedOut
        ].contains(phase)
    }

    public var unlockInstruction: String {
        "Hold Right Shift + Escape for \(Int(configuration.unlockHoldDuration.rounded())) seconds to end cleaning."
    }

    public var interactionSummary: String {
        configuration.interactionMode.displayName
    }

    public var nextSessionConfiguration: CleaningConfiguration {
        defaultConfiguration
    }

    @discardableResult
    public func refreshPermissions() -> PermissionStatus {
        let status = permissionsController.refreshStatus()
        permissionStatus = status

        if !status.canBlockInput && phase == .idle {
            statusMessage = permissionStatusMessage(for: status)
        } else if status.canBlockInput && phase == .permissionsRequired {
            phase = .idle
            statusMessage = "Permissions granted. Ready to clean."
        }

        return status
    }

    public func requestPermissions() {
        permissionsController.requestPermissions()
        applyPermissionRefresh()
    }

    public func requestAccessibilityPermission() {
        permissionsController.requestAccessibilityPermission()
        applyPermissionRefresh()
    }

    public func requestInputMonitoringPermission() {
        permissionsController.requestInputMonitoringPermission()
        applyPermissionRefresh()
    }

    public func openAccessibilitySettings() {
        _ = permissionsController.openAccessibilitySettings()
        phase = .permissionsRequired
        statusMessage = "Open System Settings > Privacy & Security > Accessibility, enable Mac Pause, then return here."
    }

    public func openInputMonitoringSettings() {
        _ = permissionsController.openInputMonitoringSettings()
        phase = .permissionsRequired
        statusMessage = "Open System Settings > Privacy & Security, choose Input Monitoring, enable Mac Pause, then quit and reopen the app."
    }

    public func openPrivacyAndSecuritySettings() {
        _ = permissionsController.openPrivacyAndSecuritySettings()
        phase = .permissionsRequired
        statusMessage = "Open System Settings > Privacy & Security, then enable the remaining Mac Pause permissions."
    }

    public func updateDefaultConfiguration(_ configuration: CleaningConfiguration) {
        defaultConfiguration = configuration

        guard ![
            Phase.arming,
            .active,
            .unlocking
        ].contains(phase) else {
            return
        }

        applyConfiguration(configuration)
    }

    public func startCleaning(using configurationOverride: CleaningConfiguration? = nil) {
        guard [
            Phase.idle,
            .permissionsRequired,
            .timedOut
        ].contains(phase) else {
            return
        }

        idleResetTimer?.invalidate()
        let status = refreshPermissions()

        guard status.canBlockInput else {
            phase = .permissionsRequired
            statusMessage = "Grant Accessibility and Input Monitoring to start cleaning mode."
            return
        }

        applyConfiguration(configurationOverride ?? defaultConfiguration)
        beginArming()
    }

    public func cancelCleaning() {
        finishSession(reason: .cancelled)
    }

    func activateCleaningMode() {
        invalidateArmingTimer()

        do {
            try inputBlocker.startBlocking()
        } catch {
            phase = .permissionsRequired
            statusMessage = error.localizedDescription
            refreshPermissions()
            return
        }

        unlockProgress = 0
        phase = .active
        statusMessage = "Cleaning mode active."
        sessionDeadline = Date().addingTimeInterval(configuration.sessionTimeout)
        timeRemaining = configuration.sessionTimeout
        scheduleSessionTimer()
    }

    func handleUnlockProgress(_ progress: Double) {
        guard phase == .active || phase == .unlocking else {
            return
        }

        unlockProgress = progress

        if progress > 0 {
            phase = .unlocking
            statusMessage = "Keep holding Right Shift + Escape to exit."
        } else {
            phase = .active
            statusMessage = "Cleaning mode active."
        }
    }

    func timeoutCleaningSession() {
        finishSession(reason: .timedOut)
    }

    private func beginArming() {
        invalidateAllTimers()
        armingDeadline = Date().addingTimeInterval(configuration.armingCountdown)
        armingSecondsRemaining = max(1, Int(ceil(configuration.armingCountdown)))
        phase = .arming
        statusMessage = "Cleaning mode starts after the countdown."

        guard configuration.armingCountdown > 0 else {
            activateCleaningMode()
            return
        }

        armingTimer = Timer.scheduledTimer(
            withTimeInterval: 0.1,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateArmingCountdown()
            }
        }
        RunLoop.main.add(armingTimer!, forMode: .common)
    }

    private func updateArmingCountdown() {
        guard let armingDeadline else {
            return
        }

        let remaining = armingDeadline.timeIntervalSinceNow

        if remaining <= 0 {
            activateCleaningMode()
            return
        }

        armingSecondsRemaining = max(1, Int(ceil(remaining)))
    }

    private func scheduleSessionTimer() {
        invalidateSessionTimer()

        sessionTimer = Timer.scheduledTimer(
            withTimeInterval: 0.05,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateSessionTimer()
            }
        }
        RunLoop.main.add(sessionTimer!, forMode: .common)
    }

    private func updateSessionTimer() {
        guard let sessionDeadline else {
            return
        }

        let remaining = sessionDeadline.timeIntervalSinceNow

        if remaining <= 0 {
            timeoutCleaningSession()
            return
        }

        timeRemaining = remaining
    }

    private func finishSession(reason: SessionEndReason) {
        invalidateAllTimers()
        inputBlocker.stopBlocking()
        armingDeadline = nil
        sessionDeadline = nil
        armingSecondsRemaining = 0
        timeRemaining = 0
        unlockProgress = 0

        switch reason {
        case .completed:
            phase = .idle
            statusMessage = "Cleaning mode ended."
        case .interrupted(let message):
            phase = .idle
            statusMessage = message
        case .timedOut:
            phase = .timedOut
            statusMessage = "Cleaning mode ended automatically."
            scheduleIdleReset()
        case .cancelled:
            phase = .idle
            statusMessage = "Cleaning mode cancelled."
        }

        applyConfiguration(defaultConfiguration)
    }

    private func scheduleIdleReset() {
        idleResetTimer?.invalidate()

        idleResetTimer = Timer.scheduledTimer(
            withTimeInterval: 1.2,
            repeats: false
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.phase == .timedOut else {
                    return
                }

                self.phase = .idle
                self.statusMessage = "Ready to clean."
            }
        }
        RunLoop.main.add(idleResetTimer!, forMode: .common)
    }

    private func invalidateAllTimers() {
        invalidateArmingTimer()
        invalidateSessionTimer()
        idleResetTimer?.invalidate()
        idleResetTimer = nil
    }

    private func invalidateArmingTimer() {
        armingTimer?.invalidate()
        armingTimer = nil
    }

    private func invalidateSessionTimer() {
        sessionTimer?.invalidate()
        sessionTimer = nil
    }

    private func applyPermissionRefresh() {
        permissionStatus = permissionsController.refreshStatus()

        guard ![
            Phase.arming,
            .active,
            .unlocking
        ].contains(phase) else {
            return
        }

        if permissionStatus.canBlockInput {
            phase = .idle
            statusMessage = "Permissions granted. Ready to clean."
        } else {
            phase = .permissionsRequired
            statusMessage = permissionStatusMessage(for: permissionStatus)
        }
    }

    private func applyConfiguration(_ configuration: CleaningConfiguration) {
        self.configuration = configuration
        inputBlocker.updateUnlockHoldDuration(configuration.unlockHoldDuration)
        inputBlocker.updateInteractionMode(configuration.interactionMode)
    }

    private func permissionStatusMessage(for status: PermissionStatus) -> String {
        if !status.accessibilityGranted && !status.inputMonitoringGranted {
            return "Accessibility and Input Monitoring are still required."
        }

        if !status.accessibilityGranted {
            return "Accessibility is still required."
        }

        return "Input Monitoring is still required. If you just enabled it, quit and reopen Mac Pause."
    }
}
