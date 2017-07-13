//
//  TIRRealTIRPresenter.swift
//  ThreeInRow
//
//  Created by DMITRY SINYOV on 12.07.17.
//  Copyright © 2017 DMITRY SINYOV. All rights reserved.
//

import Foundation

class TIRRealTIRViewModelElement: NSObject
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

protocol TIRRealTIRPresenterProtocol
{
    var itemsPerRow: Int { get }
    var rowsCount: Int { get }
    
    var isAnimating: Bool { get set }
    
    func examplesAllTypes() -> [TIRRealTIRViewModelElement]
    func useGravityOnField()
    func refillFieldByColumns() -> [[TIRRealTIRViewModelElement]]
    func canTrySwap(fromIndex: IndexPath, toIndex: IndexPath) -> Bool
    func canSwap(fromIndex: IndexPath, toIndex: IndexPath) -> Bool
    func elementByCoord(row: Int, column: Int) -> TIRRealTIRViewModelElement?
    func swapElementsByCoords(row1: Int, column1: Int, row2: Int, column2: Int)
    
    func removeThreesAndMore()
}

//презентер не должен знать об индексах таблицы
//презентер не является просто передатчиком из view в model за редким исключением, иначе что-то неверно в архитектуре
//то что анимация идёт, известно presenter, но сами анимационные действия только в view
//закешированные картинки для анимаций создаёт и хранит view
//view не знает об устройстве модели и не работает с объектами, напримую полученными из неё

class TIRRealTIRPresenter: NSObject, TIRRealTIRPresenterProtocol
{
    unowned var view: TIRRealTIRViewProtocol
    var model: TIRRealTIRModelProtocol!
    
    var itemsPerRow: Int { get { return model.itemsPerRow } }
    var rowsCount: Int { get { return model.rowsCount } }
    
    var isAnimating: Bool = false
    
    init(view: TIRRealTIRViewProtocol, model: TIRRealTIRModelProtocol)
    {
        self.view = view
        self.model = model
        
        self.model.setupModel()
    }
    
    func examplesAllTypes() -> [TIRRealTIRViewModelElement]
    {
        let examplesModel = model.examplesAllTypes()
        
        var examplesView = [TIRRealTIRViewModelElement]()
        
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
            self.isAnimating = false
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
    
    func refillFieldByColumns() -> [[TIRRealTIRViewModelElement]]
    {
        return model.refillFieldByColumns().map {
            (columnElements) -> [TIRRealTIRViewModelElement] in
            
            let columnViewElements = columnElements.map {
                (modelElement) -> TIRRealTIRViewModelElement in
                
                return TIRRealTIRViewModelElement(modelElement: modelElement)
            }
            return columnViewElements
        }
    }
    func canTrySwap(fromIndex: IndexPath, toIndex: IndexPath) -> Bool//проверка, что ячейки являются соседями по горизонтали или вертикали
    {
        let fromRow = fromIndex.row / model.itemsPerRow
        let fromColumn = fromIndex.row % model.itemsPerRow
        let toRow = toIndex.row / model.itemsPerRow
        let toColumn = toIndex.row % model.itemsPerRow
        
        return model.canTrySwap(fromCoord: TIRRowColumn(row: fromRow, column: fromColumn), toCoord: TIRRowColumn(row: toRow, column: toColumn))
    }
    func canSwap(fromIndex: IndexPath, toIndex: IndexPath) -> Bool//проверка, что ячейки можно поменять реально (получившееся состояние будет допустимым)
    {
        let toRow = toIndex.row / model.itemsPerRow
        let toColumn = toIndex.row % model.itemsPerRow
        let fromRow = fromIndex.row / model.itemsPerRow
        let fromColumn = fromIndex.row % model.itemsPerRow
        
        return model.canSwap(fromCoord: TIRRowColumn(row: fromRow, column: fromColumn), toCoord: TIRRowColumn(row: toRow, column: toColumn))
    }
    func elementByCoord(row: Int, column: Int) -> TIRRealTIRViewModelElement?
    {
        guard let elementModel = model.elementByCoord(coord: TIRRowColumn(row: row, column: column)) else { return nil }
        let elementView = TIRRealTIRViewModelElement(modelElement: elementModel)
        return elementView
    }
    func swapElementsByCoords(row1: Int, column1: Int, row2: Int, column2: Int)
    {
        return model.swapElementsByCoords(firstCoord: TIRRowColumn(row: row1, column: column1), secondCoord: TIRRowColumn(row: row2, column: column2))
    }
}
