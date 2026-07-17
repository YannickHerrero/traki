import XCTest

/// Exercises the regular-width layouts and confirms an active session survives
/// the iPad-only landscape rotation.
final class IPadLayoutUITests: XCTestCase {

    override func setUp() { continueAfterFailure = false }

    @MainActor
    func testRegularWidthLayoutAndLandscapeTracking() throws {
        let app = XCUIApplication()
        app.launch()

        let logPast = app.buttons["log-past"]
        XCTAssertTrue(logPast.waitForExistence(timeout: 10))
        try XCTSkipIf(app.windows.firstMatch.frame.width < 700,
                       "This test requires an iPad-sized simulator window.")

        snapshot(app, named: "ipad-home-portrait")

        app.buttons["mode-listen"].tap()
        let stop = app.buttons["stop-save"]
        XCTAssertTrue(stop.waitForExistence(timeout: 5))

        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(stop.waitForExistence(timeout: 5),
                      "The active session controls should survive rotation")
        XCTAssertGreaterThan(app.windows.firstMatch.frame.width, app.windows.firstMatch.frame.height)
        snapshot(app, named: "ipad-timer-landscape")

        stop.tap()
        XCTAssertTrue(app.buttons["done"].waitForExistence(timeout: 5))
        snapshot(app, named: "ipad-complete-landscape")
        app.buttons["done"].tap()
        XCTAssertTrue(logPast.waitForExistence(timeout: 5))

        app.buttons["tab-stats"].tap()
        XCTAssertTrue(app.staticTexts["Statistics"].waitForExistence(timeout: 5))
        snapshot(app, named: "ipad-stats-landscape")

        XCUIDevice.shared.orientation = .portrait
    }

    @MainActor
    private func snapshot(_ app: XCUIApplication, named name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
