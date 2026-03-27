import CoreGraphics
import XCTest
@testable import MacPauseCore

final class UnlockDetectorTests: XCTestCase {
    func testEscapeAloneDoesNotUnlock() async throws {
        let detector = UnlockDetector(
            holdDuration: 0.1,
            tickerInterval: 0.01
        )
        let expectation = expectation(description: "unlock should not fire")
        expectation.isInverted = true

        detector.onUnlockCompleted = {
            expectation.fulfill()
        }

        detector.process(event: .keyDown, keyCode: UnlockDetector.escapeKeyCode)
        await fulfillment(of: [expectation], timeout: 0.2)
    }

    func testLeftShiftAndEscapeDoesNotUnlock() async throws {
        let detector = UnlockDetector(
            holdDuration: 0.1,
            tickerInterval: 0.01
        )
        let expectation = expectation(description: "unlock should not fire")
        expectation.isInverted = true

        detector.onUnlockCompleted = {
            expectation.fulfill()
        }

        detector.process(event: .flagsChanged, keyCode: UnlockDetector.leftShiftKeyCode)
        detector.process(event: .keyDown, keyCode: UnlockDetector.escapeKeyCode)

        await fulfillment(of: [expectation], timeout: 0.2)
    }

    func testShortRightShiftAndEscapeHoldDoesNotUnlock() async throws {
        let detector = UnlockDetector(
            holdDuration: 0.25,
            tickerInterval: 0.01
        )
        let expectation = expectation(description: "unlock should not fire")
        expectation.isInverted = true

        detector.onUnlockCompleted = {
            expectation.fulfill()
        }

        detector.process(event: .flagsChanged, keyCode: UnlockDetector.rightShiftKeyCode)
        detector.process(event: .keyDown, keyCode: UnlockDetector.escapeKeyCode)
        try await Task.sleep(for: .milliseconds(80))
        detector.process(event: .keyUp, keyCode: UnlockDetector.escapeKeyCode)
        detector.process(event: .flagsChanged, keyCode: UnlockDetector.rightShiftKeyCode)

        await fulfillment(of: [expectation], timeout: 0.25)
    }

    func testRightShiftAndEscapeUnlockAfterHoldDuration() async throws {
        let detector = UnlockDetector(
            holdDuration: 0.1,
            tickerInterval: 0.01
        )
        let expectation = expectation(description: "unlock fires")

        detector.onUnlockCompleted = {
            expectation.fulfill()
        }

        detector.process(event: .flagsChanged, keyCode: UnlockDetector.rightShiftKeyCode)
        detector.process(event: .keyDown, keyCode: UnlockDetector.escapeKeyCode)

        await fulfillment(of: [expectation], timeout: 0.25)
    }
}
