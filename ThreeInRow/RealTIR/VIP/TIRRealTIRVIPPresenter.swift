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
        
        view.setField(newField: fieldViewModel)
    }
    /*
    func examplesAllTypes() -> [TIRRealTIRVIPViewModelElement]
    {
        let examplesModel = model.examplesAllTypes()
        
        var examplesView = [TIRRealTIRVIPViewModelElement]()
        
        for elementModel in examplesModel
        {
            let elementView = TIRRealTIRViewModelElement(modelElement: elementModel)
            examplesView.append(elementView)
        }
        
        return examplesView
    }
    
    func removeThreesAndMore()
    {
        let chainsForRemove = findChains()
        
        guard chainsForRemove.count > 0 else {
            view.animationSequenceStoped()
            return
        }
        
        //подготовка к анимации удаления
        var removingElements = [TIRRealTIRViewModelElement]()
        for chain in chainsForRemove
        {
            for modelElement in chain
            {
                removingElements.append(TIRRealTIRViewModelElement(modelElement: modelElement))
            }
        }
        
        removeChains(chains: chainsForRemove)
        
        view.animateElementsRemove(elements: removingElements, completion: {
            self.useGravityOnField()
        })
    }
    
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
