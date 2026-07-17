import XCTest

/// End-to-end smoke test of the core loop:
/// Home → tap a mode → Active Timer runs → Stop & save → Session Complete → Done.
final class CoreLoopUITests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testTrackStopAndSaveASession() {
        let app = XCUIApplication()
        app.launch()

        // Home: start a Flashcards session.
        let card = app.buttons["mode-flash"]
        XCTAssertTrue(card.waitForExistence(timeout: 10), "Home mode card should be present")
        card.tap()

        // Active Timer: the Stop & save control appears.
        let stop = app.buttons["stop-save"]
        XCTAssertTrue(stop.waitForExistence(timeout: 10), "Active Timer should appear after tapping a mode")
        XCTAssertTrue(app.buttons["timer-pip"].exists,
                      "Active Timer should expose the Picture in Picture control")

        // Let the stopwatch run briefly, then stop.
        sleep(2)
        stop.tap()

        // Session Complete: the Done control appears.
        let done = app.buttons["done"]
        XCTAssertTrue(done.waitForExistence(timeout: 10), "Session Complete should appear after Stop & save")
        done.tap()

        // Back on Home.
        XCTAssertTrue(card.waitForExistence(timeout: 10), "Done should return to Home")
    }
}
