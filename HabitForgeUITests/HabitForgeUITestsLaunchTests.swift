//
//  HabitForgeUITestsLaunchTests.swift
//  HabitForgeUITests
//
//  Created by Praveet Gupta on 05/04/26.
//

import XCTest

final class HabitForgeUITestsLaunchTests: XCTestCase {

    /// The Xcode template sets this to `true`, which reruns the launch capture once per target
    /// application UI configuration and leaves the device in the last one it used. In a serial
    /// run that state carries into `WorkoutFlowUITests`, where the routine form's "Add Exercise"
    /// row ends up off-screen — and a SwiftUI `List` drops off-screen rows from the
    /// accessibility tree, so the query finds nothing. One launch capture is all this needs.
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        false
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app
        // XCUIAutomation Documentation
        // https://developer.apple.com/documentation/xcuiautomation

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
