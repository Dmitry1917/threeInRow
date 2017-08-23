//
//  RealTIRModelTests.swift
//  ThreeInRow
//
//  Created by DMITRY SINYOV on 09.07.17.
//  Copyright © 2017 DMITRY SINYOV. All rights reserved.
//

import XCTest

@testable import ThreeInRow

class MVPModelTests: XCTestCase {
    
    var model = TIRMVPModel()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        model.setupModel()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testPotentiallySwappableElements() {
        
        let swappableCoord1a = TIRRowColumn(row: 0, column: 0)
        let swappableCoord1b = TIRRowColumn(row: 1, column: 0)
        
        let swappableCoord2a = TIRRowColumn(row: 4, column: 4)
        let swappableCoord2b = TIRRowColumn(row: 4, column: 5)
        
        let unswappableCoord1a = TIRRowColumn(row: 0, column: 0)
        let unswappableCoord1b = TIRRowColumn(row: 0, column: 7)
        
        let unswappableCoord2a = TIRRowColumn(row: 3, column: 4)
        let unswappableCoord2b = TIRRowColumn(row: 3, column: 6)
        
        XCTAssert(model.canTrySwap(fromCoord: swappableCoord1a, toCoord: swappableCoord1b))
        XCTAssert(model.canTrySwap(fromCoord: swappableCoord2a, toCoord: swappableCoord2b))
        XCTAssert(!model.canTrySwap(fromCoord: unswappableCoord1a, toCoord: unswappableCoord1b))
        XCTAssert(!model.canTrySwap(fromCoord: unswappableCoord2a, toCoord: unswappableCoord2b))
    }
    
}
