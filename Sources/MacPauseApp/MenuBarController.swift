import AppKit
import Combine
import MacPauseCore

@MainActor
final class MenuBarController: NSObject, NSMenuDelegate {
    private let sessionController: CleaningSessionController
    private weak var permissionWindowController: PermissionWindowController?
    private weak var settingsWindowController: SettingsWindowController?

    private let statusItem = NSStatusBar.system.statusItem(
        withLength: NSStatusItem.squareLength
    )
    private let menu = NSMenu()
    private let statusMenuItem = NSMenuItem()
    private let detailsMenuItem = NSMenuItem()
    private let actionMenuItem = NSMenuItem()
    private let presetMenuItem = NSMenuItem()
    private let presetMenu = NSMenu(title: "Preset Sessions")
    private var presetItems: [NSMenuItem] = []
    private let settingsMenuItem = NSMenuItem()
    private let permissionsMenuItem = NSMenuItem()
    private let helpMenuItem = NSMenuItem()
    private let uninstallMenuItem = NSMenuItem()
    private let quitMenuItem = NSMenuItem()

    private var cancellables = Set<AnyCancellable>()

    init(
        sessionController: CleaningSessionController,
        permissionWindowController: PermissionWindowController,
        settingsWindowController: SettingsWindowController
    ) {
        self.sessionController = sessionController
        self.permissionWindowController = permissionWindowController
        self.settingsWindowController = settingsWindowController
        super.init()

        configureStatusItem()
        configureMenu()
        bind()
        refreshMenu()
    }

    func menuWillOpen(_ menu: NSMenu) {
        sessionController.refreshPermissions()
        refreshMenu()
    }

    private func configureStatusItem() {
        statusItem.button?.image = MenuBarIcon.image(for: .ready)
        statusItem.button?.imagePosition = .imageOnly
        statusItem.button?.toolTip = "Mac Pause"
        statusItem.menu = menu
    }

    private func configureMenu() {
        menu.delegate = self

        statusMenuItem.isEnabled = false
        detailsMenuItem.isEnabled = false

        actionMenuItem.target = self
        actionMenuItem.action = #selector(primaryAction)

        permissionsMenuItem.target = self
        permissionsMenuItem.action = #selector(requestPermissions)

        settingsMenuItem.title = "Settings…"
        settingsMenuItem.target = self
        settingsMenuItem.action = #selector(showSettingsWindow)

        helpMenuItem.target = self
        helpMenuItem.action = #selector(showPermissionsWindow)

        uninstallMenuItem.target = self
        uninstallMenuItem.action = #selector(uninstall)

        quitMenuItem.title = "Quit Mac Pause"
        quitMenuItem.target = self
        quitMenuItem.action = #selector(quit)

        presetItems = CleaningPreset.allCases.map { preset in
            let item = NSMenuItem(
                title: preset.menuTitle,
                action: #selector(startPreset(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = preset.rawValue
            return item
        }
        presetMenu.items = presetItems
        presetMenuItem.submenu = presetMenu

        menu.items = [
            statusMenuItem,
            detailsMenuItem,
            .separator(),
            actionMenuItem,
            presetMenuItem,
            settingsMenuItem,
            permissionsMenuItem,
            helpMenuItem,
            .separator(),
            uninstallMenuItem,
            quitMenuItem
        ]
    }

    private func bind() {
        sessionController.$phase
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshMenu()
            }
            .store(in: &cancellables)

        sessionController.$permissionStatus
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshMenu()
            }
            .store(in: &cancellables)

