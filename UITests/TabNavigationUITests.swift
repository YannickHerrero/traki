import XCTest

/// Verifies the tab bar switches between the four destinations, capturing a
/// screenshot of each for the record.
final class TabNavigationUITests: XCTestCase {

    override func setUp() { continueAfterFailure = false }

    @MainActor
    func testVisitEachTab() {
        let app = XCUIApplication()
        app.launch()

        func snapshot(_ name: String) {
            let shot = XCTAttachment(screenshot: app.screenshot())
            shot.name = name
            shot.lifetime = .keepAlways
            add(shot)
        }

        app.buttons["tab-stats"].tap()
        XCTAssertTrue(app.staticTexts["Statistics"].waitForExistence(timeout: 5))
        snapshot("stats")

        app.buttons["tab-history"].tap()
        XCTAssertTrue(app.staticTexts["History"].waitForExistence(timeout: 5))
        snapshot("history")

        app.buttons["tab-settings"].tap()
        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 5))
        snapshot("settings")

        app.buttons["tab-home"].tap()
        XCTAssertTrue(app.buttons["log-past"].waitForExistence(timeout: 5))
    }
}
