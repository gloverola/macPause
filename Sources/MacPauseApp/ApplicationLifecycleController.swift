import AppKit
import Foundation

@MainActor
protocol ApplicationLifecycleControlling: AnyObject {
    func relaunch() throws
}

enum ApplicationLifecycleError: LocalizedError {
    case bundledAppRequired

    var errorDescription: String? {
        switch self {
        case .bundledAppRequired:
            return "Relaunch is only available when Mac Pause is running as the bundled .app."
        }
    }
}

@MainActor
final class ApplicationLifecycleController: ApplicationLifecycleControlling {
    func relaunch() throws {
        guard let appURL = bundledAppURL else {
            throw ApplicationLifecycleError.bundledAppRequired
        }

        let scriptURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("mac-pause-relaunch-\(UUID().uuidString).sh")

        let script = """
        #!/bin/zsh
        set -euo pipefail
        APP_PATH=\(shellQuoted(appURL.path))
        SCRIPT_PATH=\(shellQuoted(scriptURL.path))
        sleep 1
        /usr/bin/open "$APP_PATH"
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

        NSApp.terminate(nil)
    }

    private var bundledAppURL: URL? {
        let url = Bundle.main.bundleURL
        return url.pathExtension.lowercased() == "app" ? url : nil
    }

    private func shellQuoted(_ string: String) -> String {
        "'\(string.replacingOccurrences(of: "'", with: "'\\''"))'"
    }
}
