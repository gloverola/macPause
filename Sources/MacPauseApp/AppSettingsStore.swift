import Foundation
import MacPauseCore

@MainActor
final class AppSettingsStore: ObservableObject {
    private enum Keys {
        static let armingCountdown = "macpause.armingCountdown"
        static let unlockHoldDuration = "macpause.unlockHoldDuration"
        static let sessionTimeout = "macpause.sessionTimeout"
        static let interactionMode = "macpause.interactionMode"
        static let backdropStyle = "macpause.backdropStyle"
    }

    @Published var armingCountdown: Double {
        didSet { persist(armingCountdown, key: Keys.armingCountdown) }
    }
    @Published var unlockHoldDuration: Double {
        didSet { persist(unlockHoldDuration, key: Keys.unlockHoldDuration) }
    }
    @Published var sessionTimeout: Double {
        didSet { persist(sessionTimeout, key: Keys.sessionTimeout) }
    }
    @Published var interactionMode: CleaningInteractionMode {
        didSet { persist(interactionMode.rawValue, key: Keys.interactionMode) }
    }
    @Published var backdropStyle: CleaningBackdropStyle {
        didSet { persist(backdropStyle.rawValue, key: Keys.backdropStyle) }
    }
    @Published private(set) var launchAtLoginState: LaunchAtLoginState
    @Published private(set) var launchAtLoginErrorMessage: String?

    private let defaults: UserDefaults
    private let launchAtLoginController: LaunchAtLoginControlling

    init(
        defaults: UserDefaults = .standard,
        launchAtLoginController: LaunchAtLoginControlling = LaunchAtLoginController()
    ) {
        self.defaults = defaults
        self.launchAtLoginController = launchAtLoginController
        armingCountdown = defaults.object(forKey: Keys.armingCountdown) as? Double ?? 3
        unlockHoldDuration = defaults.object(forKey: Keys.unlockHoldDuration) as? Double ?? 2
        sessionTimeout = defaults.object(forKey: Keys.sessionTimeout) as? Double ?? 60
        interactionMode = CleaningInteractionMode(
            rawValue: defaults.string(forKey: Keys.interactionMode) ?? ""
        ) ?? .fullLock
        backdropStyle = CleaningBackdropStyle(
            rawValue: defaults.string(forKey: Keys.backdropStyle) ?? ""
        ) ?? .classicHUD
        launchAtLoginState = launchAtLoginController.currentState()
    }

    var cleaningConfiguration: CleaningConfiguration {
        CleaningConfiguration(
            armingCountdown: armingCountdown,
            unlockHoldDuration: unlockHoldDuration,
            sessionTimeout: sessionTimeout,
            interactionMode: interactionMode,
            backdropStyle: backdropStyle
        )
    }

    func refreshLaunchAtLoginState() {
        launchAtLoginState = launchAtLoginController.currentState()
    }

    func setLaunchAtLoginEnabled(_ enabled: Bool) {
        launchAtLoginErrorMessage = nil

        do {
            launchAtLoginState = try launchAtLoginController.setEnabled(enabled)
        } catch {
            launchAtLoginErrorMessage = error.localizedDescription
            refreshLaunchAtLoginState()
        }
    }

    private func persist(_ value: Double, key: String) {
        defaults.set(value, forKey: key)
    }

    private func persist(_ value: String, key: String) {
        defaults.set(value, forKey: key)
    }
}
