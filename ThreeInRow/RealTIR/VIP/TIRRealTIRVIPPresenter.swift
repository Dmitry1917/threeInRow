//
//  TIRRealTIRPresenter.swift
//  ThreeInRow
//
//  Created by DMITRY SINYOV on 12.07.17.
//  Copyright © 2017 DMITRY SINYOV. All rights reserved.
//

import Foundation

class TIRRealTIRVIPViewModelElement: NSObject
{
    var type: TIRElementMainTypes = .elementUndefined
    var row: Int = 0
    var column: Int = 0
    
    init(modelElement: TIRRealTIRModelElement)
    {
        self.type = modelElement.elementType
        self.row = modelElement.coordinates.row
        self.column = modelElement.coordinates.column
    }
}

protocol TIRRealTIRVIPPresenterProtocol
{
    func prepareFieldPresentation(field: [[TIRRealTIRModelElement]])
    func prepareExamplesAllTypes(examples: [TIRRealTIRModelElement])
    func prepareChoosedCell(coord: (row: Int, column: Int))
    func prepareUnsuccessfullSwap(first: (row: Int, column: Int), second: (row: Int, column: Int))
    func prepareSuccessfullSwap(first: (row: Int, column: Int), second: (row: Int, column: Int))
    func prepareNoChains()
    func prepareRemoveChains(chains: [[TIRRealTIRModelElement]])
    func prepareGravity(oldCoords: [TIRRowColumn], newCoords: [TIRRowColumn])
    func prepareRefillFieldByColumns(columns: [[TIRRealTIRModelElement]])
}

class TIRRealTIRVIPPresenter: NSObject, TIRRealTIRVIPPresenterProtocol
{
    unowned var view: TIRRealTIRVIPViewProtocol
    
    init(view: TIRRealTIRVIPViewProtocol)
    {
        self.view = view
    }
    
    func prepareFieldPresentation(field: [[TIRRealTIRModelElement]]) {
        
        let fieldViewModel = field.map {
            (columnElements) -> [TIRRealTIRVIPViewModelElement] in
            
            let columnViewElements = columnElements.map {
                (modelElement) -> TIRRealTIRVIPViewModelElement in
                
                return TIRRealTIRVIPViewModelElement(modelElement: modelElement)
            }
            return columnViewElements
        }
        
        view.setField(newField: fieldViewModel, reloadNow: true)
    }
    
    func prepareChoosedCell(coord: (row: Int, column: Int)) {
        view.chooseCell(coord: coord)
    }
    
    func prepareUnsuccessfullSwap(first: (row: Int, column: Int), second: (row: Int, column: Int)) {
        view.animateUnsuccessfullSwap(first: first, second: second)
    }
    func prepareSuccessfullSwap(first: (row: Int, column: Int), second: (row: Int, column: Int)) {
        view.animateSuccessfullSwap(first: first, second: second)
    }
    
    func prepareNoChains() {
        view.changesEnded()
    }
    
    func prepareRemoveChains(chains: [[TIRRealTIRModelElement]]) {
        //подготовка к анимации удаления
        var removingElements = [TIRRealTIRVIPViewModelElement]()
        for chain in chains
        {
            for modelElement in chain
            {
                removingElements.append(TIRRealTIRVIPViewModelElement(modelElement: modelElement))
            }
        }
        view.animateElementsRemove(elements: removingElements)
    }
    
    func prepareGravity(oldCoords: [TIRRowColumn], newCoords: [TIRRowColumn]) {
        let oldViewCoords: [(row: Int, column: Int)] = oldCoords.map
        { (coord) -> (row: Int, column: Int) in
            
            return (row: coord.row, column: coord.column)
        }
        let newViewCoords: [(row: Int, column: Int)] = newCoords.map
        { (coord) -> (row: Int, column: Int) in
            
            return (row: coord.row, column: coord.column)
        }
        
        view.animateFieldChanges(oldViewCoords: oldViewCoords, newViewCoords: newViewCoords)
    }
    
    func prepareRefillFieldByColumns(columns: [[TIRRealTIRModelElement]]) {
        let columnsViewModel = columns.map {
            (columnElements) -> [TIRRealTIRVIPViewModelElement] in
            
            let columnViewElements = columnElements.map {
                (modelElement) -> TIRRealTIRVIPViewModelElement in
                
                return TIRRealTIRVIPViewModelElement(modelElement: modelElement)
            }
            return columnViewElements
        }
        
        view.animateFieldRefill(columns: columnsViewModel)
    }
    
    func prepareExamplesAllTypes(examples: [TIRRealTIRModelElement]) {
        var examplesViews = [TIRRealTIRVIPViewModelElement]()
        
        for elementModel in examples
        {
            let elementView = TIRRealTIRVIPViewModelElement(modelElement: elementModel)
            examplesViews.append(elementView)
        }
        
        view.examplesAllTypes(examples: examplesViews)
    }
}
