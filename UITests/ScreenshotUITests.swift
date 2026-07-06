import XCTest

/// Captures the hero screens as attachments for the README demo gallery.
final class ScreenshotUITests: XCTestCase {

    override func setUp() { continueAfterFailure = false }

    @MainActor
    func testCaptureScreens() {
        let app = XCUIApplication()
        app.launch()

        func snapshot(_ name: String) {
            let shot = XCTAttachment(screenshot: app.screenshot())
            shot.name = name
            shot.lifetime = .keepAlways
            add(shot)
        }

        // Home (Playful Cards)
        XCTAssertTrue(app.buttons["log-past"].waitForExistence(timeout: 10))
        snapshot("01-home")

        // Active Timer — Listening has the nicest gradient.
        app.buttons["mode-listen"].tap()
        XCTAssertTrue(app.buttons["stop-save"].waitForExistence(timeout: 10))
        sleep(5)
        snapshot("02-timer")

        // Session Complete
        app.buttons["stop-save"].tap()
        XCTAssertTrue(app.buttons["done"].waitForExistence(timeout: 10))
        snapshot("03-complete")
        app.buttons["done"].tap()

        // Statistics — top (bars) and scrolled (trend + heatmap).
        app.buttons["tab-stats"].tap()
        XCTAssertTrue(app.staticTexts["Statistics"].waitForExistence(timeout: 5))
        snapshot("04-stats")
        app.swipeUp()
        snapshot("05-stats-charts")

        // History
        app.buttons["tab-history"].tap()
        XCTAssertTrue(app.staticTexts["History"].waitForExistence(timeout: 5))
        snapshot("06-history")

        // Log a past session sheet
        app.buttons["tab-home"].tap()
        XCTAssertTrue(app.buttons["log-past"].waitForExistence(timeout: 5))
        app.buttons["log-past"].tap()
        XCTAssertTrue(app.buttons["log-save"].waitForExistence(timeout: 5))
        snapshot("07-log")
    }
}
