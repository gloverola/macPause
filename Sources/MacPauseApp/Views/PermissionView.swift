import MacPauseCore
import SwiftUI

struct PermissionView: View {
    @ObservedObject var sessionController: CleaningSessionController
    let applicationLifecycleController: ApplicationLifecycleControlling

    @State private var relaunchErrorMessage: String?

    private var isBundledApp: Bool {
        Bundle.main.bundleURL.pathExtension.lowercased() == "app"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            permissionsSection
            sessionDefaultsSection

            if !isBundledApp {
                developmentModeNotice
            }

            footer
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(MacPauseTheme.permissionBackground.ignoresSafeArea())
        .onAppear {
            sessionController.refreshPermissions()
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(MacPauseTheme.primaryButtonFill)

                Image(systemName: "pause.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 4) {
                Text("Mac Pause")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(MacPauseTheme.ink)

                Text("Enable the two privacy permissions used to suspend input while you clean.")
                    .font(.system(size: 12))
                    .foregroundStyle(MacPauseTheme.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            statusBadge(
                text: sessionController.permissionStatus.canBlockInput ? "Ready" : "Setup Required",
                tint: sessionController.permissionStatus.canBlockInput ? MacPauseTheme.success : MacPauseTheme.warning
            )
        }
        .padding(12)
        .macPauseSurface(cornerRadius: 12, fill: MacPauseTheme.chromeFill)
    }

    private var permissionsSection: some View {
        VStack(spacing: 0) {
            sectionHeader(
                title: "Required Permissions",
                detail: "System Settings > Privacy & Security"
            )

            permissionRow(
                title: "Accessibility",
                detail: "Allows Mac Pause to suppress keyboard, pointer, click, and scroll events.",
                location: "Privacy & Security > Accessibility",
                icon: "figure.stand",
                granted: sessionController.permissionStatus.accessibilityGranted,
                requestAction: sessionController.requestAccessibilityPermission,
                openSettingsAction: sessionController.openAccessibilitySettings
            )

            separator

            permissionRow(
                title: "Input Monitoring",
                detail: "Allows the app to detect the Right Shift + Escape unlock chord. macOS may require a quit and reopen after you enable it.",
                location: "Privacy & Security > Input Monitoring",
                icon: "keyboard",
                granted: sessionController.permissionStatus.inputMonitoringGranted,
                settingsButtonTitle: "Open Privacy",
                helperText: "Direct links to Input Monitoring are inconsistent on current macOS builds. If Privacy & Security opens instead, select Input Monitoring in the sidebar and enable Mac Pause manually.",
                requestAction: sessionController.requestInputMonitoringPermission,
                openSettingsAction: sessionController.openInputMonitoringSettings
            )
        }
        .macPauseSurface(cornerRadius: 10)
    }

    private var sessionDefaultsSection: some View {
        VStack(spacing: 0) {
            sectionHeader(
                title: "Cleaning Session",
                detail: "Default behavior once setup is complete"
            )

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    compactSettingPill(
                        title: "Scope",
                        value: sessionController.nextSessionConfiguration.interactionMode.displayName
                    )
                    compactSettingPill(
                        title: "Screen",
                        value: sessionController.nextSessionConfiguration.backdropStyle.displayName
                    )
                }

                HStack(spacing: 8) {
                    utilityCell(
                        title: "Countdown",
                        value: durationLabel(sessionController.nextSessionConfiguration.armingCountdown),
                        detail: "A short arming delay before input is paused."
                    )

                    utilityCell(
                        title: "Unlock",
                        detail: "Hold the chord for \(durationLabel(sessionController.nextSessionConfiguration.unlockHoldDuration))."
                    ) {
                        HStack(spacing: 5) {
                            MacPauseKeyCap(title: "Right Shift", minWidth: 78)
                            Text("+")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(MacPauseTheme.inkMuted)
                            MacPauseKeyCap(title: "Esc", minWidth: 36)
                        }
                    }

                    utilityCell(
                        title: "Failsafe",
                        value: durationLabel(sessionController.nextSessionConfiguration.sessionTimeout),
                        detail: "Normal input is restored automatically."
                    )
                }
            }
            .padding(10)
        }
        .macPauseSurface(cornerRadius: 10)
    }

    private var developmentModeNotice: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(MacPauseTheme.warning)

            Text("Privacy status can read incorrectly when Mac Pause is launched as a raw executable instead of the bundled .app.")
                .font(.system(size: 11))
                .foregroundStyle(MacPauseTheme.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .macPauseInsetSurface(cornerRadius: 8)
    }

