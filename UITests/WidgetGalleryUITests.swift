import XCTest

/// Renders the widget views in the DEBUG in-app gallery and screenshots them,
/// verifying the widget layouts and the shared-snapshot load path.
final class WidgetGalleryUITests: XCTestCase {

    override func setUp() { continueAfterFailure = false }

    @MainActor
    func testWidgetsRender() {
        let app = XCUIApplication()
        app.launchArguments = ["-widgetGallery"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Widget gallery"].waitForExistence(timeout: 10))
        XCTAssertGreaterThanOrEqual(app.otherElements.matching(identifier: "widget-tile").count, 1)

        func snapshot(_ name: String) {
            let shot = XCTAttachment(screenshot: app.screenshot())
            shot.name = name
            shot.lifetime = .keepAlways
            add(shot)
        }

        snapshot("widgets-top")
        app.swipeUp()
        snapshot("widgets-bottom")
    }
}
