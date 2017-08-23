//
//  TIRPresenter.swift
//  ThreeInRow
//
//  Created by DMITRY SINYOV on 12.07.17.
//  Copyright © 2017 DMITRY SINYOV. All rights reserved.
//

import Foundation

class TIRVIPViewModelElement: NSObject
{
    var type: TIRElementMainTypes = .elementUndefined
    var row: Int = 0
    var column: Int = 0
    
    init(modelElement: TIRVIPModelElement)
    {
        self.type = modelElement.elementType
        self.row = modelElement.coordinates.row
        self.column = modelElement.coordinates.column
    }
}

protocol TIRVIPPresenterProtocol
{
    func prepareFieldPresentation(field: [[TIRVIPModelElement]])
    func prepareExamplesAllTypes(examples: [TIRVIPModelElement])
    func prepareChoosedCell(coord: (row: Int, column: Int))
    func prepareUnsuccessfullSwap(first: (row: Int, column: Int), second: (row: Int, column: Int))
    func prepareSuccessfullSwap(first: (row: Int, column: Int), second: (row: Int, column: Int))
    func prepareNoChains()
    func prepareRemoveChains(chains: [[TIRVIPModelElement]])
    func prepareGravity(oldCoords: [(row: Int, column: Int)], newCoords: [(row: Int, column: Int)])
    func prepareRefillFieldByColumns(columns: [[TIRVIPModelElement]])
}

class TIRVIPPresenter: NSObject, TIRVIPPresenterProtocol
{
    weak var view: TIRVIPViewProtocol?
    
    init(view: TIRVIPViewProtocol)
    {
        self.view = view
    }
    
    func prepareFieldPresentation(field: [[TIRVIPModelElement]]) {
        
        let fieldViewModel = field.map {
            (columnElements) -> [TIRVIPViewModelElement] in
            
            let columnViewElements = columnElements.map {
                (modelElement) -> TIRVIPViewModelElement in
                
                return TIRVIPViewModelElement(modelElement: modelElement)
            }
            return columnViewElements
        }
        
        view?.setField(newField: fieldViewModel, reloadNow: true)
    }
    
    func prepareChoosedCell(coord: (row: Int, column: Int)) {
        view?.chooseCell(coord: coord)
    }
    
    func prepareUnsuccessfullSwap(first: (row: Int, column: Int), second: (row: Int, column: Int)) {
        view?.animateUnsuccessfullSwap(first: first, second: second)
    }
    func prepareSuccessfullSwap(first: (row: Int, column: Int), second: (row: Int, column: Int)) {
        view?.animateSuccessfullSwap(first: first, second: second)
    }
    
    func prepareNoChains() {
        view?.changesEnded()
    }
    
    func prepareRemoveChains(chains: [[TIRVIPModelElement]]) {
        //подготовка к анимации удаления
        var removingElements = [TIRVIPViewModelElement]()
        for chain in chains
        {
            for modelElement in chain
            {
                removingElements.append(TIRVIPViewModelElement(modelElement: modelElement))
            }
        }
        view?.animateElementsRemove(elements: removingElements)
    }
    
    func prepareGravity(oldCoords: [(row: Int, column: Int)], newCoords: [(row: Int, column: Int)]) {
        
        view?.animateFieldChanges(oldViewCoords: oldCoords, newViewCoords: newCoords)
    }
    
    func prepareRefillFieldByColumns(columns: [[TIRVIPModelElement]]) {
        let columnsViewModel = columns.map {
            (columnElements) -> [TIRVIPViewModelElement] in
            
            let columnViewElements = columnElements.map {
                (modelElement) -> TIRVIPViewModelElement in
                
                return TIRVIPViewModelElement(modelElement: modelElement)
            }
            return columnViewElements
        }
        
        view?.animateFieldRefill(columns: columnsViewModel)
    }
    
    func prepareExamplesAllTypes(examples: [TIRVIPModelElement]) {
        var examplesViews = [TIRVIPViewModelElement]()
        
        for elementModel in examples
        {
            let elementView = TIRVIPViewModelElement(modelElement: elementModel)
            examplesViews.append(elementView)
        }
        
        view?.examplesAllTypes(examples: examplesViews)
    }
}
