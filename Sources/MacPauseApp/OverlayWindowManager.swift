import AppKit
import MacPauseCore
import SwiftUI

@MainActor
final class OverlayWindowManager {
    private let sessionController: CleaningSessionController
    private var panels: [NSPanel] = []

    init(sessionController: CleaningSessionController) {
        self.sessionController = sessionController
    }

    func updateVisibility() {
        if sessionController.isOverlayVisible {
            presentOverlays()
        } else {
            dismissOverlays()
        }
    }

    private func presentOverlays() {
        let screens = NSScreen.screens

        if panels.count != screens.count {
            dismissOverlays()
            panels = screens.map(makePanel(for:))
        } else {
            for (panel, screen) in zip(panels, screens) {
                panel.setFrame(screen.frame, display: true)
            }
        }

        panels.forEach { $0.orderFrontRegardless() }
    }

    private func dismissOverlays() {
        panels.forEach { $0.orderOut(nil) }
        panels.removeAll()
    }

    private func makePanel(for screen: NSScreen) -> NSPanel {
        let panel = NSPanel(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false,
            screen: screen
        )

        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.appearance = NSAppearance(named: .darkAqua)
        panel.ignoresMouseEvents = true
        panel.level = .screenSaver
        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .ignoresCycle
        ]
        panel.contentView = NSHostingView(
            rootView: OverlayView(sessionController: sessionController)
        )

        return panel
    }
}
