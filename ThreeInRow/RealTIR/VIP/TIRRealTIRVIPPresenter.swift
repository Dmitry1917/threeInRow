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
    
    init(modelElement: TIRRealTIRVIPModelElement)
    {
        self.type = modelElement.elementType
        self.row = modelElement.coordinates.row
        self.column = modelElement.coordinates.column
    }
}

protocol TIRRealTIRVIPPresenterProtocol
{
    func prepareFieldPresentation(field: [[TIRRealTIRVIPModelElement]])
    func prepareExamplesAllTypes(examples: [TIRRealTIRVIPModelElement])
    func prepareChoosedCell(coord: (row: Int, column: Int))
    func prepareUnsuccessfullSwap(first: (row: Int, column: Int), second: (row: Int, column: Int))
    func prepareSuccessfullSwap(first: (row: Int, column: Int), second: (row: Int, column: Int))
    func prepareNoChains()
    func prepareRemoveChains(chains: [[TIRRealTIRVIPModelElement]])
    func prepareGravity(oldCoords: [(row: Int, column: Int)], newCoords: [(row: Int, column: Int)])
    func prepareRefillFieldByColumns(columns: [[TIRRealTIRVIPModelElement]])
}

class TIRRealTIRVIPPresenter: NSObject, TIRRealTIRVIPPresenterProtocol
{
    unowned var view: TIRRealTIRVIPViewProtocol
    
    init(view: TIRRealTIRVIPViewProtocol)
    {
        self.view = view
    }
    
    func prepareFieldPresentation(field: [[TIRRealTIRVIPModelElement]]) {
        
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
    
    func prepareRemoveChains(chains: [[TIRRealTIRVIPModelElement]]) {
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
    
    func prepareGravity(oldCoords: [(row: Int, column: Int)], newCoords: [(row: Int, column: Int)]) {
        
        view.animateFieldChanges(oldViewCoords: oldCoords, newViewCoords: newCoords)
    }
    
    func prepareRefillFieldByColumns(columns: [[TIRRealTIRVIPModelElement]]) {
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
    
    func prepareExamplesAllTypes(examples: [TIRRealTIRVIPModelElement]) {
        var examplesViews = [TIRRealTIRVIPViewModelElement]()
        
        for elementModel in examples
        {
            let elementView = TIRRealTIRVIPViewModelElement(modelElement: elementModel)
            examplesViews.append(elementView)
        }
        
        view.examplesAllTypes(examples: examplesViews)
    }
}
