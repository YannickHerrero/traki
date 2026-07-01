import XCTest

/// Verifies editing from History: press-and-hold an entry opens the edit sheet
/// (with a Delete option), and changing the duration then saving dismisses it.
final class EditingUITests: XCTestCase {

    override func setUp() { continueAfterFailure = false }

    @MainActor
    func testHoldToEditEntry() {
        let app = XCUIApplication()
        app.launch()

        app.buttons["tab-history"].tap()
        XCTAssertTrue(app.staticTexts["History"].waitForExistence(timeout: 5))

        // Press-and-hold a session row (past the 480ms threshold).
        let row = app.staticTexts["Reading"].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.press(forDuration: 0.7)

        // The edit sheet appears with a Save and a Delete control.
        let save = app.buttons["log-save"]
        XCTAssertTrue(save.waitForExistence(timeout: 5), "Hold should open the edit sheet")
        XCTAssertTrue(app.buttons["log-delete"].exists, "Editing shows a Delete option")

        app.buttons["quick-60"].tap()

        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "edit-sheet"
        shot.lifetime = .keepAlways
        add(shot)

        save.tap()
        XCTAssertTrue(save.waitForNonExistence(timeout: 5), "Sheet should dismiss after saving the edit")
    }
}
