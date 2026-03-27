import XCTest
@testable import MacPauseCore

final class InputBlockingTests: XCTestCase {
    func testBlockedEventMaskIncludesSystemDefinedEvents() {
        let systemDefinedBit = CGEventMask(1) << CGEventInputBlocker.systemDefinedEventRawValue

        XCTAssertTrue(
            CGEventInputBlocker.blockedEventRawValues.contains(
                CGEventInputBlocker.systemDefinedEventRawValue
            )
        )
        XCTAssertNotEqual(CGEventInputBlocker.blockedEventMask & systemDefinedBit, 0)
    }
}
