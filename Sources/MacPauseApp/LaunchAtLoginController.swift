import AppKit
import Foundation
import ServiceManagement

struct LaunchAtLoginState: Equatable {
    let isEnabled: Bool
    let isAvailable: Bool
    let requiresApproval: Bool
    let detail: String
}

@MainActor
protocol LaunchAtLoginControlling {
    func currentState() -> LaunchAtLoginState
    func setEnabled(_ enabled: Bool) throws -> LaunchAtLoginState
}

enum LaunchAtLoginError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Launch at login is only available from the bundled Mac Pause app."
        }
    }
}

@MainActor
final class LaunchAtLoginController: LaunchAtLoginControlling {
    func currentState() -> LaunchAtLoginState {
        guard isBundledApp else {
            return LaunchAtLoginState(
                isEnabled: false,
                isAvailable: false,
                requiresApproval: false,
                detail: "Available only when Mac Pause is running as the bundled .app."
            )
        }

        guard #available(macOS 13.0, *) else {
            return LaunchAtLoginState(
                isEnabled: false,
                isAvailable: false,
                requiresApproval: false,
                detail: "Launch at login requires macOS 13 or newer."
            )
        }

        return map(SMAppService.mainApp.status)
    }

    func setEnabled(_ enabled: Bool) throws -> LaunchAtLoginState {
        guard isBundledApp else {
            throw LaunchAtLoginError.unavailable
        }

        guard #available(macOS 13.0, *) else {
            throw LaunchAtLoginError.unavailable
        }

        let service = SMAppService.mainApp

        if enabled {
            try service.register()
        } else {
            try service.unregister()
        }

        return map(service.status)
    }

    private var isBundledApp: Bool {
        Bundle.main.bundleURL.pathExtension.lowercased() == "app"
    }

    @available(macOS 13.0, *)
    private func map(_ status: SMAppService.Status) -> LaunchAtLoginState {
        switch status {
        case .enabled:
            return LaunchAtLoginState(
                isEnabled: true,
                isAvailable: true,
                requiresApproval: false,
                detail: "Mac Pause will open automatically when you log in."
            )
        case .notRegistered:
            return LaunchAtLoginState(
                isEnabled: false,
                isAvailable: true,
                requiresApproval: false,
                detail: "Mac Pause will stay off until you launch it manually."
            )
        case .requiresApproval:
            return LaunchAtLoginState(
                isEnabled: true,
                isAvailable: true,
                requiresApproval: true,
                detail: "Approve Mac Pause in System Settings > General > Login Items."
            )
        case .notFound:
            return LaunchAtLoginState(
                isEnabled: false,
                isAvailable: false,
                requiresApproval: false,
                detail: "macOS could not register this build as a login item."
            )
        @unknown default:
            return LaunchAtLoginState(
                isEnabled: false,
                isAvailable: false,
                requiresApproval: false,
                detail: "Launch at login is unavailable for this build."
            )
        }
    }
}
