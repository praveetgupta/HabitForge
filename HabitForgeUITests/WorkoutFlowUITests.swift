import XCTest

/// End-to-end verification of the workout flow on the simulator:
/// routine creation → start → set logging → rest timer → finish → summary → history.
/// Fully self-contained: creates its own routine via the UI, so it passes against a
/// fresh app container.
///
/// Waits that assert something *must* appear are generous, because these run last in the
/// suite when the machine has had simulators up for several minutes and sheet presentation
/// can take well over the 4s these used to allow. The short timeouts on `if`/`guard` probes
/// are deliberate — those ask "is this already here?" and should not stall.
final class WorkoutFlowUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Navigates to Workouts and guarantees at least one routine exists, creating
    /// "QA Routine" through the UI when the library is empty.
    private func ensureRoutineExists(_ app: XCUIApplication) {
        app.tabBars.buttons["Workouts"].tap()

        if app.buttons["Start Workout"].firstMatch.waitForExistence(timeout: 3) { return }

        // Empty library: the ContentUnavailableView offers a New Routine action.
        let newRoutine = app.buttons["New Routine"].firstMatch
        XCTAssertTrue(newRoutine.waitForExistence(timeout: 15), "New Routine button missing")
        newRoutine.tap()

        let nameField = app.textFields["routineNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 15), "Routine name field missing")
        nameField.tap()
        nameField.typeText("QA Routine")

        // Add one exercise via the picker before saving (exercises the draft path).
        let addExercise = app.buttons["Add Exercise"].firstMatch
        XCTAssertTrue(addExercise.waitForExistence(timeout: 15), "Add Exercise row missing")
        addExercise.tap()

        // The picker's library is sorted by name; "Ab Wheel Rollout" is first.
        // Row labels concatenate the muscle/equipment subtitle, so match by prefix.
        let firstExercise = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Ab Wheel Rollout")
        ).firstMatch
        XCTAssertTrue(firstExercise.waitForExistence(timeout: 15), "Exercise list did not appear")
        firstExercise.tap()

        let save = app.buttons["Save"]
        XCTAssertTrue(save.waitForExistence(timeout: 15), "Save button missing")
        save.tap()

        XCTAssertTrue(
            app.buttons["Start Workout"].firstMatch.waitForExistence(timeout: 15),
            "Routine card did not appear after saving"
        )
    }

    /// If a session is in progress (resume banner on the dashboard), discards it.
    private func discardActiveSessionIfNeeded(_ app: XCUIApplication) {
        let resume = app.buttons["Resume workout in progress"]
        guard resume.waitForExistence(timeout: 3) else { return }
        resume.tap()

        let close = app.buttons["Close"].firstMatch
        XCTAssertTrue(close.waitForExistence(timeout: 15), "Close button missing in active workout")
        close.tap()
        let discard = app.buttons["Discard Workout"]
        XCTAssertTrue(discard.waitForExistence(timeout: 15), "Discard dialog did not appear")
        discard.tap()
        _ = resume.waitForNonExistence(timeout: 4)
    }

    /// Starts a workout: either resumes the active session or starts a fresh one.
    private func startWorkout(_ app: XCUIApplication) {
        let resume = app.buttons["Resume workout in progress"]
        if resume.waitForExistence(timeout: 2) {
            resume.tap()
        } else {
            let start = app.buttons["Start Workout"].firstMatch
            XCTAssertTrue(start.waitForExistence(timeout: 15), "No Start Workout button found")
            start.tap()
        }
    }

    func testRestTimerAdjustAndSkip() throws {
        let app = XCUIApplication()
        app.launch()
        ensureRoutineExists(app)
        discardActiveSessionIfNeeded(app)
        startWorkout(app)

        // Complete set 1 (reps prefilled) — starts the rest timer.
        let check = app.buttons["Complete set 1"]
        XCTAssertTrue(check.waitForExistence(timeout: 15), "Set 1 checkmark not found")
        check.tap()

        let plus15 = app.buttons["+15s"]
        XCTAssertTrue(plus15.waitForExistence(timeout: 15), "Rest timer bar did not appear")

        func currentRestSeconds() -> Int? {
            let label = app.staticTexts["restCountdown"]
            guard label.exists else { return nil }
            let parts = label.label.split(separator: ":").compactMap { Int($0) }
            guard parts.count == 2 else { return nil }
            return parts[0] * 60 + parts[1]
        }

        let before = currentRestSeconds()
        XCTAssertNotNil(before, "Could not read rest countdown")

        plus15.tap()
        let afterPlus = currentRestSeconds() ?? 0
        XCTAssertGreaterThan(afterPlus, before! + 10, "+15s did not extend the timer")

        plus15.tap()
        let afterPlus2 = currentRestSeconds() ?? 0
        XCTAssertGreaterThan(afterPlus2, afterPlus + 10, "Second +15s did not extend the timer")

        // Skip dismisses the bar.
        app.buttons["Skip rest"].tap()
        XCTAssertTrue(plus15.waitForNonExistence(timeout: 4), "Rest bar still visible after skip")

        // −15s shortens a fresh timer.
        let check2 = app.buttons["Complete set 2"]
        XCTAssertTrue(check2.waitForExistence(timeout: 15))
        check2.tap()
        let minus15 = app.buttons["−15s"]
        XCTAssertTrue(minus15.waitForExistence(timeout: 15))
        let beforeMinus = currentRestSeconds() ?? 0
        minus15.tap()
        let afterMinus = currentRestSeconds() ?? 0
        XCTAssertLessThan(afterMinus, beforeMinus - 10, "−15s did not shorten the timer")

        // Clean up: discard the session.
        app.buttons["Close"].firstMatch.tap()
        let discard = app.buttons["Discard Workout"]
        XCTAssertTrue(discard.waitForExistence(timeout: 15), "Discard dialog did not appear")
        discard.tap()
    }

    func testFinishWorkoutShowsSummaryAndHistory() throws {
        let app = XCUIApplication()
        app.launch()
        ensureRoutineExists(app)
        discardActiveSessionIfNeeded(app)
        startWorkout(app)

        // Complete one set so the session has data.
        let check = app.buttons["Complete set 1"]
        if check.waitForExistence(timeout: 4) {
            check.tap()
        }

        let finish = app.buttons["Finish"]
        XCTAssertTrue(finish.waitForExistence(timeout: 15))
        finish.tap()

        // Summary sheet appears.
        XCTAssertTrue(
            app.navigationBars["Workout Complete"].waitForExistence(timeout: 15),
            "Workout summary sheet did not appear after Finish"
        )

        // Mood picker is on the summary — tap the happy face if present.
        let happy = app.buttons["😄"]
        if happy.waitForExistence(timeout: 2) { happy.tap() }

        app.buttons["Done"].tap()

        // Back on the dashboard: Recent Sessions is listed.
        XCTAssertTrue(
            app.staticTexts["Recent Sessions"].waitForExistence(timeout: 15),
            "Dashboard did not reappear after finishing"
        )

        // History via See All.
        let seeAll = app.buttons["See All"]
        if seeAll.waitForExistence(timeout: 2) {
            seeAll.tap()
            XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 15))
            app.navigationBars.buttons.firstMatch.tap() // back
        }

        // Progress via the toolbar chart icon.
        let chart = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Progress")).firstMatch
        if chart.exists {
            chart.tap()
            XCTAssertTrue(app.navigationBars["Progress"].waitForExistence(timeout: 15))
        }
    }
}

extension XCUIElement {
    @discardableResult
    func waitForNonExistence(timeout: TimeInterval) -> Bool {
        let gone = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: gone, object: self)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
}
