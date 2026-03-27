import CoreGraphics
import Foundation

public enum KeyboardEventKind: Sendable {
    case keyDown
    case keyUp
    case flagsChanged
}

public final class UnlockDetector: @unchecked Sendable {
    public static let escapeKeyCode = CGKeyCode(53)
    public static let leftShiftKeyCode = CGKeyCode(56)
    public static let rightShiftKeyCode = CGKeyCode(60)

    public var onProgressChanged: (@Sendable (Double) -> Void)?
    public var onUnlockCompleted: (@Sendable () -> Void)?

    private var holdDuration: TimeInterval
    private let tickerInterval: TimeInterval
    private let callbackQueue: DispatchQueue
    private let lock = NSLock()

    private var isEscapePressed = false
    private var isRightShiftPressed = false
    private var chordStartTime: TimeInterval?
    private var timer: DispatchSourceTimer?

    public init(
        holdDuration: TimeInterval,
        tickerInterval: TimeInterval = 0.05,
        callbackQueue: DispatchQueue = .main
    ) {
        self.holdDuration = holdDuration
        self.tickerInterval = tickerInterval
        self.callbackQueue = callbackQueue
    }

    deinit {
        reset()
    }

    public func process(event: KeyboardEventKind, keyCode: CGKeyCode) {
        var progressToEmit: Double?

        lock.lock()

        switch event {
        case .keyDown:
            if keyCode == Self.escapeKeyCode {
                isEscapePressed = true
            }
        case .keyUp:
            if keyCode == Self.escapeKeyCode {
                isEscapePressed = false
            }
        case .flagsChanged:
            if keyCode == Self.rightShiftKeyCode {
                isRightShiftPressed.toggle()
            }
        }

        if shouldTrackChord {
            if chordStartTime == nil {
                chordStartTime = ProcessInfo.processInfo.systemUptime
                startTimerLocked()
            }
        } else {
            chordStartTime = nil
            stopTimerLocked()
            progressToEmit = 0
        }

        lock.unlock()

        if let progressToEmit {
            emitProgress(progressToEmit)
        }
    }

    public func reset() {
        lock.lock()
        isEscapePressed = false
        isRightShiftPressed = false
        chordStartTime = nil
        stopTimerLocked()
        lock.unlock()

        emitProgress(0)
    }

    public func updateHoldDuration(_ holdDuration: TimeInterval) {
        lock.lock()
        self.holdDuration = holdDuration
        chordStartTime = nil
        stopTimerLocked()
        lock.unlock()

        emitProgress(0)
    }

    private var shouldTrackChord: Bool {
        isEscapePressed && isRightShiftPressed
    }

    private func startTimerLocked() {
        guard timer == nil else {
            return
        }

        let timer = DispatchSource.makeTimerSource(queue: .global(qos: .userInitiated))
        timer.schedule(
            deadline: .now(),
            repeating: tickerInterval
        )
        timer.setEventHandler { [weak self] in
            self?.handleTimerTick()
        }
        self.timer = timer
        timer.resume()
    }

    private func stopTimerLocked() {
        guard let timer else {
            return
        }

        timer.setEventHandler {}
        timer.cancel()
        self.timer = nil
    }

    private func handleTimerTick() {
        var progressToEmit = 0.0
        var unlockCompleted = false
        var progressHandler: (@Sendable (Double) -> Void)?
        var unlockHandler: (@Sendable () -> Void)?

        lock.lock()

        guard let chordStartTime else {
            lock.unlock()
            return
        }

        let elapsed = ProcessInfo.processInfo.systemUptime - chordStartTime
        progressToEmit = min(1, elapsed / holdDuration)
        progressHandler = onProgressChanged

        if progressToEmit >= 1 {
            unlockCompleted = true
            unlockHandler = onUnlockCompleted
            isEscapePressed = false
            isRightShiftPressed = false
            self.chordStartTime = nil
            stopTimerLocked()
        }

        lock.unlock()

        if let progressHandler {
            let progress = progressToEmit
            callbackQueue.async {
                progressHandler(progress)
            }
        }

        if unlockCompleted, let unlockHandler {
            callbackQueue.async {
                unlockHandler()
            }
        }
    }

    private func emitProgress(_ progress: Double) {
        guard let onProgressChanged else {
            return
        }

        callbackQueue.async {
            onProgressChanged(progress)
        }
    }
}
