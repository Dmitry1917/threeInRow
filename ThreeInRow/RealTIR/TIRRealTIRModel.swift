//
//  TIRRealTIRModel.swift
//  ThreeInRow
//
//  Created by DMITRY SINYOV on 12.06.17.
//  Copyright © 2017 DMITRY SINYOV. All rights reserved.
//

import UIKit

class TIRRealTIRModel: NSObject
{
    private var modelArray = [[TIRRealTIRModelElement]]()
    private(set) var itemsPerRow: Int = 8
    private(set) var rowsCount: Int = 8
    
    func setupModel()
    {
        modelArray = (0..<rowsCount).map
            { (i) -> [TIRRealTIRModelElement] in
                
                let rowContent: [TIRRealTIRModelElement] = (0..<itemsPerRow).map
                { (j) -> TIRRealTIRModelElement in
                    
                    let modelElement = TIRRealTIRModelElement()
                    
                    modelElement.elementType = TIRElementMainTypes.randomType()
                    modelElement.coordinates = TIRRowColumn(row: i, column: j)
                    
                    return modelElement
                }
                
                return rowContent
        }
    }
    
    func elementByCoord(coord: TIRRowColumn) -> TIRRealTIRModelElement?
    {
        guard coord.row >= 0 else { return nil }
        guard coord.column >= 0 else { return nil }
        guard coord.row < rowsCount else { return nil }
        guard coord.column < itemsPerRow else { return nil }
        return modelArray[coord.row][coord.column]
    }
    
    func swapElementsByCoords(firstCoord: TIRRowColumn, secondCoord: TIRRowColumn)
    {
        let sourceModelElement = elementByCoord(coord: firstCoord)
        let destinationModelElement = elementByCoord(coord: secondCoord)
        
        guard sourceModelElement != nil && destinationModelElement != nil else { return }
        
        sourceModelElement!.coordinates = secondCoord
        destinationModelElement!.coordinates = firstCoord
        modelArray[firstCoord.row][firstCoord.column] = modelArray[secondCoord.row][secondCoord.column]
        modelArray[secondCoord.row][secondCoord.column] = sourceModelElement!
    }
    
    func canTrySwap(fromCoord: TIRRowColumn, toCoord: TIRRowColumn) -> Bool//проверка, что ячейки являются соседями по горизонтали или вертикали
    {
        if abs(fromCoord.row - toCoord.row) < 2 && fromCoord.column == toCoord.column || abs(fromCoord.column - toCoord.column) < 2 && fromCoord.row == toCoord.row { return true }
        else { return false }
    }
    func canSwap(fromCoord: TIRRowColumn, toCoord: TIRRowColumn) -> Bool//проверка, что ячейки можно поменять реально (получившееся состояние будет допустимым)
    {
        let checkedModelElementFrom = modelArray[fromCoord.row][fromCoord.column]
        let checkedModelElementTo = modelArray[toCoord.row][toCoord.column]
        
        //проще оказалось временно поменять модель для проверки, чем постоянно учитывать, что она пока не соответствует проверяемому
        modelArray[fromCoord.row][fromCoord.column] = modelArray[toCoord.row][toCoord.column]
        modelArray[toCoord.row][toCoord.column] = checkedModelElementFrom
        
        //проверим наличие троек, в которые может входить данная ячейка
        let result = findThrees(checkedModelElement: checkedModelElementFrom, coords: toCoord) || findThrees(checkedModelElement: checkedModelElementTo, coords: fromCoord)//координаты переставлены, так как модель изменена на время проверки
        
        modelArray[toCoord.row][toCoord.column] = modelArray[fromCoord.row][fromCoord.column]
        modelArray[fromCoord.row][fromCoord.column] = checkedModelElementFrom
        
        return result
    }
    
