import AppKit
import MacPauseCore
import SwiftUI

@MainActor
final class PermissionWindowController: NSWindowController {
    private static let preferredContentWidth: CGFloat = 548
    private static let minimumContentSize = NSSize(width: 520, height: 292)

    private let hostingController: NSHostingController<AnyView>

    init(
        sessionController: CleaningSessionController,
        applicationLifecycleController: ApplicationLifecycleControlling
    ) {
        let hostingController = NSHostingController(
            rootView: AnyView(
                PermissionView(
                    sessionController: sessionController,
                    applicationLifecycleController: applicationLifecycleController
                )
                .frame(width: Self.preferredContentWidth, alignment: .topLeading)
            )
        )
        self.hostingController = hostingController

        let window = NSWindow(contentViewController: hostingController)

        window.title = "Mac Pause Setup"
        window.setContentSize(Self.minimumContentSize)
        window.minSize = Self.minimumContentSize
        window.styleMask = [
            .titled,
            .closable
        ]
        window.isReleasedWhenClosed = false
        window.isOpaque = true
        window.appearance = NSAppearance(named: .darkAqua)
        window.backgroundColor = .windowBackgroundColor
        window.animationBehavior = .utilityWindow
        window.collectionBehavior = [.moveToActiveSpace]
        window.center()

        super.init(window: window)

        resizeToBestFittingSize()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func present() {
        guard let window else {
            return
        }

        resizeToBestFittingSize()

        if !window.isVisible {
            window.center()
        }

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func resizeToBestFittingSize() {
        guard let window else {
            return
        }

        hostingController.view.invalidateIntrinsicContentSize()
        let fittingSize = hostingController.view.fittingSize
        let screen = window.screen ?? NSScreen.main
        let maxHeight = max(
            Self.minimumContentSize.height,
            (screen?.visibleFrame.height ?? fittingSize.height) - 120
        )

        let contentSize = NSSize(
            width: max(Self.minimumContentSize.width, fittingSize.width),
            height: min(maxHeight, max(Self.minimumContentSize.height, fittingSize.height))
        )

        window.setContentSize(contentSize)
    }
}
