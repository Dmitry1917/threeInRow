//
//  ThreeInRowUITests.swift
//  ThreeInRowUITests
//
//  Created by DMITRY SINYOV on 23.08.17.
//  Copyright © 2017 DMITRY SINYOV. All rights reserved.
//

import XCTest

class ThreeInRowUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSeveralFieldTouches() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCUIDevice.shared.orientation = .faceUp
        
        let app = XCUIApplication()
        app.buttons["Three in row"].tap()
        
        let collectionViewsQuery = app.collectionViews
        let element = collectionViewsQuery.children(matching: .cell).element(boundBy: 27).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element
        let element2 = collectionViewsQuery.children(matching: .cell).element(boundBy: 28).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element
        //element.tap()
        //element2.tap()
        element.press(forDuration: 0.2, thenDragTo: element2)
        
        app.navigationBars["ThreeInRow.TIRVIPERView"].children(matching: .button).matching(identifier: "Back").element(boundBy: 0).tap()
        
        XCTAssertTrue(app.buttons["Three in row"].exists, "not in first screen")
    }
    
}
