import MacPauseCore
import SwiftUI

struct OverlayView: View {
    @ObservedObject var sessionController: CleaningSessionController

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backdropBackground
                    .ignoresSafeArea()

                panel(for: geometry.size)
            }
            .animation(.easeInOut(duration: 0.18), value: sessionController.phase)
            .animation(.linear(duration: 0.08), value: sessionController.unlockProgress)
        }
    }

    private func panel(for size: CGSize) -> some View {
        VStack(spacing: 0) {
            header
            separator

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 12) {
                    statusPane
                        .frame(width: 224, alignment: .topLeading)
                    detailStack
                }

                VStack(spacing: 12) {
                    statusPane
                    detailStack
                }
            }
            .padding(14)

            separator
            footer
        }
        .frame(width: max(420, min(size.width - 72, 680)))
        .macPauseSurface(cornerRadius: 14, fill: MacPauseTheme.hudFill)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "pause.circle.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(MacPauseTheme.aqua)

            VStack(alignment: .leading, spacing: 1) {
                Text("Mac Pause")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(MacPauseTheme.ink)

                Text(phaseHeaderSubtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(MacPauseTheme.inkMuted)
            }

            Spacer(minLength: 12)

            phaseBadge
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var statusPane: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(MacPauseTheme.ink)

            Text(subtitle)
                .font(.system(size: 12))
                .foregroundStyle(MacPauseTheme.inkMuted)
                .fixedSize(horizontal: false, vertical: true)

            separator

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(primaryValue)
                    .font(.system(size: primaryValue == "Done" ? 28 : 42, weight: .semibold))
                    .foregroundStyle(MacPauseTheme.ink)

                Text(primaryUnitLabel.uppercased())
                    .font(.system(size: 10.5, weight: .semibold))
                    .tracking(0.7)
                    .foregroundStyle(MacPauseTheme.inkMuted)
            }

            progressBar(progress: ringProgress, tint: phaseAccentColor)

            Text(metricCaption)
                .font(.system(size: 11))
                .foregroundStyle(MacPauseTheme.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .macPauseInsetSurface(cornerRadius: 10)
    }

    private var detailStack: some View {
        VStack(spacing: 10) {
            detailPanel(title: "Unlock Chord", icon: "keyboard", tint: MacPauseTheme.aqua) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        MacPauseKeyCap(title: "Right Shift", minWidth: 80)
                        Text("+")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(MacPauseTheme.inkMuted)
                        MacPauseKeyCap(title: "Esc", minWidth: 36)
                    }

                    Text("Hold continuously for \(Int(sessionController.configuration.unlockHoldDuration.rounded())) seconds to restore normal input.")
                        .font(.system(size: 11))
                        .foregroundStyle(MacPauseTheme.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            detailPanel(title: "Input State", icon: "cursorarrow.motionlines", tint: phaseAccentColor) {
                VStack(alignment: .leading, spacing: 6) {
                    statusLine(text: inputStateLabel, tint: phaseAccentColor)

                    Text(inputStateDetail)
                        .font(.system(size: 11))
                        .foregroundStyle(MacPauseTheme.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            detailPanel(title: "Screen", icon: "rectangle.on.rectangle", tint: MacPauseTheme.aqua) {
                VStack(alignment: .leading, spacing: 6) {
                    statusLine(text: sessionController.configuration.backdropStyle.displayName, tint: MacPauseTheme.aqua)

                    Text(screenDetail)
                        .font(.system(size: 11))
                        .foregroundStyle(MacPauseTheme.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            detailPanel(title: "Failsafe", icon: "timer", tint: MacPauseTheme.warning) {
                VStack(alignment: .leading, spacing: 6) {
                    statusLine(text: failsafeLabel, tint: MacPauseTheme.warning)

                    Text(failsafeDetail)
                        .font(.system(size: 11))
                        .foregroundStyle(MacPauseTheme.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func detailPanel<Content: View>(
        title: String,
        icon: String,
        tint: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(tint)

                Text(title.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.7)
                    .foregroundStyle(MacPauseTheme.inkMuted)
            }

            content()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .macPauseInsetSurface(cornerRadius: 10)
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Text(sessionController.statusMessage)
                .font(.system(size: 11))
                .foregroundStyle(MacPauseTheme.inkMuted)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 12)

            statusLine(text: phaseLabel, tint: phaseAccentColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func statusLine(text: String, tint: Color) -> some View {
        HStack(spacing: 7) {
            Circle()
                .fill(tint)
                .frame(width: 7, height: 7)

            Text(text)
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(MacPauseTheme.ink)
        }
    }

    private func progressBar(progress: CGFloat, tint: Color) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(MacPauseTheme.progressTrack)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .stroke(MacPauseTheme.insetLine, lineWidth: 1)
                    )

                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                tint.opacity(0.62),
                                tint
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: max(12, geometry.size.width * max(0.03, ringProgress)))
                    .overlay(alignment: .top) {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(Color.white.opacity(0.18))
                            .frame(height: 1)
                    }
            }
        }
        .frame(height: 14)
    }

    private var phaseBadge: some View {
        Text(phaseLabel.uppercased())
            .font(.system(size: 9.5, weight: .semibold))
            .tracking(0.7)
            .foregroundStyle(phaseAccentColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(phaseAccentColor.opacity(0.14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(phaseAccentColor.opacity(0.28), lineWidth: 1)
                    )
            )
    }

    private var separator: some View {
        Rectangle()
            .fill(MacPauseTheme.separator)
            .frame(height: 1)
            .padding(.horizontal, 1)
    }

    private var phaseLabel: String {
        switch sessionController.phase {
        case .idle:
            return "Idle"
        case .permissionsRequired:
            return "Setup"
        case .arming:
            return "Arming"
        case .active:
            return "Cleaning"
        case .unlocking:
            return "Unlocking"
        case .timedOut:
            return "Completed"
        }
    }

    private var phaseHeaderSubtitle: String {
        switch sessionController.phase {
        case .arming:
            return "Preparing to pause input"
        case .active:
            return "Keyboard and pointer are paused"
        case .unlocking:
            return "Restoring normal input"
        case .timedOut:
            return "Failsafe restored the session"
        case .permissionsRequired:
            return "Additional setup is required"
        case .idle:
            return "Ready for the next cleaning session"
        }
    }

    private var phaseAccentColor: Color {
        switch sessionController.phase {
        case .idle:
            return MacPauseTheme.aqua
        case .permissionsRequired:
            return MacPauseTheme.warning
        case .arming:
            return MacPauseTheme.aqua
        case .active:
            return MacPauseTheme.aqua
        case .unlocking:
            return MacPauseTheme.success
        case .timedOut:
            return MacPauseTheme.warning
        }
    }

    private var title: String {
        switch sessionController.phase {
        case .idle:
            return "Ready"
        case .permissionsRequired:
            return "Setup Required"
        case .arming:
            return "Cleaning mode is starting"
        case .active:
            return "Cleaning mode is active"
        case .unlocking:
            return "Unlock in progress"
        case .timedOut:
            return "Session ended"
        }
    }

    private var subtitle: String {
        switch sessionController.phase {
        case .idle:
            return "Mac Pause is waiting for the next cleaning session."
        case .permissionsRequired:
            return "Grant Accessibility and Input Monitoring, then return to Mac Pause."
        case .arming:
            return "Take your hands off the computer. \(sessionController.configuration.interactionMode.displayName) begins when the countdown reaches zero."
        case .active:
            return activeSubtitle
        case .unlocking:
            return "Keep the unlock chord held until the progress bar reaches the end."
        case .timedOut:
            return "The failsafe timer ended the session and restored normal input."
        }
    }

    private var ringProgress: CGFloat {
        switch sessionController.phase {
        case .arming:
            let total = max(sessionController.configuration.armingCountdown, 1)
            let remaining = min(Double(sessionController.armingSecondsRemaining), total)
            return CGFloat(max(0.04, min(1, 1 - remaining / total)))
        case .active:
            let total = max(sessionController.configuration.sessionTimeout, 1)
            let elapsed = total - sessionController.timeRemaining
            return CGFloat(max(0.06, min(1, elapsed / total)))
        case .unlocking:
            return CGFloat(max(0.06, min(1, sessionController.unlockProgress)))
        case .timedOut:
            return 1
        case .permissionsRequired:
            return 0.18
        case .idle:
            return 0.04
        }
    }

    private var primaryValue: String {
        switch sessionController.phase {
        case .arming:
            return "\(sessionController.armingSecondsRemaining)"
        case .active:
            return "\(Int(ceil(sessionController.timeRemaining)))"
        case .unlocking:
            return "\(Int(sessionController.unlockProgress * 100))"
        case .timedOut:
            return "Done"
        case .permissionsRequired:
            return "2"
        case .idle:
            return "Ready"
        }
    }

    private var primaryUnitLabel: String {
        switch sessionController.phase {
        case .arming:
            return "sec"
        case .active:
            return "sec left"
        case .unlocking:
            return "% unlock"
        case .timedOut:
            return "input restored"
        case .permissionsRequired:
            return "permissions"
        case .idle:
            return "standby"
        }
    }

    private var metricCaption: String {
        switch sessionController.phase {
        case .arming:
            return "The arming countdown is still running. Nothing is blocked yet."
        case .active:
            return "The safety timer is active while cleaning mode is running."
        case .unlocking:
            return "Release either key before completion and the unlock progress resets."
        case .timedOut:
            return "Failsafe exit completed successfully."
        case .permissionsRequired:
            return "Two permissions must be granted before the session can start."
        case .idle:
            return "Choose Start Cleaning from the menu bar to begin."
        }
    }

    private var inputStateLabel: String {
        switch sessionController.phase {
        case .arming:
            return "Standby"
        case .active, .unlocking:
            return sessionController.configuration.interactionMode.displayName
        case .timedOut:
            return "Input Restored"
        case .permissionsRequired:
            return "Setup Needed"
        case .idle:
            return "Normal Input"
        }
    }

    private var inputStateDetail: String {
        switch sessionController.phase {
        case .arming:
            return "Mac Pause is waiting for the countdown to finish before blocking anything."
        case .active, .unlocking:
            return activeInputDetail
        case .timedOut:
            return "Normal keyboard and mouse behavior has already been restored."
        case .permissionsRequired:
            return "Input blocking cannot start until both privacy permissions are granted."
        case .idle:
            return "The computer is operating normally."
        }
    }

    private var failsafeLabel: String {
        switch sessionController.phase {
        case .arming:
            return "Pending"
        case .active, .unlocking:
            return "Auto-exit in \(Int(ceil(sessionController.timeRemaining))) sec"
        case .timedOut:
            return "Failsafe Completed"
        case .permissionsRequired:
            return "Unavailable"
        case .idle:
            return "60 sec safety timer"
        }
    }

    private var failsafeDetail: String {
        switch sessionController.phase {
        case .arming:
            return "The 60 second safety timer starts as soon as cleaning mode becomes active."
        case .active, .unlocking:
            return "If the unlock chord is never completed, Mac Pause restores input automatically."
        case .timedOut:
            return "Mac Pause ended the session automatically to avoid trapping the machine."
        case .permissionsRequired:
            return "Failsafe timing is only available once a cleaning session has started."
        case .idle:
            return "Every session carries a fixed 60 second automatic exit."
        }
    }

    @ViewBuilder
    private var backdropBackground: some View {
        switch sessionController.configuration.backdropStyle {
        case .classicHUD:
            MacPauseTheme.overlayBackground
        case .blackout:
            Color.black
        case .neutralGray:
            Color(hex: 0xBDC3CB)
        case .whiteout:
            Color(hex: 0xF3F5F8)
        }
    }

    private var activeSubtitle: String {
        switch sessionController.configuration.interactionMode {
        case .fullLock:
            return "Keyboard, pointer movement, clicks, drags, and scrolling are currently suspended."
        case .keyboardOnly:
            return "Keyboard input is paused, while the pointer remains available for repositioning or display cleaning."
        case .pointerOnly:
            return "Pointer movement, clicks, drags, and scrolling are paused, while the keyboard remains available."
        }
    }

    private var activeInputDetail: String {
        switch sessionController.configuration.interactionMode {
        case .fullLock:
            return "Keyboard events, pointer movement, clicks, drags, and scrolling are being suppressed."
        case .keyboardOnly:
            return "Keyboard events and media keys are being suppressed, but pointer movement and clicks still work."
        case .pointerOnly:
            return "Pointer movement, clicks, drags, and scrolling are being suppressed, but keyboard input still works."
        }
    }

    private var screenDetail: String {
        switch sessionController.configuration.backdropStyle {
        case .classicHUD:
            return "The classic Mac Pause HUD stays on top while the desktop remains dimmed behind it."
        case .blackout:
            return "A solid black cleaning backdrop helps when wiping glossy displays or checking reflections."
        case .neutralGray:
            return "A mid-gray screen is useful for spotting dust without the contrast of a pure white background."
        case .whiteout:
            return "A bright white cleaning backdrop helps reveal smudges and streaks on the display."
        }
    }
}
