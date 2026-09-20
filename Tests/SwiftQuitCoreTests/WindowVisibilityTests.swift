import XCTest
@testable import SwiftQuitCore

final class WindowVisibilityTests: XCTestCase {
    func testDetectsNormalVisibleWindowForTheTargetApplication() {
        let records = [
            WindowVisibility.Record(ownerPID: 42, layer: 0, alpha: 1),
            WindowVisibility.Record(ownerPID: 99, layer: 0, alpha: 1)
        ]

        XCTAssertTrue(WindowVisibility.hasUserVisibleWindow(for: 42, in: records))
    }

    func testIgnoresWindowsOwnedByOtherApplications() {
        let records = [WindowVisibility.Record(ownerPID: 99, layer: 0, alpha: 1)]

        XCTAssertFalse(WindowVisibility.hasUserVisibleWindow(for: 42, in: records))
    }

    func testIgnoresNonUserFacingAndTransparentWindows() {
        let records = [
            WindowVisibility.Record(ownerPID: 42, layer: 25, alpha: 1),
            WindowVisibility.Record(ownerPID: 42, layer: 0, alpha: 0)
        ]

        XCTAssertFalse(WindowVisibility.hasUserVisibleWindow(for: 42, in: records))
    }
}