        sessionController.$statusMessage
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshMenu()
            }
            .store(in: &cancellables)

        sessionController.$configuration
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshMenu()
            }
            .store(in: &cancellables)

        sessionController.$armingSecondsRemaining
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshMenu()
            }
            .store(in: &cancellables)

        sessionController.$timeRemaining
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshMenu()
            }
            .store(in: &cancellables)

        sessionController.$unlockProgress
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshMenu()
            }
            .store(in: &cancellables)
    }

    private func refreshMenu() {
        statusMenuItem.title = sessionController.statusMessage
        detailsMenuItem.title = detailsTitle
        updateActionMenuItem()
        updatePresetMenuItems()
        updatePermissionsMenuItem()
        updateUninstallMenuItem()
        updateStatusIcon()
    }

    private func updateActionMenuItem() {
        switch sessionController.phase {
        case .idle, .timedOut, .permissionsRequired:
            actionMenuItem.title = "Start Cleaning (\(Int(sessionController.nextSessionConfiguration.sessionTimeout))s)"
            actionMenuItem.isEnabled = true
        case .arming:
            actionMenuItem.title = "Cancel Countdown (\(sessionController.armingSecondsRemaining)s)"
            actionMenuItem.isEnabled = true
        case .active:
            actionMenuItem.title = "Cleaning Mode Active (\(Int(ceil(sessionController.timeRemaining)))s)"
            actionMenuItem.isEnabled = false
        case .unlocking:
            actionMenuItem.title = "Unlocking (\(Int(sessionController.unlockProgress * 100))%)"
            actionMenuItem.isEnabled = false
        }
    }

    private func updatePresetMenuItems() {
        presetMenuItem.title = "Preset Sessions"
        let canStartPreset = [
            CleaningSessionController.Phase.idle,
            .timedOut,
            .permissionsRequired
        ].contains(sessionController.phase)
        presetMenuItem.isEnabled = canStartPreset

        for (preset, item) in zip(CleaningPreset.allCases, presetItems) {
            item.title = preset.menuTitle
            item.isEnabled = canStartPreset
        }
    }

    private func updatePermissionsMenuItem() {
        if sessionController.permissionStatus.canBlockInput {
            permissionsMenuItem.title = "Permissions Ready"
            permissionsMenuItem.isEnabled = false
        } else {
            permissionsMenuItem.title = "Grant Required Permissions"
            permissionsMenuItem.isEnabled = true
        }

        helpMenuItem.title = "Permissions Help…"
    }

    private func updateUninstallMenuItem() {
        uninstallMenuItem.title = "Uninstall Mac Pause…"
        uninstallMenuItem.isEnabled = bundledAppURL != nil
    }

    private var detailsTitle: String {
        let configuration: CleaningConfiguration

        switch sessionController.phase {
        case .arming, .active, .unlocking:
            configuration = sessionController.configuration
            return "Current: \(configuration.interactionMode.displayName) · \(configuration.backdropStyle.displayName)"
        case .idle, .permissionsRequired, .timedOut:
            configuration = sessionController.nextSessionConfiguration
            return "Default: \(configuration.interactionMode.displayName) · \(configuration.backdropStyle.displayName)"
        }
    }

    private func updateStatusIcon() {
        let iconState: MenuBarIconState

        if !sessionController.permissionStatus.canBlockInput {
            iconState = .warning
        } else {
            switch sessionController.phase {
            case .idle, .permissionsRequired, .timedOut:
                iconState = .ready
            case .arming:
                iconState = .arming
            case .active, .unlocking:
                iconState = .active
            }
        }

        statusItem.button?.image = MenuBarIcon.image(for: iconState)
    }

    @objc
    private func primaryAction() {
        switch sessionController.phase {
        case .arming:
            sessionController.cancelCleaning()
        case .idle, .permissionsRequired, .timedOut:
            sessionController.startCleaning()

            if sessionController.phase == .permissionsRequired {
                presentPermissionWindow()
            }
        case .active, .unlocking:
            break
        }
    }

    @objc
    private func startPreset(_ sender: NSMenuItem) {
        guard
            let rawValue = sender.representedObject as? String,
            let preset = CleaningPreset(rawValue: rawValue)
        else {
            return
        }

        sessionController.startCleaning(
            using: preset.configuration(using: sessionController.nextSessionConfiguration)
        )

        if sessionController.phase == .permissionsRequired {
            presentPermissionWindow()
        }
    }

    @objc
    private func requestPermissions() {
        presentPermissionWindow()
    }

    @objc
    private func showPermissionsWindow() {
        presentPermissionWindow()
    }

    @objc
    private func showSettingsWindow() {
        settingsWindowController?.present()
    }

    @objc
    private func quit() {
        NSApp.terminate(nil)
    }

    @objc
    private func uninstall() {
        guard let bundledAppURL else {
            showUninstallUnavailableAlert()
            return
        }

        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Uninstall Mac Pause?"
        alert.informativeText = "This will quit Mac Pause, move the app bundle to the Trash, and reset its Accessibility and Input Monitoring permissions."
        alert.addButton(withTitle: "Uninstall")
        alert.addButton(withTitle: "Cancel")

        guard alert.runModal() == .alertFirstButtonReturn else {
            return
        }

        do {
            try scheduleSelfUninstall(from: bundledAppURL)
            sessionController.cancelCleaning()
            NSApp.terminate(nil)
        } catch {
            showUninstallErrorAlert(message: error.localizedDescription)
        }
    }

    private func presentPermissionWindow() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.permissionWindowController?.present()
        }
    }

    private var bundledAppURL: URL? {
        let url = Bundle.main.bundleURL
        return url.pathExtension.lowercased() == "app" ? url : nil
    }

    private func showUninstallUnavailableAlert() {
        showUninstallErrorAlert(
            message: "Uninstall is only available when Mac Pause is running as the bundled .app."
        )
    }

    private func showUninstallErrorAlert(message: String) {
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Mac Pause"
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func scheduleSelfUninstall(from appURL: URL) throws {
        let scriptURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("mac-pause-uninstall-\(UUID().uuidString).sh")

        let script = """
        #!/bin/zsh
        set -euo pipefail
        APP_PATH=\(shellQuoted(appURL.path))
        BUNDLE_ID=\(shellQuoted(Bundle.main.bundleIdentifier ?? "dev.codex.macpause"))
        SCRIPT_PATH=\(shellQuoted(scriptURL.path))
        TARGET="${HOME}/.Trash/$(basename "$APP_PATH")"

        if [[ -e "$TARGET" ]]; then
          BASE_NAME="$(basename "$APP_PATH" .app)"
          TARGET="${HOME}/.Trash/${BASE_NAME}-$(date +%s).app"
        fi

        sleep 1
        /bin/mv "$APP_PATH" "$TARGET"
        /usr/bin/tccutil reset Accessibility "$BUNDLE_ID" >/dev/null 2>&1 || true
        /usr/bin/tccutil reset ListenEvent "$BUNDLE_ID" >/dev/null 2>&1 || true
        /bin/rm -f "$SCRIPT_PATH"
        """

        try script.write(to: scriptURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o700],
            ofItemAtPath: scriptURL.path
        )

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = [scriptURL.path]
        try process.run()
    }

    private func shellQuoted(_ string: String) -> String {
        "'\(string.replacingOccurrences(of: "'", with: "'\\''"))'"
    }
}
