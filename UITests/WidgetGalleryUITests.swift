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

        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "widgets"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
