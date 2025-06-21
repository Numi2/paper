//
//  PaperUITests.swift
//  PaperUITests
//
//  Created by T on 6/20/25.
//

import XCTest

final class PaperUITests: XCTestCase {

    @MainActor
    func testAppLaunches() throws {
        let app = XCUIApplication()
        app.launch()
        // Simple test to verify the app launches without crashing
        XCTAssertTrue(app.exists)
    }
}
