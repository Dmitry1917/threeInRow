//
//  TIRRealTIRPresenter.swift
//  ThreeInRow
//
//  Created by DMITRY SINYOV on 12.07.17.
//  Copyright © 2017 DMITRY SINYOV. All rights reserved.
//

import UIKit

protocol TIRRealTIRPresenterProtocol
{
    var itemsPerRow: Int { get }
    var rowsCount: Int { get }
    
    func examplesAllTypes() -> [TIRRealTIRModelElement]
    func findChains() -> [[TIRRealTIRModelElement]]
    func removeChains(chains: [[TIRRealTIRModelElement]])
    func useGravityOnField() -> (oldCoords: [TIRRowColumn], newCoords: [TIRRowColumn])
    func refillFieldByColumns() -> [[TIRRealTIRModelElement]]
    func canTrySwap(fromIndex: IndexPath, toIndex: IndexPath) -> Bool
    func canSwap(fromIndex: IndexPath, toIndex: IndexPath) -> Bool
    func elementByCoord(coord: TIRRowColumn) -> TIRRealTIRModelElement?
    func swapElementsByCoords(firstCoord: TIRRowColumn, secondCoord: TIRRowColumn)
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
    
    init(view: TIRRealTIRViewProtocol, model: TIRRealTIRModelProtocol)
    {
        self.view = view
        self.model = model
        
        self.model.setupModel()
    }
    
    func examplesAllTypes() -> [TIRRealTIRModelElement]
    {
        return model.examplesAllTypes()
    }
    func findChains() -> [[TIRRealTIRModelElement]]
    {
        return model.findChains()
    }
    func removeChains(chains: [[TIRRealTIRModelElement]])
    {
        return model.removeChains(chains: chains)
    }
    func useGravityOnField() -> (oldCoords: [TIRRowColumn], newCoords: [TIRRowColumn])
    {
        return model.useGravityOnField()
    }
    func refillFieldByColumns() -> [[TIRRealTIRModelElement]]
    {
        return model.refillFieldByColumns()
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
    func elementByCoord(coord: TIRRowColumn) -> TIRRealTIRModelElement?
    {
        return model.elementByCoord(coord: coord)
    }
    func swapElementsByCoords(firstCoord: TIRRowColumn, secondCoord: TIRRowColumn)
    {
        return model.swapElementsByCoords(firstCoord: firstCoord, secondCoord: secondCoord)
    }
}
