import XCTest

/// Drives the real app through the UI against the bundled sample feed.
@MainActor
final class CountryListUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    private func launch(_ argument: String = "-UITestStubFeed") {
        app.launchArguments = [argument]
        app.launch()
    }

    private var searchField: XCUIElement { app.searchFields.firstMatch }

    private func search(for text: String) {
        searchField.tap()
        searchField.typeText(text)
    }

    /// Leaves search the way a person does: the Cancel button, which iOS 26
    /// shows as a round "close" button while the keyboard is up.
    private func dismissSearch() {
        let cancel = app.buttons["Cancel"]
        (cancel.exists ? cancel : app.buttons["close"]).tap()
    }

    /// Rows in the country list (the keyboard has its own cells).
    private var countryRows: XCUIElementQuery { app.tables["country-list"].cells }

    private func country(_ code: String) -> XCUIElement { app.cells["country-\(code)"] }

    // MARK: Loading

    func testListShowsCountriesOnLaunch() {
        launch()

        XCTAssertTrue(app.navigationBars["Countries"].exists)
        XCTAssertTrue(country("AF").waitForExistence(timeout: 5))
        XCTAssertTrue(country("AF").label.contains("Afghanistan"))
        XCTAssertTrue(country("AF").label.contains("Kabul"))
    }

    func testCountryWithoutACapitalShowsNotAvailable() {
        launch()
        search(for: "Macao")

        XCTAssertTrue(country("MO").waitForExistence(timeout: 5))
        XCTAssertTrue(country("MO").label.contains("N/A"))
    }

    func testFirstPageOnlyThenMoreRowsWhileScrolling() {
        launch()
        XCTAssertTrue(country("AF").waitForExistence(timeout: 5))
        // The sample feed has 55 countries and the first page holds 20,
        // so the last one cannot be on screen or loaded yet.
        XCTAssertFalse(country("EH").exists)

        let list = app.tables["country-list"]
        for _ in 0..<20 where !country("EH").exists {
            list.swipeUp()
        }
        XCTAssertTrue(country("EH").exists, "Western Sahara, the last country, should load after scrolling")
    }

    // MARK: Search

    func testSearchByName() {
        launch()
        search(for: "japan")

        XCTAssertTrue(country("JP").waitForExistence(timeout: 5))
        XCTAssertFalse(country("AF").exists)
        XCTAssertEqual(countryRows.count, 1)
    }

    func testSearchByCapital() {
        launch()
        search(for: "tokyo")

        XCTAssertTrue(country("JP").waitForExistence(timeout: 5))
        XCTAssertEqual(countryRows.count, 1)
    }

    func testSearchIgnoresAccents() {
        launch()
        search(for: "cote")

        XCTAssertTrue(country("CI").waitForExistence(timeout: 5))
    }

    func testSearchWithNoMatchesShowsNoResults() {
        launch()
        search(for: "zzzz")

        XCTAssertTrue(app.staticTexts["No Results"].waitForExistence(timeout: 5))
        // UIKit can keep recycled cells in the accessibility tree after the
        // table empties, so check what is actually on screen instead.
        let visibleRows = countryRows.allElementsBoundByIndex.filter(\.isHittable)
        XCTAssertTrue(visibleRows.isEmpty, "rows still on screen: \(visibleRows.map(\.identifier))")
    }

    func testCancellingSearchRestoresTheList() {
        launch()
        search(for: "japan")
        XCTAssertTrue(country("JP").waitForExistence(timeout: 5))

        dismissSearch()

        XCTAssertTrue(country("AF").waitForExistence(timeout: 5))
        XCTAssertGreaterThan(countryRows.count, 5)
    }

    // MARK: Errors

    func testFailedLoadShowsRetryAndRecovers() {
        launch("-UITestFailFirstLoad")

        XCTAssertTrue(app.staticTexts["Couldn't Load Countries"].waitForExistence(timeout: 5))
        let retry = app.buttons["Retry"]
        XCTAssertTrue(retry.exists)
        XCTAssertFalse(country("AF").exists)

        retry.tap()

        XCTAssertTrue(country("AF").waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Couldn't Load Countries"].exists)
    }
}
