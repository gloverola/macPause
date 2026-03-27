import AppKit
import ApplicationServices
import Foundation

private let accessibilityPromptOptionKey = "AXTrustedCheckOptionPrompt"

public struct PermissionStatus: Equatable, Sendable {
    public var accessibilityGranted: Bool
    public var inputMonitoringGranted: Bool

    public init(
        accessibilityGranted: Bool,
        inputMonitoringGranted: Bool
    ) {
        self.accessibilityGranted = accessibilityGranted
        self.inputMonitoringGranted = inputMonitoringGranted
    }

    public var canBlockInput: Bool {
        accessibilityGranted && inputMonitoringGranted
    }
}

public protocol PermissionControlling: AnyObject {
    func refreshStatus() -> PermissionStatus
    func requestPermissions()
    func requestAccessibilityPermission()
    func requestInputMonitoringPermission()
    func openAccessibilitySettings() -> Bool
    func openInputMonitoringSettings() -> Bool
    func openPrivacyAndSecuritySettings() -> Bool
}

public final class PermissionsController: PermissionControlling {
    public init() {}

    public func refreshStatus() -> PermissionStatus {
        PermissionStatus(
            accessibilityGranted: preflightAccessibilityAccess(),
            inputMonitoringGranted: preflightListenAccess()
        )
    }

    public func requestPermissions() {
        _ = requestAccessibilityPrompt()
        _ = requestListenAccess()
    }

    public func requestAccessibilityPermission() {
        _ = requestAccessibilityPrompt()
    }

    public func requestInputMonitoringPermission() {
        _ = requestListenAccess()
    }

    @discardableResult
    public func openAccessibilitySettings() -> Bool {
        openSystemSettings(
            candidates: [
                "x-apple.systempreferences:com.apple.preference.security?PrivacyAccessibilityServicesType",
                "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
                "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?PrivacyAccessibilityServicesType",
                "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility",
                "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension",
                "x-apple.systempreferences:com.apple.preference.security?Privacy"
            ],
            fallbackURL: "https://support.apple.com/guide/mac-help/allow-accessibility-apps-to-access-your-mac-mh43185/mac"
        )
    }

    @discardableResult
    public func openInputMonitoringSettings() -> Bool {
        openSystemSettings(
            candidates: [
                "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension",
                "x-apple.systempreferences:com.apple.preference.security?Privacy",
                "x-apple.systempreferences:com.apple.preference.security"
            ],
            fallbackURL: "https://support.apple.com/guide/mac-help/control-access-to-input-monitoring-on-mac-mchl4cedafb6/mac"
        )
    }

    @discardableResult
    public func openPrivacyAndSecuritySettings() -> Bool {
        openSystemSettings(
            candidates: [
                "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension",
                "x-apple.systempreferences:com.apple.preference.security?Privacy",
                "x-apple.systempreferences:com.apple.preference.security"
            ],
            fallbackURL: "https://support.apple.com/guide/mac-help/control-what-you-share-on-mac-mchl2b29231a/mac"
        )
    }

    private func requestAccessibilityPrompt() -> Bool {
        let options = [
            accessibilityPromptOptionKey: true
        ] as CFDictionary

        return AXIsProcessTrustedWithOptions(options)
    }

    private func preflightAccessibilityAccess() -> Bool {
        let options = [
            accessibilityPromptOptionKey: false
        ] as CFDictionary

        return AXIsProcessTrusted() || AXIsProcessTrustedWithOptions(options)
    }

    private func preflightListenAccess() -> Bool {
        if #available(macOS 10.15, *) {
            return CGPreflightListenEventAccess()
        }

        return true
    }

    private func requestListenAccess() -> Bool {
        if #available(macOS 10.15, *) {
            return CGRequestListenEventAccess()
        }

        return true
    }

    private func openSystemSettings(
        candidates: [String],
        fallbackURL: String
    ) -> Bool {
        for candidate in candidates {
            guard let url = URL(string: candidate) else {
                continue
            }

            if NSWorkspace.shared.open(url) {
                return true
            }
        }

        guard let fallbackURL = URL(string: fallbackURL) else {
            return false
        }

        return NSWorkspace.shared.open(fallbackURL)
    }
}
