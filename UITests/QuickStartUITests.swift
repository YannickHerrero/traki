import XCTest

/// Verifies the App-Intent quick-start path: a pending start request (as a widget
/// button would create) drops the app straight into the Active Timer on launch.
final class QuickStartUITests: XCTestCase {

    override func setUp() { continueAfterFailure = false }

    @MainActor
    func testPendingIntentStartsTimer() {
        let app = XCUIApplication()
        app.launchArguments = ["-simulateIntentStart", "read"]
        app.launch()

        // The app consumes the pending request and shows the Active Timer.
        let stop = app.buttons["stop-save"]
        XCTAssertTrue(stop.waitForExistence(timeout: 10),
                      "A pending quick-start should open the Active Timer")

        // Clean up so the saved session doesn't accumulate noise.
        stop.tap()
        _ = app.buttons["done"].waitForExistence(timeout: 5)
        app.buttons["done"].tap()
    }
}
