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
//    func examplesAllTypes() -> [TIRRealTIRVIPViewModelElement]
//    func useGravityOnField()
//    func refillFieldByColumns() -> [[TIRRealTIRVIPViewModelElement]]
//    func canTrySwap(row1: Int, column1: Int, row2: Int, column2: Int) -> Bool
//    func canSwap(row1: Int, column1: Int, row2: Int, column2: Int) -> Bool
//    func elementByCoord(row: Int, column: Int) -> TIRRealTIRVIPViewModelElement?
//    func moveElementFromTo(row1: Int, column1: Int, row2: Int, column2: Int)
//    
//    func removeThreesAndMore()
    
    
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

//презентер не должен знать об индексах таблицы//
//презентер не является просто передатчиком из view в model за редким исключением, иначе что-то неверно в архитектуре
//то что анимация идёт, известно presenter, но сами анимационные действия только в view//
//закешированные картинки для анимаций создаёт и хранит view//
//view не знает об устройстве модели и не работает с объектами, напримую полученными из неё//

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
        
//        let refillHandler = {
//            
//            let refilledColumns = self.refillFieldByColumns()
//            self.view.animateFieldRefill(columns: refilledColumns)
//        }
        
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
    /*
    func findChains() -> [[TIRRealTIRModelElement]]
    {
        return model.findChains()
    }
    func removeChains(chains: [[TIRRealTIRModelElement]])
    {
        return model.removeChains(chains: chains)
    }
    func useGravityOnField()
    {
        let (oldCoords, newCoords) = model.useGravityOnField()
        
        let oldViewCoords: [(row: Int, column: Int)] = oldCoords.map
        { (coord) -> (row: Int, column: Int) in
            
            return (row: coord.row, column: coord.column)
        }
        let newViewCoords: [(row: Int, column: Int)] = newCoords.map
        { (coord) -> (row: Int, column: Int) in
            
            return (row: coord.row, column: coord.column)
        }
        
        let refillHandler = {
            
            let refilledColumns = self.refillFieldByColumns()
            self.view.animateFieldRefill(columns: refilledColumns)
        }
        
        view.animateFieldChanges(oldViewCoords: oldViewCoords, newViewCoords: newViewCoords, completionHandler: refillHandler)
    }
    
    func refillFieldByColumns() -> [[TIRRealTIRVIPViewModelElement]]
    {
        return model.refillFieldByColumns().map {
            (columnElements) -> [TIRRealTIRVIPViewModelElement] in
            
            let columnViewElements = columnElements.map {
                (modelElement) -> TIRRealTIRVIPViewModelElement in
                
                return TIRRealTIRVIPViewModelElement(modelElement: modelElement)
            }
            return columnViewElements
        }
    }
    func canTrySwap(row1: Int, column1: Int, row2: Int, column2: Int) -> Bool//проверка, что ячейки являются соседями по горизонтали или вертикали
    {
        return model.canTrySwap(fromCoord: TIRRowColumn(row: row1, column: column1), toCoord: TIRRowColumn(row: row2, column: column2))
    }
    func canSwap(row1: Int, column1: Int, row2: Int, column2: Int) -> Bool//проверка, что ячейки можно поменять реально (получившееся состояние будет допустимым)
    {
        return model.canSwap(fromCoord: TIRRowColumn(row: row1, column: column1), toCoord: TIRRowColumn(row: row2, column: column2))
    }
    func elementByCoord(row: Int, column: Int) -> TIRRealTIRVIPViewModelElement?
    {
        guard let elementModel = model.elementByCoord(coord: TIRRowColumn(row: row, column: column)) else { return nil }
        let elementView = TIRRealTIRVIPViewModelElement(modelElement: elementModel)
        return elementView
    }
    func moveElementFromTo(row1: Int, column1: Int, row2: Int, column2: Int)
    {
        return model.swapElementsByCoords(firstCoord: TIRRowColumn(row: row1, column: column1), secondCoord: TIRRowColumn(row: row2, column: column2))
    }
*/
}
