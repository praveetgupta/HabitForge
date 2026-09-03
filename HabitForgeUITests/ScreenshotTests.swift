import XCTest

/// Regenerates the README screenshots from a fixed demo dataset, so they can be rebuilt on
/// demand rather than curated by hand from whatever was on the device.
///
///     xcodebuild test -project HabitForge.xcodeproj -scheme HabitForge \
///       -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
///       -only-testing:HabitForgeUITests/ScreenshotTests \
///       -resultBundlePath /tmp/shots.xcresult
///     xcrun xcresulttool export attachments --path /tmp/shots.xcresult --output-path /tmp/shots
///
/// `Tools/screenshots.sh` wraps both steps and files the PNGs into `screenshots/`.
final class ScreenshotTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// The app container survives between UI tests, so the demo dataset must not be left
    /// behind: with it in place `WorkoutFlowUITests` starts a five-exercise demo routine and
    /// its `"Complete set 1"` query matches five buttons instead of one. Resetting in
    /// teardown means it happens even when the capture above fails part-way through.
    override func tearDownWithError() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-HabitForgeResetStore"]
        app.launch()
        _ = app.tabBars.firstMatch.waitForExistence(timeout: 30)
        Thread.sleep(forTimeInterval: 2)
        app.terminate()
    }

    private func launchWithDemoData() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-HabitForgeDemoData"]
        app.launch()
        // The demo seed runs in a .task on first render; wait for the tab bar, then settle.
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 30), "App never launched")
        Thread.sleep(forTimeInterval: 3)
        return app
    }

    private func capture(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    private func tab(_ app: XCUIApplication, _ name: String) {
        app.tabBars.buttons[name].tap()
        Thread.sleep(forTimeInterval: 1.5)
    }

    @MainActor
    func testCaptureScreenshots() throws {
        let app = launchWithDemoData()

        // 1. Habits dashboard — summary ring, habit rings, progress graph.
        tab(app, "Habits")
        capture(app, "01-habits")

        // 2. All-habits progress, opened from the dashboard's expand control.
        let expand = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'expand' OR label CONTAINS[c] 'progress'")
        ).firstMatch
        if expand.waitForExistence(timeout: 3), expand.isHittable {
            expand.tap()
            Thread.sleep(forTimeInterval: 1.5)
            capture(app, "02-habit-progress")
            app.navigationBars.buttons.element(boundBy: 0).tap()
            Thread.sleep(forTimeInterval: 1)
        }

        // 3. Todos sidebar — the GTD lists, areas and projects.
        tab(app, "Todos")
        capture(app, "03-todos")

        // 4. Today, with its evening section.
        let today = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Today'")).firstMatch
        if today.waitForExistence(timeout: 3) {
            today.tap()
            Thread.sleep(forTimeInterval: 1.5)
            capture(app, "04-today")
            app.navigationBars.buttons.element(boundBy: 0).tap()
            Thread.sleep(forTimeInterval: 1)
        }

        // 5. Workouts dashboard — routine cards and recent sessions.
        tab(app, "Workouts")
        capture(app, "05-workouts")

        // 6. Workout progress — volume chart and recent PRs.
        let progress = app.navigationBars.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'progress' OR identifier CONTAINS[c] 'chart'")
        ).firstMatch
        if progress.waitForExistence(timeout: 3), progress.isHittable {
            progress.tap()
            Thread.sleep(forTimeInterval: 2)
            capture(app, "06-workout-progress")
            app.navigationBars.buttons.element(boundBy: 0).tap()
            Thread.sleep(forTimeInterval: 1)
        }

        // 7. Active workout — the set-logging grid and rest timer.
        let start = app.buttons["Start Workout"].firstMatch
        if start.waitForExistence(timeout: 5) {
            start.tap()
            Thread.sleep(forTimeInterval: 2)

            // Log one set so the grid shows a completed row, a PR badge and the rest timer.
            let complete = app.buttons.matching(
                NSPredicate(format: "label BEGINSWITH 'Complete set'")
            ).firstMatch
            if complete.waitForExistence(timeout: 4), complete.isHittable {
                complete.tap()
                Thread.sleep(forTimeInterval: 1.5)
            }
            capture(app, "07-active-workout")

            // Leave the session behind so the run is repeatable.
            let close = app.buttons["Close"].firstMatch
            if close.waitForExistence(timeout: 3) {
                close.tap()
                let discard = app.buttons.matching(
                    NSPredicate(format: "label CONTAINS[c] 'discard'")
                ).firstMatch
                if discard.waitForExistence(timeout: 3) { discard.tap() }
                Thread.sleep(forTimeInterval: 1)
            }
        }

        // 8. Settings — units, appearance, export, archive.
        tab(app, "Settings")
        capture(app, "08-settings")
    }
}
