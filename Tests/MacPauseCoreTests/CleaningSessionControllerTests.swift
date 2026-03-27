import XCTest
@testable import MacPauseCore

@MainActor
final class CleaningSessionControllerTests: XCTestCase {
    func testStartCleaningRequiresPermissions() {
        let blocker = MockInputBlocker()
        let permissions = MockPermissionsController(
            status: .init(
                accessibilityGranted: false,
                inputMonitoringGranted: false
            )
        )
        let controller = CleaningSessionController(
            configuration: .init(
                armingCountdown: 0,
                unlockHoldDuration: 0.1,
                sessionTimeout: 0.1
            ),
            inputBlocker: blocker,
            permissionsController: permissions
        )

        controller.startCleaning()

        XCTAssertEqual(controller.phase, .permissionsRequired)
        XCTAssertFalse(controller.isOverlayVisible)
        XCTAssertFalse(blocker.isBlocking)
    }

    func testOverlayVisibilityOnlyTurnsOnForCleaningStates() {
        let blocker = MockInputBlocker()
        let permissions = MockPermissionsController(
            status: .init(
                accessibilityGranted: true,
                inputMonitoringGranted: true
            )
        )
        let controller = CleaningSessionController(
            configuration: .init(
                armingCountdown: 0,
                unlockHoldDuration: 0.1,
                sessionTimeout: 1
            ),
            inputBlocker: blocker,
            permissionsController: permissions
        )

        XCTAssertFalse(controller.isOverlayVisible)

        controller.activateCleaningMode()

        XCTAssertTrue(controller.isOverlayVisible)

        controller.cancelCleaning()

        XCTAssertFalse(controller.isOverlayVisible)
    }

    func testActivateCleaningModeStartsInputBlocker() throws {
        let blocker = MockInputBlocker()
        let permissions = MockPermissionsController(
            status: .init(
                accessibilityGranted: true,
                inputMonitoringGranted: true
            )
        )
        let controller = CleaningSessionController(
            configuration: .init(
                armingCountdown: 0,
                unlockHoldDuration: 0.1,
                sessionTimeout: 1
            ),
            inputBlocker: blocker,
            permissionsController: permissions
        )

        controller.activateCleaningMode()

        XCTAssertEqual(controller.phase, .active)
        XCTAssertTrue(blocker.startCalled)
        XCTAssertEqual(controller.timeRemaining, 1, accuracy: 0.01)
    }

    func testUnlockProgressMovesBetweenActiveAndUnlocking() {
        let blocker = MockInputBlocker()
        let permissions = MockPermissionsController(
            status: .init(
                accessibilityGranted: true,
                inputMonitoringGranted: true
            )
        )
        let controller = CleaningSessionController(
            configuration: .init(
                armingCountdown: 0,
                unlockHoldDuration: 0.1,
                sessionTimeout: 1
            ),
            inputBlocker: blocker,
            permissionsController: permissions
        )

        controller.activateCleaningMode()
        controller.handleUnlockProgress(0.4)

        XCTAssertEqual(controller.phase, .unlocking)
        XCTAssertEqual(controller.unlockProgress, 0.4, accuracy: 0.001)

        controller.handleUnlockProgress(0)

        XCTAssertEqual(controller.phase, .active)
        XCTAssertEqual(controller.unlockProgress, 0, accuracy: 0.001)
    }

    func testTimeoutStopsBlockingAndEntersTimedOutState() {
        let blocker = MockInputBlocker()
        let permissions = MockPermissionsController(
            status: .init(
                accessibilityGranted: true,
                inputMonitoringGranted: true
            )
        )
        let controller = CleaningSessionController(
            configuration: .init(
                armingCountdown: 0,
                unlockHoldDuration: 0.1,
                sessionTimeout: 1
            ),
            inputBlocker: blocker,
            permissionsController: permissions
        )

        controller.activateCleaningMode()
        controller.timeoutCleaningSession()

        XCTAssertEqual(controller.phase, .timedOut)
        XCTAssertTrue(blocker.stopCalled)
        XCTAssertEqual(controller.timeRemaining, 0, accuracy: 0.001)
    }

    func testUpdatingDefaultConfigurationAppliesImmediatelyWhenIdle() {
        let blocker = MockInputBlocker()
        let permissions = MockPermissionsController(
            status: .init(
                accessibilityGranted: true,
                inputMonitoringGranted: true
            )
        )
        let controller = CleaningSessionController(
            configuration: .init(
                armingCountdown: 3,
                unlockHoldDuration: 2,
                sessionTimeout: 60
            ),
            inputBlocker: blocker,
            permissionsController: permissions
        )

        let updated = CleaningConfiguration(
            armingCountdown: 5,
            unlockHoldDuration: 1.5,
            sessionTimeout: 90,
            interactionMode: .pointerOnly,
            backdropStyle: .blackout
        )

        controller.updateDefaultConfiguration(updated)

        XCTAssertEqual(controller.configuration, updated)
        XCTAssertEqual(controller.nextSessionConfiguration, updated)
        XCTAssertEqual(blocker.unlockHoldDuration ?? 0, 1.5, accuracy: 0.001)
        XCTAssertEqual(blocker.interactionMode, .pointerOnly)
    }

    func testStartCleaningCanUseConfigurationOverride() {
        let blocker = MockInputBlocker()
        let permissions = MockPermissionsController(
            status: .init(
                accessibilityGranted: true,
                inputMonitoringGranted: true
            )
        )
        let controller = CleaningSessionController(
            configuration: .init(
                armingCountdown: 3,
                unlockHoldDuration: 2,
                sessionTimeout: 60
            ),
            inputBlocker: blocker,
            permissionsController: permissions
        )

        let override = CleaningConfiguration(
            armingCountdown: 0,
            unlockHoldDuration: 1,
            sessionTimeout: 15,
            interactionMode: .keyboardOnly,
            backdropStyle: .whiteout
        )

        controller.startCleaning(using: override)

        XCTAssertEqual(controller.configuration, override)
        XCTAssertEqual(controller.phase, .active)
        XCTAssertEqual(controller.timeRemaining, 15, accuracy: 0.01)
        XCTAssertEqual(blocker.unlockHoldDuration ?? 0, 1, accuracy: 0.001)
        XCTAssertEqual(blocker.interactionMode, .keyboardOnly)
    }
}

private final class MockInputBlocker: InputBlocking {
    var isBlocking = false
    var onUnlockProgress: (@Sendable (Double) -> Void)?
    var onUnlockCompleted: (@Sendable () -> Void)?
    var onBlockerInterruption: (@Sendable (String) -> Void)?
    var unlockHoldDuration: TimeInterval?
    var interactionMode: CleaningInteractionMode?

    var startCalled = false
    var stopCalled = false

    func startBlocking() throws {
        startCalled = true
        isBlocking = true
    }

    func stopBlocking() {
        stopCalled = true
        isBlocking = false
    }

    func updateUnlockHoldDuration(_ holdDuration: TimeInterval) {
        unlockHoldDuration = holdDuration
    }

    func updateInteractionMode(_ mode: CleaningInteractionMode) {
        interactionMode = mode
    }
}

private final class MockPermissionsController: PermissionControlling {
    var status: PermissionStatus

    init(status: PermissionStatus) {
        self.status = status
    }

    func refreshStatus() -> PermissionStatus {
        status
    }

    func requestPermissions() {}

    func requestAccessibilityPermission() {}

    func requestInputMonitoringPermission() {}

    func openAccessibilitySettings() -> Bool { true }

    func openInputMonitoringSettings() -> Bool { true }

    func openPrivacyAndSecuritySettings() -> Bool { true }
}
