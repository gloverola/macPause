import Foundation
import MacPauseCore

enum CleaningPreset: String, CaseIterable {
    case quickWipe
    case deskReset
    case deepClean

    var title: String {
        switch self {
        case .quickWipe:
            return "Quick Wipe"
        case .deskReset:
            return "Desk Reset"
        case .deepClean:
            return "Deep Clean"
        }
    }

    var duration: TimeInterval {
        switch self {
        case .quickWipe:
            return 15
        case .deskReset:
            return 30
        case .deepClean:
            return 60
        }
    }

    var menuTitle: String {
        "\(title) (\(Int(duration))s)"
    }

    func configuration(using defaults: CleaningConfiguration) -> CleaningConfiguration {
        defaults.withSessionTimeout(duration)
    }
}
