import Foundation

public enum CleaningInteractionMode: String, CaseIterable, Codable, Sendable {
    case fullLock
    case keyboardOnly
    case pointerOnly

    public var displayName: String {
        switch self {
        case .fullLock:
            return "Full Lock"
        case .keyboardOnly:
            return "Keyboard Only"
        case .pointerOnly:
            return "Pointer Only"
        }
    }
}

public enum CleaningBackdropStyle: String, CaseIterable, Codable, Sendable {
    case classicHUD
    case blackout
    case neutralGray
    case whiteout

    public var displayName: String {
        switch self {
        case .classicHUD:
            return "Classic HUD"
        case .blackout:
            return "Black Screen"
        case .neutralGray:
            return "Gray Screen"
        case .whiteout:
            return "White Screen"
        }
    }
}

public struct CleaningConfiguration: Equatable, Sendable {
    public var armingCountdown: TimeInterval
    public var unlockHoldDuration: TimeInterval
    public var sessionTimeout: TimeInterval
    public var interactionMode: CleaningInteractionMode
    public var backdropStyle: CleaningBackdropStyle

    public init(
        armingCountdown: TimeInterval = 3,
        unlockHoldDuration: TimeInterval = 2,
        sessionTimeout: TimeInterval = 60,
        interactionMode: CleaningInteractionMode = .fullLock,
        backdropStyle: CleaningBackdropStyle = .classicHUD
    ) {
        self.armingCountdown = armingCountdown
        self.unlockHoldDuration = unlockHoldDuration
        self.sessionTimeout = sessionTimeout
        self.interactionMode = interactionMode
        self.backdropStyle = backdropStyle
    }

    public func withSessionTimeout(_ sessionTimeout: TimeInterval) -> CleaningConfiguration {
        var copy = self
        copy.sessionTimeout = sessionTimeout
        return copy
    }
}