    private var footer: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 10) {
                footerMessage
                Spacer(minLength: 10)
                footerButtons
            }

            VStack(alignment: .leading, spacing: 10) {
                footerMessage
                footerButtons
            }
        }
        .padding(12)
        .macPauseSurface(cornerRadius: 10, fill: MacPauseTheme.chromeFill)
        .alert(
            "Mac Pause",
            isPresented: Binding(
                get: { relaunchErrorMessage != nil },
                set: { if !$0 { relaunchErrorMessage = nil } }
            ),
            actions: {
                Button("OK", role: .cancel) {
                    relaunchErrorMessage = nil
                }
            },
            message: {
                Text(relaunchErrorMessage ?? "")
            }
        )
    }

    private var footerMessage: some View {
        Text(sessionController.statusMessage)
            .font(.system(size: 11))
            .foregroundStyle(MacPauseTheme.inkMuted)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var footerButtons: some View {
        HStack(spacing: 8) {
            Button("Refresh") {
                sessionController.refreshPermissions()
            }
            .buttonStyle(MacPauseBezelButtonStyle())

            Button("Open Privacy") {
                sessionController.openPrivacyAndSecuritySettings()
            }
            .buttonStyle(MacPauseBezelButtonStyle())

            if shouldShowRelaunchButton {
                Button("Quit & Reopen") {
                    do {
                        try applicationLifecycleController.relaunch()
                    } catch {
                        relaunchErrorMessage = error.localizedDescription
                    }
                }
                .buttonStyle(MacPauseBezelButtonStyle())
            }

            Button("Start Cleaning") {
                sessionController.startCleaning()
            }
            .buttonStyle(MacPauseBezelButtonStyle(kind: .primary))
            .disabled(!sessionController.permissionStatus.canBlockInput)
        }
    }

    private func permissionRow(
        title: String,
        detail: String,
        location: String,
        icon: String,
        granted: Bool,
        settingsButtonTitle: String = "Show",
        helperText: String? = nil,
        requestAction: @escaping () -> Void,
        openSettingsAction: @escaping () -> Void
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            permissionIcon(icon, granted: granted)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(MacPauseTheme.ink)

                Text(detail)
                    .font(.system(size: 11.5))
                    .foregroundStyle(MacPauseTheme.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)

                Text(location)
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(MacPauseTheme.aquaStrong)

                if let helperText {
                    Text(helperText)
                        .font(.system(size: 10.5))
                        .foregroundStyle(MacPauseTheme.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 8) {
                statusBadge(
                    text: granted ? "Granted" : "Required",
                    tint: granted ? MacPauseTheme.success : MacPauseTheme.warning
                )

                HStack(spacing: 6) {
                    Button(settingsButtonTitle) {
                        openSettingsAction()
                    }
                    .buttonStyle(MacPauseBezelButtonStyle())

                    if !granted {
                        Button("Request") {
                            requestAction()
                        }
                        .buttonStyle(MacPauseBezelButtonStyle(kind: .primary))
                    }
                }
            }
            .frame(minWidth: 144, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
    }

    private func permissionIcon(_ systemName: String, granted: Bool) -> some View {
        let tint = granted ? MacPauseTheme.success : MacPauseTheme.warning

        return ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(tint.opacity(0.16))

            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(tint)
        }
        .frame(width: 28, height: 28)
    }

    private func compactSettingPill(title: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 9.5, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(MacPauseTheme.inkMuted)

            Text(value)
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(MacPauseTheme.ink)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .macPauseInsetSurface(cornerRadius: 7)
    }

    private func utilityCell(
        title: String,
        value: String? = nil,
        detail: String,
        @ViewBuilder content: () -> some View = { EmptyView() }
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(MacPauseTheme.inkMuted)

            if let value {
                Text(value)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(MacPauseTheme.ink)
            } else {
                content()
            }

            Text(detail)
                .font(.system(size: 10.5))
                .foregroundStyle(MacPauseTheme.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .topLeading)
        .padding(10)
        .macPauseInsetSurface(cornerRadius: 8)
    }

    private func sectionHeader(title: String, detail: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(MacPauseTheme.inkMuted)

            Spacer(minLength: 10)

            Text(detail)
                .font(.system(size: 10.5))
                .foregroundStyle(MacPauseTheme.inkMuted)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
    }

    private func statusBadge(text: String, tint: Color) -> some View {
        Text(text.uppercased())
            .font(.system(size: 9.5, weight: .semibold))
            .tracking(0.6)
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(tint.opacity(0.14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(tint.opacity(0.26), lineWidth: 1)
                    )
            )
    }

    private var separator: some View {
        Rectangle()
            .fill(MacPauseTheme.separator)
            .frame(height: 1)
            .padding(.horizontal, 1)
    }

    private var shouldShowRelaunchButton: Bool {
        isBundledApp &&
        sessionController.permissionStatus.accessibilityGranted &&
        !sessionController.permissionStatus.inputMonitoringGranted
    }

    private func durationLabel(_ value: Double) -> String {
        if value == 0 {
            return "None"
        }

        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(value)) sec"
        }

        return String(format: "%.1f sec", value)
    }
}
