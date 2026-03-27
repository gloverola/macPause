import MacPauseCore
import SwiftUI

struct SettingsView: View {
    @ObservedObject var sessionController: CleaningSessionController
    @ObservedObject var settingsStore: AppSettingsStore
    let applicationLifecycleController: ApplicationLifecycleControlling

    private let countdownOptions: [Double] = [0, 3, 5, 10]
    private let unlockOptions: [Double] = [1, 1.5, 2, 3]
    private let timeoutOptions: [Double] = [15, 30, 60, 90]

    @State private var relaunchErrorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            sessionDefaultsSection
            launchAtLoginSection
            footer
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(MacPauseTheme.permissionBackground.ignoresSafeArea())
        .onAppear {
            settingsStore.refreshLaunchAtLoginState()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("Settings")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(MacPauseTheme.ink)

                Spacer(minLength: 12)

                statusBadge(
                    text: isSessionLive ? "Applies Next Session" : "Defaults",
                    tint: isSessionLive ? MacPauseTheme.warning : MacPauseTheme.aqua
                )
            }

            Text("Adjust the default countdown, unlock hold, timeout, and launch behavior.")
                .font(.system(size: 12))
                .foregroundStyle(MacPauseTheme.inkMuted)
        }
        .padding(12)
        .macPauseSurface(cornerRadius: 12, fill: MacPauseTheme.chromeFill)
    }

    private var sessionDefaultsSection: some View {
        VStack(spacing: 0) {
            sectionHeader(
                title: "Default Session",
                detail: "Used by Start Cleaning"
            )

            settingsRow(
                title: "Arming Countdown",
                detail: "Delay before Mac Pause starts blocking input."
            ) {
                Picker("Arming Countdown", selection: $settingsStore.armingCountdown) {
                    ForEach(countdownOptions, id: \.self) { option in
                        Text(durationLabel(option)).tag(option)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 120)
            }

            separator

            settingsRow(
                title: "Unlock Hold",
                detail: "How long Right Shift + Escape must be held."
            ) {
                Picker("Unlock Hold", selection: $settingsStore.unlockHoldDuration) {
                    ForEach(unlockOptions, id: \.self) { option in
                        Text(durationLabel(option)).tag(option)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 120)
            }

            separator

            settingsRow(
                title: "Pause Scope",
                detail: "Choose whether Mac Pause blocks both devices or only one."
            ) {
                Picker("Pause Scope", selection: $settingsStore.interactionMode) {
                    ForEach(CleaningInteractionMode.allCases, id: \.rawValue) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 140)
            }

            separator

            settingsRow(
                title: "Failsafe Timeout",
                detail: "Automatic exit if the unlock chord is never completed."
            ) {
                Picker("Failsafe Timeout", selection: $settingsStore.sessionTimeout) {
                    ForEach(timeoutOptions, id: \.self) { option in
                        Text(durationLabel(option)).tag(option)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 120)
            }

            separator

            settingsRow(
                title: "Screen Backdrop",
                detail: "Use a solid cleaning screen without changing the lock behavior."
            ) {
                Picker("Screen Backdrop", selection: $settingsStore.backdropStyle) {
                    ForEach(CleaningBackdropStyle.allCases, id: \.rawValue) { style in
                        Text(style.displayName).tag(style)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 140)
            }
        }
        .macPauseSurface(cornerRadius: 10)
    }

    private var launchAtLoginSection: some View {
        VStack(spacing: 0) {
            sectionHeader(
                title: "Launch at Login",
                detail: "Starts Mac Pause after sign in"
            )

            VStack(alignment: .leading, spacing: 10) {
                Toggle(
                    isOn: Binding(
                        get: { settingsStore.launchAtLoginState.isEnabled },
                        set: { settingsStore.setLaunchAtLoginEnabled($0) }
                    )
                ) {
                    Text("Open Mac Pause automatically at login")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(MacPauseTheme.ink)
                }
                .toggleStyle(.switch)
                .disabled(!settingsStore.launchAtLoginState.isAvailable)

                Text(settingsStore.launchAtLoginState.detail)
                    .font(.system(size: 11))
                    .foregroundStyle(settingsStore.launchAtLoginState.requiresApproval ? MacPauseTheme.warning : MacPauseTheme.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)

                if let launchAtLoginErrorMessage = settingsStore.launchAtLoginErrorMessage {
                    Text(launchAtLoginErrorMessage)
                        .font(.system(size: 11))
                        .foregroundStyle(MacPauseTheme.warning)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(12)
        }
        .macPauseSurface(cornerRadius: 10)
    }

    private var footer: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                footerMessage
                Spacer(minLength: 8)
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
        Text(isSessionLive ? "The current session keeps its existing timing. New defaults apply the next time you start cleaning." : "Changes are saved immediately.")
            .font(.system(size: 11))
            .foregroundStyle(MacPauseTheme.inkMuted)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var footerButtons: some View {
        HStack(spacing: 8) {
            Button("Refresh Login Item") {
                settingsStore.refreshLaunchAtLoginState()
            }
            .buttonStyle(MacPauseBezelButtonStyle())

            Button("Quit & Reopen") {
                do {
                    try applicationLifecycleController.relaunch()
                } catch {
                    relaunchErrorMessage = error.localizedDescription
                }
            }
            .buttonStyle(MacPauseBezelButtonStyle())

            Button("Permissions…") {
                sessionController.openPrivacyAndSecuritySettings()
            }
            .buttonStyle(MacPauseBezelButtonStyle(kind: .primary))
        }
    }

    private func settingsRow<Content: View>(
        title: String,
        detail: String,
        @ViewBuilder control: () -> Content
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(MacPauseTheme.ink)

                Text(detail)
                    .font(.system(size: 11))
                    .foregroundStyle(MacPauseTheme.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)
            control()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
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

    private var isSessionLive: Bool {
        [
            CleaningSessionController.Phase.arming,
            .active,
            .unlocking
        ].contains(sessionController.phase)
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
