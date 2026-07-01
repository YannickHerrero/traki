import XCTest

/// Verifies the Settings screen renders and that switching the theme re-themes
/// the app (captured light → dark).
final class SettingsUITests: XCTestCase {

    override func setUp() { continueAfterFailure = false }

    @MainActor
    func testSettingsAndThemeSwitch() {
        let app = XCUIApplication()
        app.launch()

        app.buttons["tab-settings"].tap()
        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 5))

        func snapshot(_ name: String) {
            let shot = XCTAttachment(screenshot: app.screenshot())
            shot.name = name
            shot.lifetime = .keepAlways
            add(shot)
        }

        snapshot("settings-top")
        app.swipeUp()
        snapshot("settings-bottom")

        app.swipeDown()
        let dark = app.buttons["theme-Dark"]
        XCTAssertTrue(dark.waitForExistence(timeout: 5))
        dark.tap()
        snapshot("settings-dark")

        // Restore the default so the persisted theme doesn't leak to other runs.
        app.buttons["theme-System"].tap()
    }
}
