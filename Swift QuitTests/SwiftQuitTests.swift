import XCTest

final class SwiftQuitTests: XCTestCase {
    func testNormalizedApplicationPathHandlesLegacyFileURLs() {
        XCTAssertEqual(
            SwiftQuitPolicy.normalizedApplicationPath("file:///Applications/Safari.app"),
            "/Applications/Safari.app"
        )
    }

    func testExcludedAppModeHonorsConfiguredList() {
        let settings = ["excludeBehaviour": "excludeApps"]
        let excluded = ["/Applications/Safari.app"]

        XCTAssertFalse(SwiftQuitPolicy.shouldCloseApplication(applicationName: "/Applications/Safari.app", settings: settings, excludedApplications: excluded))
        XCTAssertTrue(SwiftQuitPolicy.shouldCloseApplication(applicationName: "/Applications/Mail.app", settings: settings, excludedApplications: excluded))
    }

    func testIncludedAppModeOnlyClosesConfiguredList() {
        let settings = ["excludeBehaviour": "includeApps"]
        let excluded = ["/Applications/Safari.app"]

        XCTAssertTrue(SwiftQuitPolicy.shouldCloseApplication(applicationName: "/Applications/Safari.app", settings: settings, excludedApplications: excluded))
        XCTAssertFalse(SwiftQuitPolicy.shouldCloseApplication(applicationName: "/Applications/Mail.app", settings: settings, excludedApplications: excluded))
    }

    func testRemainingWindowCancelsTermination() {
        XCTAssertFalse(SwiftQuitPolicy.hasNoWindowsAndShouldTerminate(
            hasRemainingWindows: true,
            isHidden: false
        ))
    }

    func testLastWindowAllowsTermination() {
        XCTAssertTrue(SwiftQuitPolicy.hasNoWindowsAndShouldTerminate(
            hasRemainingWindows: false,
            isHidden: false
        ))
    }

    func testHiddenAppWithRemainingWindowsIsNotTerminated() {
        XCTAssertFalse(SwiftQuitPolicy.hasNoWindowsAndShouldTerminate(
            hasRemainingWindows: true,
            isHidden: true
        ))
    }
}
