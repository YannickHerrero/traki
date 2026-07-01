import XCTest

/// Verifies logging a past session from Home: open the sheet, pick a mode and a
/// quick-pick duration, save, and confirm the sheet dismisses.
final class LoggingUITests: XCTestCase {

    override func setUp() { continueAfterFailure = false }

    @MainActor
    func testLogAPastSession() {
        let app = XCUIApplication()
        app.launch()

        let logButton = app.buttons["log-past"]
        XCTAssertTrue(logButton.waitForExistence(timeout: 10), "Home should show 'Log a past session'")
        logButton.tap()

        let save = app.buttons["log-save"]
        XCTAssertTrue(save.waitForExistence(timeout: 5), "Log sheet should appear")

        app.buttons["logchip-read"].tap()
        app.buttons["quick-30"].tap()

        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "log-sheet"
        shot.lifetime = .keepAlways
        add(shot)

        save.tap()
        XCTAssertTrue(save.waitForNonExistence(timeout: 5), "Sheet should dismiss after saving")
    }
}
