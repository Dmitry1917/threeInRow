//
//  TIRMVPPresenter.swift
//  ThreeInRow
//
//  Created by DMITRY SINYOV on 12.07.17.
//  Copyright © 2017 DMITRY SINYOV. All rights reserved.
//

import Foundation

class TIRMVPViewModelElement: NSObject
{
    var type: TIRElementMainTypes = .elementUndefined
    var row: Int = 0
    var column: Int = 0
    
    init(modelElement: TIRMVPModelElement)
    {
        self.type = modelElement.elementType
        self.row = modelElement.coordinates.row
        self.column = modelElement.coordinates.column
    }
}

protocol TIRMVPPresenterProtocol
{
    var itemsPerRow: Int { get }
    var rowsCount: Int { get }
    
    func examplesAllTypes() -> [TIRMVPViewModelElement]
    func useGravityOnField()
    func refillFieldByColumns() -> [[TIRMVPViewModelElement]]
    func canTrySwap(row1: Int, column1: Int, row2: Int, column2: Int) -> Bool
    func canSwap(row1: Int, column1: Int, row2: Int, column2: Int) -> Bool
    func elementByCoord(row: Int, column: Int) -> TIRMVPViewModelElement?
    func moveElementFromTo(row1: Int, column1: Int, row2: Int, column2: Int)
    
    func removeThreesAndMore()
}

class TIRMVPPresenter: NSObject, TIRMVPPresenterProtocol
{
    weak var view: TIRMVPViewProtocol?
    var model: TIRMVPModelProtocol!
    
    var itemsPerRow: Int { get { return model.itemsPerRow } }
    var rowsCount: Int { get { return model.rowsCount } }
    
    init(view: TIRMVPViewProtocol, model: TIRMVPModelProtocol)
    {
        self.view = view
        self.model = model
        
        self.model.setupModel()
    }
    
    func examplesAllTypes() -> [TIRMVPViewModelElement]
    {
        let examplesModel = model.examplesAllTypes()
        
        var examplesView = [TIRMVPViewModelElement]()
        
        for elementModel in examplesModel
        {
            let elementView = TIRMVPViewModelElement(modelElement: elementModel)
            examplesView.append(elementView)
        }
        
        return examplesView
    }
    
    func removeThreesAndMore()
    {
        let chainsForRemove = findChains()
        
        guard chainsForRemove.count > 0 else {
            view?.animationSequenceStoped()
            return
        }
        
        //подготовка к анимации удаления
        var removingElements = [TIRMVPViewModelElement]()
        for chain in chainsForRemove
        {
            for modelElement in chain
            {
                removingElements.append(TIRMVPViewModelElement(modelElement: modelElement))
            }
        }
        
        removeChains(chains: chainsForRemove)
        
        view?.animateElementsRemove(elements: removingElements, completion: {
            self.useGravityOnField()
        })
    }
    
    func findChains() -> [[TIRMVPModelElement]]
    {
        return model.findChains()
    }
    func removeChains(chains: [[TIRMVPModelElement]])
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
            self.view?.animateFieldRefill(columns: refilledColumns)
        }
        
        view?.animateFieldChanges(oldViewCoords: oldViewCoords, newViewCoords: newViewCoords, completionHandler: refillHandler)
    }
    
    func refillFieldByColumns() -> [[TIRMVPViewModelElement]]
    {
        return model.refillFieldByColumns().map {
            (columnElements) -> [TIRMVPViewModelElement] in
            
            let columnViewElements = columnElements.map {
                (modelElement) -> TIRMVPViewModelElement in
                
                return TIRMVPViewModelElement(modelElement: modelElement)
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
    func elementByCoord(row: Int, column: Int) -> TIRMVPViewModelElement?
    {
        guard let elementModel = model.elementByCoord(coord: TIRRowColumn(row: row, column: column)) else { return nil }
        let elementView = TIRMVPViewModelElement(modelElement: elementModel)
        return elementView
    }
    func moveElementFromTo(row1: Int, column1: Int, row2: Int, column2: Int)
    {
        return model.swapElementsByCoords(firstCoord: TIRRowColumn(row: row1, column: column1), secondCoord: TIRRowColumn(row: row2, column: column2))
    }
}
