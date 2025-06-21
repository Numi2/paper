//
//  PaperUITestsLaunchTests.swift
//  PaperUITests
//
//  Created by T on 6/20/25.
//

import XCTest

final class PaperUITestsLaunchTests: XCTestCase {

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()
        // Simple test to verify the app can launch
        XCTAssertTrue(app.state == .runningForeground)
    }
}
