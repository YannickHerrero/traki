import XCTest

/// Captures the Statistics screen top and bottom so the charts (bars, breakdown,
/// trend, heatmap) can be eyeballed.
final class StatsUITests: XCTestCase {

    override func setUp() { continueAfterFailure = false }

    @MainActor
    func testStatsRenders() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["tab-stats"].tap()
        XCTAssertTrue(app.staticTexts["Statistics"].waitForExistence(timeout: 5))

        func snapshot(_ name: String) {
            let shot = XCTAttachment(screenshot: app.screenshot())
            shot.name = name
            shot.lifetime = .keepAlways
            add(shot)
        }

        snapshot("stats-top")
        app.swipeUp()
        app.swipeUp()
        snapshot("stats-bottom")
    }
}
