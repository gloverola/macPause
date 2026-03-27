import CoreGraphics
import Foundation

public enum InputBlockerError: Error, LocalizedError, Sendable {
    case eventTapCreationFailed

    public var errorDescription: String? {
        switch self {
        case .eventTapCreationFailed:
            return "Mac Pause could not create the global input blocker. Check Accessibility and Input Monitoring permissions, then try again."
        }
    }
}

public protocol InputBlocking: AnyObject {
    var isBlocking: Bool { get }
    var onUnlockProgress: (@Sendable (Double) -> Void)? { get set }
    var onUnlockCompleted: (@Sendable () -> Void)? { get set }
    var onBlockerInterruption: (@Sendable (String) -> Void)? { get set }

    func startBlocking() throws
    func stopBlocking()
    func updateUnlockHoldDuration(_ holdDuration: TimeInterval)
    func updateInteractionMode(_ mode: CleaningInteractionMode)
}

public final class CGEventInputBlocker: InputBlocking {
    static let systemDefinedEventRawValue: UInt32 = 14
    static let blockedEventRawValues: [UInt32] = [
        CGEventType.keyDown.rawValue,
        CGEventType.keyUp.rawValue,
        CGEventType.flagsChanged.rawValue,
        CGEventType.mouseMoved.rawValue,
        CGEventType.leftMouseDown.rawValue,
        CGEventType.leftMouseUp.rawValue,
        CGEventType.leftMouseDragged.rawValue,
        CGEventType.rightMouseDown.rawValue,
        CGEventType.rightMouseUp.rawValue,
        CGEventType.rightMouseDragged.rawValue,
        CGEventType.otherMouseDown.rawValue,
        CGEventType.otherMouseUp.rawValue,
        CGEventType.otherMouseDragged.rawValue,
        CGEventType.scrollWheel.rawValue,
        systemDefinedEventRawValue
    ]
    static let blockedEventMask: CGEventMask = blockedEventRawValues.reduce(into: CGEventMask(0)) { mask, rawValue in
        mask |= CGEventMask(1) << rawValue
    }

    public var isBlocking = false
    public var onUnlockProgress: (@Sendable (Double) -> Void)? {
        get { unlockDetector.onProgressChanged }
        set { unlockDetector.onProgressChanged = newValue }
    }
    public var onUnlockCompleted: (@Sendable () -> Void)? {
        get { unlockDetector.onUnlockCompleted }
        set { unlockDetector.onUnlockCompleted = newValue }
    }
    public var onBlockerInterruption: (@Sendable (String) -> Void)?

    private let unlockDetector: UnlockDetector
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var interactionMode: CleaningInteractionMode = .fullLock

    public init(unlockHoldDuration: TimeInterval) {
        self.unlockDetector = UnlockDetector(holdDuration: unlockHoldDuration)
    }

    deinit {
        stopBlocking()
    }

    public func startBlocking() throws {
        guard !isBlocking else {
            return
        }

        unlockDetector.reset()

        let eventMask = keyboardAndMouseEventMask
        let userInfo = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: Self.eventTapCallback,
            userInfo: userInfo
        ) else {
            throw InputBlockerError.eventTapCreationFailed
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)

        self.eventTap = eventTap
        self.runLoopSource = source

        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)

        isBlocking = true
    }

    public func stopBlocking() {
        unlockDetector.reset()

        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            runLoopSource = nil
        }

        if let eventTap {
            CFMachPortInvalidate(eventTap)
            self.eventTap = nil
        }

        isBlocking = false
    }

    public func updateUnlockHoldDuration(_ holdDuration: TimeInterval) {
        unlockDetector.updateHoldDuration(holdDuration)
    }

    public func updateInteractionMode(_ mode: CleaningInteractionMode) {
        interactionMode = mode
    }

    private var keyboardAndMouseEventMask: CGEventMask {
        Self.blockedEventMask
    }

    private static let eventTapCallback: CGEventTapCallBack = { _, type, event, userInfo in
        guard let userInfo else {
            return Unmanaged.passUnretained(event)
        }

        let blocker = Unmanaged<CGEventInputBlocker>.fromOpaque(userInfo).takeUnretainedValue()
        let shouldSuppress = blocker.handleEvent(type: type, event: event)

        if shouldSuppress {
            return nil
        }

        return Unmanaged.passUnretained(event)
    }

    private func handleEvent(type: CGEventType, event: CGEvent) -> Bool {
        // Media, brightness, and transport keys arrive as legacy NX_SYSDEFINED
        // events (raw value 14) rather than standard key down/up events.
        if type.rawValue == Self.systemDefinedEventRawValue {
            return shouldSuppressKeyboardEvents
        }

        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            handleTapDisabled()
            return false
        case .keyDown, .keyUp, .flagsChanged:
            let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
            unlockDetector.process(event: keyboardEventKind(for: type), keyCode: keyCode)
            return shouldSuppressKeyboardEvents
        case .mouseMoved,
             .leftMouseDown,
             .leftMouseUp,
             .leftMouseDragged,
             .rightMouseDown,
             .rightMouseUp,
             .rightMouseDragged,
             .otherMouseDown,
             .otherMouseUp,
             .otherMouseDragged,
             .scrollWheel:
            return shouldSuppressPointerEvents
        default:
            return false
        }
    }

    private var shouldSuppressKeyboardEvents: Bool {
        switch interactionMode {
        case .fullLock, .keyboardOnly:
            return true
        case .pointerOnly:
            return false
        }
    }

    private var shouldSuppressPointerEvents: Bool {
        switch interactionMode {
        case .fullLock, .pointerOnly:
            return true
        case .keyboardOnly:
            return false
        }
    }

    private func handleTapDisabled() {
        unlockDetector.reset()

        guard let eventTap else {
            onBlockerInterruption?("Mac Pause lost the input blocker and exited cleaning mode.")
            return
        }

        CGEvent.tapEnable(tap: eventTap, enable: true)
    }

    private func keyboardEventKind(for eventType: CGEventType) -> KeyboardEventKind {
        switch eventType {
        case .keyDown:
            return .keyDown
        case .keyUp:
            return .keyUp
        case .flagsChanged:
            return .flagsChanged
        default:
            return .keyUp
        }
    }
}
