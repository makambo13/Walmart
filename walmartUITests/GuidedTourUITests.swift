import XCTest

/// A paced walk through the app, the way a person would use it. It checks the
/// main flow and attaches screenshots, and it is what the simulator recording
/// in the README is made from (see `scripts/record-tour.sh`).
@MainActor
final class GuidedTourUITests: XCTestCase {
    func testTourOfTheApp() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-UITestStubFeed"]
        app.launch()

        func pause(_ seconds: TimeInterval = 1.0) { Thread.sleep(forTimeInterval: seconds) }
        func capture(_ name: String) {
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = name
            attachment.lifetime = .keepAlways
            add(attachment)
        }

        // 1. Loading, then the list.
        pause(0.2)
        capture("01-loading")
        XCTAssertTrue(app.cells["country-AF"].waitForExistence(timeout: 5))
        pause()
        capture("02-list")

        // 2. Scroll to load more pages.
        let list = app.tables["country-list"]
        for _ in 0..<3 {
            list.swipeUp(velocity: .slow)
            pause(0.5)
        }
        capture("03-scrolled")
        list.swipeDown(velocity: .fast)
        list.swipeDown(velocity: .fast)
        list.swipeDown(velocity: .fast)
        pause()

        // 3. Search by name.
        let search = app.searchFields.firstMatch
        search.tap()
        pause(0.5)
        search.typeText("jo")
        pause()
        capture("04-search")
        XCTAssertTrue(app.cells["country-JO"].exists)

        // 4. Search by capital.
        search.clearAndType("tokyo")
        XCTAssertTrue(app.cells["country-JP"].waitForExistence(timeout: 5))
        pause()
        capture("05-search-capital")

        // 5. Nothing found.
        search.clearAndType("zzz")
        XCTAssertTrue(app.staticTexts["No Results"].waitForExistence(timeout: 5))
        pause()
        capture("06-no-results")

        // 6. Back to the full list.
        let cancel = app.buttons["Cancel"]
        (cancel.exists ? cancel : app.buttons["close"]).tap()
        XCTAssertTrue(app.cells["country-AF"].waitForExistence(timeout: 5))
        pause()
    }

    func testErrorAndRetry() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-UITestFailFirstLoad"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Couldn't Load Countries"].waitForExistence(timeout: 5))
        Thread.sleep(forTimeInterval: 0.5)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "07-error"
        attachment.lifetime = .keepAlways
        add(attachment)

        app.buttons["Retry"].tap()
        XCTAssertTrue(app.cells["country-AF"].waitForExistence(timeout: 5))
    }
}

private extension XCUIElement {
    /// Replaces the text in a search field by deleting what is there and typing anew.
    func clearAndType(_ text: String) {
        guard let current = value as? String, !current.isEmpty else {
            typeText(text)
            return
        }
        typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
        typeText(text)
    }
}
