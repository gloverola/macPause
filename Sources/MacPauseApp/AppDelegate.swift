import AppKit
import Combine
import MacPauseCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var sessionController: CleaningSessionController?
    private var settingsStore: AppSettingsStore?
    private var menuBarController: MenuBarController?
    private var permissionWindowController: PermissionWindowController?
    private var settingsWindowController: SettingsWindowController?
    private var overlayWindowManager: OverlayWindowManager?
    private var applicationLifecycleController: ApplicationLifecycleController?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
        NSApp.appearance = NSAppearance(named: .darkAqua)

        let settingsStore = AppSettingsStore()
        let configuration = settingsStore.cleaningConfiguration
        let permissionsController = PermissionsController()
        let applicationLifecycleController = ApplicationLifecycleController()
        let inputBlocker = CGEventInputBlocker(
            unlockHoldDuration: configuration.unlockHoldDuration
        )
        let sessionController = CleaningSessionController(
            configuration: configuration,
            inputBlocker: inputBlocker,
            permissionsController: permissionsController
        )

        let permissionWindowController = PermissionWindowController(
            sessionController: sessionController,
            applicationLifecycleController: applicationLifecycleController
        )
        let settingsWindowController = SettingsWindowController(
            sessionController: sessionController,
            settingsStore: settingsStore,
            applicationLifecycleController: applicationLifecycleController
        )
        let overlayWindowManager = OverlayWindowManager(
            sessionController: sessionController
        )
        let menuBarController = MenuBarController(
            sessionController: sessionController,
            permissionWindowController: permissionWindowController,
            settingsWindowController: settingsWindowController
        )

        self.sessionController = sessionController
        self.settingsStore = settingsStore
        self.permissionWindowController = permissionWindowController
        self.settingsWindowController = settingsWindowController
        self.overlayWindowManager = overlayWindowManager
        self.menuBarController = menuBarController
        self.applicationLifecycleController = applicationLifecycleController

        bind(
            sessionController: sessionController,
            settingsStore: settingsStore
        )
        sessionController.refreshPermissions()
    }

    func applicationWillTerminate(_ notification: Notification) {
        sessionController?.cancelCleaning()
    }

    private func bind(
        sessionController: CleaningSessionController,
        settingsStore: AppSettingsStore
    ) {
        sessionController.$phase
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.overlayWindowManager?.updateVisibility()
            }
            .store(in: &cancellables)

        Publishers.CombineLatest(
            Publishers.CombineLatest4(
                settingsStore.$armingCountdown,
                settingsStore.$unlockHoldDuration,
                settingsStore.$sessionTimeout,
                settingsStore.$interactionMode
            ),
            settingsStore.$backdropStyle
        )
            .receive(on: RunLoop.main)
            .sink { [weak sessionController, weak settingsStore] _, _ in
                guard let settingsStore else {
                    return
                }

                sessionController?.updateDefaultConfiguration(
                    settingsStore.cleaningConfiguration
                )
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(
            for: NSApplication.didBecomeActiveNotification
        )
        .receive(on: RunLoop.main)
        .sink { [weak sessionController, weak settingsStore] _ in
            sessionController?.refreshPermissions()
            settingsStore?.refreshLaunchAtLoginState()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                sessionController?.refreshPermissions()
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                sessionController?.refreshPermissions()
            }
        }
        .store(in: &cancellables)
    }
}