    func findThrees(checkedModelElement: TIRRealTIRModelElement, coords: TIRRowColumn) -> Bool
    {
        //достаточно проверить соседей в радиусе 2-х клеток (от обеих поменянных местами), чтобы знать о тройках
        var sameTypeArray: [TIRRowColumn] = []
        
        var minRow = coords.row - 2
        var maxRow = coords.row + 2
        var minColumn = coords.column - 2
        var maxColumn = coords.column + 2
        
        if minRow < 0 { minRow = 0 }
        if maxRow > rowsCount - 1 { maxRow = rowsCount - 1}
        if minColumn < 0 { minColumn = 0 }
        if maxColumn > itemsPerRow - 1 { maxColumn = itemsPerRow - 1 }
        
        for row in minRow...maxRow
        {
            for column in minColumn...maxColumn
            {
                let modelElement = modelArray[row][column]
                
                if modelElement.elementType == checkedModelElement.elementType
                {
                    sameTypeArray.append(TIRRowColumn(row: row, column: column))
                }
            }
        }
        
        //print("\(sameTypeArray)")
        
        //проверим наличие подходящих групп соседних ячеек
        
        //для каждой ячейки находим соседние того же типа, затем для получившегося массива проверяем оставшиеся на подходящие соседства (у пары ячеек уже можно определить направление, значит нужно проверить только две подходящие координаты)
        for coordFirst in sameTypeArray
        {
            for coordSecond in sameTypeArray
            {
                guard coordFirst != coordSecond else { continue }
                //соседи ли
                if abs(coordFirst.row - coordSecond.row) < 2 && coordFirst.column == coordSecond.column || abs(coordFirst.column - coordSecond.column) < 2 && coordFirst.row == coordSecond.row
                {
                    //проверим наличие третьей по линии найденных ячеек
                    if coordFirst.row == coordSecond.row//на одной горизонтали
                    {
                        let minColumn = min(coordFirst.column, coordSecond.column) - 1
                        let maxColumn = max(coordFirst.column, coordSecond.column) + 1
                        
                        let seekCoordMin = TIRRowColumn(row: coordFirst.row, column: minColumn)
                        let seekCoordMax = TIRRowColumn(row: coordFirst.row, column: maxColumn)
                        
                        if sameTypeArray.contains(seekCoordMin) || sameTypeArray.contains(seekCoordMax) { return true }//нашли тройку - проверка удачна
                    }
                    else//на одной вертикали
                    {
                        let minRow = min(coordFirst.row, coordSecond.row) - 1
                        let maxRow = max(coordFirst.row, coordSecond.row) + 1
                        
                        let seekCoordMin = TIRRowColumn(row: minRow, column: coordFirst.column)
                        let seekCoordMax = TIRRowColumn(row: maxRow, column: coordFirst.column)
                        
                        if sameTypeArray.contains(seekCoordMin) || sameTypeArray.contains(seekCoordMax) { return true }//нашли тройку - проверка удачна
                    }
                    
                }
            }
        }
        
        return false
    }
    func findChains()
    {
        var realChains = [[TIRRealTIRModelElement]]()
        let potentialChains = findChainsMoreThan2()
        
        //уберём элементы цепей, не входящие в тройки - оставшиеся можно рассматривать, как удаляемые участки
        
        for var chain in potentialChains
        {
            print(chain)
            if chainWithThrees(chainArray: &chain)
            {
                realChains.append(chain)
            }
            
        }
    }
    func chainWithThrees(chainArray: inout [TIRRealTIRModelElement]) -> Bool
    {
        //пройдёмся по всем ячейкам и попытаемся найти в цепочке её двух соседей в одном направлении, если есть - оставляем, иначе убираем, если в цепочке таковых ячеек нет, то вся цепочка неподходит
        
        
        
        return true
    }
    func findChainsMoreThan2() -> [[TIRRealTIRModelElement]]
    {//как вариант, можно добавить тип объекта - пустой, чтобы не оперировать с отсутствующими?
        var allChains = [[TIRRealTIRModelElement]]()
        
        var tempModel : [[TIRRealTIRModelElement?]] = (0..<modelArray.count).map
        { (i) -> [TIRRealTIRModelElement] in
            
            let rowContent: [TIRRealTIRModelElement] = (0..<modelArray[0].count).map
            { (j) -> TIRRealTIRModelElement in
                
                return modelArray[i][j]
            }
            
            return rowContent
        }
        
        for row: [TIRRealTIRModelElement?] in tempModel
        {
            for element: TIRRealTIRModelElement? in row
            {
                //print("\(element)")
                if element != nil
                {
                    //print(getNeighbors(checkedElement: element!, checkedModel: tempModel))
                    
                    //рекурсивно проходим по соседям и добавляем в цепочку, если подходит, удаляя из модели
                    var chainArray : [TIRRealTIRModelElement] = [TIRRealTIRModelElement]()
                    //chainArray.append(TIRRealTIRModelElement())
                    getChainForElement(checkedElement: element!, chainArray: &chainArray, tempModel: &tempModel)
                    
                    if chainArray.count > 2
                    {
                        //print(chainArray)
                        allChains.append(chainArray)
                    }
                }
            }
        }
        
        return allChains
    }
    func getChainForElement(checkedElement: TIRRealTIRModelElement, chainArray: inout [TIRRealTIRModelElement], tempModel: inout [[TIRRealTIRModelElement?]])
    {
        chainArray.append(checkedElement)
        tempModel[checkedElement.coordinates.row][checkedElement.coordinates.column] = nil
        
        let neighbors = getNeighbors(checkedElement: checkedElement, checkedModel: tempModel)
        
        //сразу уберём всех соседей того же типа из проверки, чтобы не было самопересечений
        for neighbor in neighbors
        {
            if neighbor.elementType == checkedElement.elementType
            {
                tempModel[neighbor.coordinates.row][neighbor.coordinates.column] = nil
            }
        }
        
        for neighbor in neighbors
        {
            if neighbor.elementType == checkedElement.elementType
            {
                getChainForElement(checkedElement: neighbor, chainArray: &chainArray, tempModel: &tempModel)
            }
        }
    }
    func getNeighbors(checkedElement: TIRRealTIRModelElement, checkedModel: [[TIRRealTIRModelElement?]]) -> [TIRRealTIRModelElement]//получим соседей элемента в указанной модели (модель может быть частично заполнена и не все возможные соседи существуют)
    {
        var neighbors = [TIRRealTIRModelElement]()
        
        if checkedElement.coordinates.row > 0
        {
            if let neighbor = checkedModel[checkedElement.coordinates.row - 1][checkedElement.coordinates.column] {neighbors.append(neighbor)}
        }
        if checkedElement.coordinates.row < checkedModel.count-1
        {
            if let neighbor = checkedModel[checkedElement.coordinates.row + 1][checkedElement.coordinates.column] {neighbors.append(neighbor)}
        }
        if checkedElement.coordinates.column > 0
        {
            if let neighbor = checkedModel[checkedElement.coordinates.row][checkedElement.coordinates.column - 1] {neighbors.append(neighbor)}
        }
        if checkedElement.coordinates.column < checkedModel[0].count-1
        {
            if let neighbor = checkedModel[checkedElement.coordinates.row][checkedElement.coordinates.column + 1] {neighbors.append(neighbor)}
        }
        
        return neighbors
    }
}
