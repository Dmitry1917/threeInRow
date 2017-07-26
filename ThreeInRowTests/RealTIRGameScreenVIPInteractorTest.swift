//
//  RealTIRGameScreenVIPInteractorTest.swift
//  ThreeInRow
//
//  Created by DMITRY SINYOV on 26.07.17.
//  Copyright © 2017 DMITRY SINYOV. All rights reserved.
//

import XCTest

@testable import ThreeInRow

class RealTIRGameScreenVIPInteractorTest: XCTestCase {
    
    var interactor: TIRRealTIRVIPInteractor!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        interactor = TIRRealTIRVIPInteractor()
        interactor.setupModel()
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
    
    class GameScreenInteractorOuterSpy: TIRRealTIRVIPPresenterProtocol {
        
        var changeSelectedCellCalled = false
        var newChoosedElement = (0, 0)
        var unsuccessfullSwap = false
        var successfullSwap = false
        var removingChains = [[TIRRealTIRVIPModelElement]]()
        
        func prepareFieldPresentation(field: [[TIRRealTIRVIPModelElement]])
        {
            
        }
        func prepareExamplesAllTypes(examples: [TIRRealTIRVIPModelElement])
        {
            
        }
        func prepareChoosedCell(coord: (row: Int, column: Int))
        {
            changeSelectedCellCalled = true
            newChoosedElement = coord
        }
        func prepareUnsuccessfullSwap(first: (row: Int, column: Int), second: (row: Int, column: Int))
        {
            unsuccessfullSwap = true
        }
        func prepareSuccessfullSwap(first: (row: Int, column: Int), second: (row: Int, column: Int))
        {
            successfullSwap = true
        }
        func prepareNoChains()
        {
            
        }
        func prepareRemoveChains(chains: [[TIRRealTIRVIPModelElement]])
        {
            removingChains = chains
        }
        func prepareGravity(oldCoords: [(row: Int, column: Int)], newCoords: [(row: Int, column: Int)])
        {
            
        }
        func prepareRefillFieldByColumns(columns: [[TIRRealTIRVIPModelElement]])
        {
            
        }
    }
    
    func testSwapElementsUnswapable() {
        let outerSpy = GameScreenInteractorOuterSpy()
        interactor.presenter = outerSpy
        
        interactor.swapElementsByCoordsIfCan(first: (0, 0), second: (0, 2))
        
        XCTAssert(outerSpy.changeSelectedCellCalled, "These elements can not be swaped - need choose new main cell")
        XCTAssert(outerSpy.newChoosedElement == (0, 2), "Another cell must be selected in this case")
    }
    func testSwapElementsSwapableUnsuccessfull() {
        let outerSpy = GameScreenInteractorOuterSpy()
        interactor.presenter = outerSpy
        
        let field = [0, 1, 2, 3, 4, 5, 0, 1,
                     2, 3, 4, 5, 0, 1, 2, 3,
                     4, 5, 0, 1, 2, 3, 4, 5,
                     0, 1, 2, 3, 4, 5, 0, 1,
                     2, 3, 4, 5, 0, 1, 2, 3,
                     4, 5, 0, 1, 2, 3, 4, 5,
                     0, 1, 2, 3, 4, 5, 0, 1,
                     2, 3, 4, 5, 0, 1, 2, 3]
        interactor.setupModelForTests(field: field)
        
        interactor.swapElementsByCoordsIfCan(first: (0, 0), second: (0, 1))
        
        XCTAssert(outerSpy.unsuccessfullSwap, "These elements must have unsuccessfull swap")
    }
    func testSwapElementsSwapableSuccessfull() {
        let outerSpy = GameScreenInteractorOuterSpy()
        interactor.presenter = outerSpy
        
        let field = [0, 1, 0, 0, 4, 5, 0, 1,
                     2, 3, 4, 5, 0, 1, 2, 3,
                     4, 5, 0, 1, 2, 3, 4, 5,
                     0, 1, 2, 3, 4, 5, 0, 1,
                     2, 3, 4, 5, 0, 1, 2, 3,
                     4, 5, 0, 1, 2, 3, 4, 5,
                     0, 1, 2, 3, 4, 5, 0, 1,
                     2, 3, 4, 5, 0, 1, 2, 3]
        interactor.setupModelForTests(field: field)
        
        interactor.swapElementsByCoordsIfCan(first: (0, 0), second: (0, 1))
        
        XCTAssert(outerSpy.successfullSwap, "These elements must have successfull swap")
    }
    
    func testRemoveThrees() {
        let outerSpy = GameScreenInteractorOuterSpy()
        interactor.presenter = outerSpy
        
        let field = [0, 0, 0, 0, 4, 5, 0, 1,
                     2, 3, 0, 5, 1, 1, 1, 1,
                     4, 5, 0, 1, 2, 3, 4, 1,
                     0, 1, 2, 3, 4, 5, 0, 1,
                     2, 3, 4, 5, 0, 1, 2, 3,
                     4, 5, 0, 1, 2, 2, 2, 2,
                     0, 1, 2, 3, 4, 5, 0, 1,
                     2, 3, 4, 5, 0, 1, 2, 3]
        interactor.setupModelForTests(field: field)
        
        interactor.removeThreesAndMore()
        
        XCTAssert(outerSpy.removingChains.count == 3, "Incorrect chains count")
    }
}
