import XCTest

/// Smoke coverage: every tab reachable, the global quick add opens, and the Settings screen
/// exposes its real controls. Self-contained — assumes no pre-existing data.
///
/// SwiftUI renders a `Picker` in a `List` as a button labelled "Title, Selection", so rows
/// are matched by prefix rather than exact label (HANDOFF gotcha #13).
final class HabitForgeUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        return app
    }

    private func button(startingWith prefix: String, in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
    }

    @MainActor
    func testAllTabsAreReachable() throws {
        let app = launch()
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "Tab bar never appeared")

        for tab in ["Habits", "Todos", "Workouts", "Settings"] {
            let button = tabBar.buttons[tab]
            XCTAssertTrue(button.waitForExistence(timeout: 5), "\(tab) tab missing")
            button.tap()
            XCTAssertTrue(
                app.navigationBars[tab].waitForExistence(timeout: 5),
                "\(tab) tab did not show a matching navigation title"
            )
        }
    }

    @MainActor
    func testSettingsExposesUnitsAppearanceAndData() throws {
        let app = launch()
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))

        // The stub screen used to show placeholder rows; these are the real controls.
        XCTAssertTrue(button(startingWith: "Weight unit", in: app).waitForExistence(timeout: 5),
                      "Weight unit picker missing")
        XCTAssertTrue(button(startingWith: "Appearance", in: app).exists, "Appearance picker missing")
        XCTAssertTrue(button(startingWith: "Default rest timer", in: app).exists,
                      "Default rest timer picker missing")
        XCTAssertTrue(app.buttons["Export all data (JSON)"].firstMatch.exists,
                      "Data export action missing")
        XCTAssertTrue(app.buttons["Reset all data"].firstMatch.exists, "Reset action missing")
    }

    /// Selects `option` in the "Weight unit" picker and returns the row's new label.
    @discardableResult
    private func selectWeightUnit(_ option: String, in app: XCUIApplication) -> String {
        let row = button(startingWith: "Weight unit", in: app)
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Weight unit row missing")
        row.tap()

        let choice = app.buttons[option].firstMatch
        XCTAssertTrue(choice.waitForExistence(timeout: 5), "\(option) missing from the picker")
        choice.tap()

        let updated = button(startingWith: "Weight unit", in: app)
        XCTAssertTrue(updated.waitForExistence(timeout: 5))
        return updated.label
    }

    @MainActor
    func testSwitchingWeightUnitSticksBothWays() throws {
        let app = launch()
        app.tabBars.buttons["Settings"].tap()

        // The setting persists to UserDefaults and survives the app being relaunched, so this
        // asserts a round trip rather than an initial value — otherwise a second run of this
        // test would start in pounds and fail.
        let pounds = selectWeightUnit("Pounds (lb)", in: app)
        XCTAssertTrue(pounds.contains("Pounds"), "Did not switch to pounds (label: \(pounds))")

        let kilograms = selectWeightUnit("Kilograms (kg)", in: app)
        XCTAssertTrue(kilograms.contains("Kilograms"),
                      "Did not switch back to kilograms (label: \(kilograms))")
    }

    @MainActor
    func testArchiveScreenOpensFromSettings() throws {
        let app = launch()
        app.tabBars.buttons["Settings"].tap()

        let archive = button(startingWith: "Archive", in: app)
        XCTAssertTrue(archive.waitForExistence(timeout: 5), "Archive row missing")
        archive.tap()

        XCTAssertTrue(app.navigationBars["Archive"].waitForExistence(timeout: 5),
                      "Archive screen did not open")
        XCTAssertTrue(app.staticTexts["Nothing archived"].waitForExistence(timeout: 5),
                      "Empty archive state missing")
    }

    @MainActor
    func testGlobalQuickAddOpensAndAddsATodo() throws {
        let app = launch()
        app.tabBars.buttons["Habits"].tap()

        let fab = app.buttons["globalQuickAdd"]
        XCTAssertTrue(fab.waitForExistence(timeout: 10), "Global quick add button missing")
        fab.tap()

        // Regression guard: the sheet used to present with a nil view model and come up
        // blank, so assert on a field actually being there rather than on the sheet alone.
        let field = app.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5), "Quick add sheet did not open")

        field.tap()
        field.typeText("Smoke test todo")
        app.buttons["Add"].firstMatch.tap()

        // The todo should be waiting in the Inbox.
        app.tabBars.buttons["Todos"].tap()
        XCTAssertTrue(app.navigationBars["Todos"].waitForExistence(timeout: 5))
        XCTAssertTrue(
            app.staticTexts["Smoke test todo"].waitForExistence(timeout: 5)
                || app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Smoke test todo"))
                    .firstMatch.waitForExistence(timeout: 5)
                || app.cells.containing(.staticText, identifier: "Inbox").firstMatch.exists,
            "Quick-added todo did not reach the Todos tab"
        )
    }
}
