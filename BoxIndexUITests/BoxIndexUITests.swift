//
//  BoxIndexUITests.swift
//  BoxIndexUITests
//
//  Created by David P. Discher on 3/2/26.
//

import XCTest

final class BoxIndexUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCreateSearchEditAndSaveContainer() throws {
        let app = makeApp()
        app.launch()

        app.buttons["home.addContainer"].tap()

        let nameField = app.textFields["container.name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.tap()
        nameField.typeText("Attic Bin 12")

        let labelField = app.textFields["container.labelCode"]
        labelField.tap()
        labelField.typeText("AB-012")

        let locationField = app.textFields["container.location"]
        locationField.tap()
        locationField.typeText("Attic")

        app.buttons["container.save"].tap()

        let createdRow = app.buttons["Attic Bin 12, AB-012"]
        XCTAssertTrue(createdRow.waitForExistence(timeout: 2))

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 2))
        searchField.tap()
        searchField.typeText("AB-012")

        createdRow.tap()

        app.buttons["container.edit"].tap()

        let subLocationField = app.textFields["container.subLocation"]
        XCTAssertTrue(subLocationField.waitForExistence(timeout: 2))
        subLocationField.tap()
        subLocationField.typeText("Rear Rack")

        app.buttons["container.save"].tap()

        let locationValue = app.staticTexts["container.locationValue"]
        XCTAssertTrue(locationValue.waitForExistence(timeout: 2))
        XCTAssertEqual(locationValue.label, "Attic • Rear Rack")
    }

    @MainActor
    func testExportFlowShowsPreparedStatusInUITestMode() throws {
        let app = makeApp(seedDemoData: true)
        app.launch()

        app.tabBars.buttons["Backup"].tap()
        app.buttons["Export BoxIndex Data"].tap()

        let preparedMessage = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Prepared ")).firstMatch
        XCTAssertTrue(preparedMessage.waitForExistence(timeout: 2))
    }

    @MainActor
    func testScanQRScreenLoadsOnSupportedHardware() throws {
        #if targetEnvironment(simulator)
        throw XCTSkip("Live QR scanner smoke tests require supported iPhone hardware.")
        #else
        let app = makeApp(seedDemoData: true)
        app.launch()

        app.tabBars.buttons["QR"].tap()
        XCTAssertTrue(app.navigationBars["Scan QR"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Open Code"].waitForExistence(timeout: 2))
        #endif
    }

    @MainActor
    func testScanLabelScreenLoadsOnSupportedHardware() throws {
        #if targetEnvironment(simulator)
        throw XCTSkip("Live label scanner smoke tests require supported iPhone hardware.")
        #else
        let app = makeApp(seedDemoData: true)
        app.launch()

        app.tabBars.buttons["Label"].tap()
        XCTAssertTrue(app.navigationBars["Scan Label"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Match Label"].waitForExistence(timeout: 2))
        #endif
    }

    private func makeApp(seedDemoData: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "UITEST_USE_IN_MEMORY_STORE",
            "UITEST_DISABLE_DOCUMENT_PICKERS",
        ]

        if seedDemoData {
            app.launchArguments.append("UITEST_SEED_DEMO_DATA")
        }

        return app
    }
}
