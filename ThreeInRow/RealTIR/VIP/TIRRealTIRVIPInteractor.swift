//
//  TIRRealTIRModel.swift
//  ThreeInRow
//
//  Created by DMITRY SINYOV on 12.06.17.
//  Copyright © 2017 DMITRY SINYOV. All rights reserved.
//

import UIKit

protocol TIRRealTIRVIPInteractorProtocol
{
    var itemsPerRow: Int { get }
    var rowsCount: Int { get }
    
    func setupModel()
    func examplesAllTypes() -> [TIRRealTIRModelElement]
    func findChains() -> [[TIRRealTIRModelElement]]
    func removeChains(chains: [[TIRRealTIRModelElement]])
    func useGravityOnField() -> (oldCoords: [TIRRowColumn], newCoords: [TIRRowColumn])
    func refillFieldByColumns() -> [[TIRRealTIRModelElement]]
    func canTrySwap(fromCoord: TIRRowColumn, toCoord: TIRRowColumn) -> Bool
    func canSwap(fromCoord: TIRRowColumn, toCoord: TIRRowColumn) -> Bool
    func elementByCoord(coord: TIRRowColumn) -> TIRRealTIRModelElement?
    func swapElementsByCoords(firstCoord: TIRRowColumn, secondCoord: TIRRowColumn)
    
    func askField()
}

class TIRRealTIRVIPInteractor: NSObject, TIRRealTIRVIPInteractorProtocol
{
    var presenter: TIRRealTIRVIPPresenterProtocol!
    
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
        
        //простой вариант изначальной очистки поля от троек - применяем обычные удаления троек и добавление случайных ячеек, пока поле не будет безтроечным (уходит несколько шагов, но на практике немного, так что способ допустимый)
        
        //var counter = 0
        var chains = findChains()
        while chains.count > 0
        {
//            counter += 1
//            print(counter)
            removeChains(chains: chains)
            _ = refillFieldByColumns()//таким образом показываем, что возвращаемый результат не требуется, чтобы компилятор не ругался, альтернатива - @discardableResult перед функцией
            chains = findChains()
        }
    }
    
    func askField() {
        presenter.prepareFieldPresentation(field: modelArray)
    }
    
    func examplesAllTypes() -> [TIRRealTIRModelElement]
    {
        var examples = [TIRRealTIRModelElement]()
        
        for elementType in TIRElementMainTypes.allReal()
        {
            var found = false
            for row in 0..<rowsCount
            {
                for column in 0..<itemsPerRow
                {
                    let element = modelArray[row][column]
                    if element.elementType == elementType
                    {
                        examples.append(element)
                        found = true
                        break
                    }
                }
                if found { break }
            }
        }
        
        return examples
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
    
    func canTrySwap(fromCoord: TIRRowColumn, toCoord: TIRRowColumn) -> Bool
    {
        return fromCoord.isNeighbor(checkedCoord: toCoord)
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
    func findChains() -> [[TIRRealTIRModelElement]]
    {
        var realChains = [[TIRRealTIRModelElement]]()
        let potentialChains = findChainsMoreThan2()
        
        //уберём элементы цепей, не входящие в тройки - оставшиеся можно рассматривать, как удаляемые участки
        
        for chain in potentialChains
        {
            let threesOnlyChain = chainWithThreesOnly(chainArray: chain)
            if threesOnlyChain.count > 0
            {
                realChains.append(threesOnlyChain)
            }
        }
        
        return realChains
    }
    func chainWithThreesOnly(chainArray: [TIRRealTIRModelElement]) -> [TIRRealTIRModelElement]
    {
        //пройдёмся по всем ячейкам и попытаемся найти в цепочке её двух соседей в одном направлении, если есть - оставляем, иначе убираем
        
        //сделаем массив координат
        var coordArrayOriginal: [TIRRowColumn] = []
        for modelElement in chainArray
        {
            coordArrayOriginal.append(modelElement.coordinates)
        }
        
        let coordArray = coordArrayOriginal
        //пройдёмся по массиву координат в поисках троек
        for coordFirst in coordArray
        {
            var threeFounded = false
            for coordSecond in coordArray
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
                        
                        if coordArray.contains(seekCoordMin) || coordArray.contains(seekCoordMax) { threeFounded = true }//нашли тройку - проверка удачна
                    }
                    else//на одной вертикали
                    {
                        let minRow = min(coordFirst.row, coordSecond.row) - 1
                        let maxRow = max(coordFirst.row, coordSecond.row) + 1
                        
                        let seekCoordMin = TIRRowColumn(row: minRow, column: coordFirst.column)
                        let seekCoordMax = TIRRowColumn(row: maxRow, column: coordFirst.column)
                        
                        if coordArray.contains(seekCoordMin) || coordArray.contains(seekCoordMax) { threeFounded = true }//нашли тройку - проверка удачна
                    }
                    
                }
            }
            
            if !threeFounded
            {
                if let removingIndex = coordArrayOriginal.index(of: coordFirst)
                {
                    coordArrayOriginal.remove(at: removingIndex)
                }
            }
        }
        
        //оставим только элементы троек в цепочке
        var chainArrayMutableCopy = chainArray
        for modelElement in chainArray
        {
            if !coordArrayOriginal.contains(modelElement.coordinates) { chainArrayMutableCopy.remove(at: chainArrayMutableCopy.index(of: modelElement)!) }
        }
        
        return chainArrayMutableCopy
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
    
    
    //удаление цепочек
    func removeChains(chains: [[TIRRealTIRModelElement]])
    {
        for chain in chains
        {
            for element in chain
            {
                modelArray[element.coordinates.row][element.coordinates.column].elementType = TIRElementMainTypes.elementUndefined
            }
        }
    }
    func useGravityOnField() -> (oldCoords: [TIRRowColumn], newCoords: [TIRRowColumn])//сдвинем ячейки, которые требуется и вернём координаты старые и новые
    {
        var oldCoords = [TIRRowColumn]()
        var newCoords = [TIRRowColumn]()
        
        //пройдёмся по столбцам и найдём пустые ячейки под каждой реальной - сколько их, такой и сдвиг вниз
        //пока просто в лоб без оптимизаций
        for column in 0..<itemsPerRow
        {
            //просматриваем снизу вверх, чтобы сразу корректно заменить на новое значение, ничего не перепутав
            for row in (0..<rowsCount-1).reversed()//нижний ряд не берём, так как оттуда некуда падать
            {
                let element = modelArray[row][column]
                
                guard element.elementType != TIRElementMainTypes.elementUndefined else { continue }//элемент не пустой
                
                //посчитаем пустые ячейки ниже проверяемой - их количество и будет сдвигом
                var emptyElementsUnderCurrent = 0
                for rowDown in row+1..<rowsCount
                {
                    let elementDown = modelArray[rowDown][column]
                    
                    if elementDown.elementType == TIRElementMainTypes.elementUndefined { emptyElementsUnderCurrent += 1 }
                }
                
                guard emptyElementsUnderCurrent > 0 else { continue }
                
                oldCoords.append(TIRRowColumn(row: row, column: column))
                newCoords.append(TIRRowColumn(row: row + emptyElementsUnderCurrent, column: column))
                
                //в новые координаты можно сразу записать значение, так как туда ничего точно не попадёт, в отличие от старых, куда может сдвинуться другая ячейка сверху
                //получается своеобразная сортировка пузырьком - идём снизу и сдвигаем вниз на пустые места ячейки, а сами пустые продвигаются вверх, что и требовалось
                modelArray[row+emptyElementsUnderCurrent][column].elementType = modelArray[row][column].elementType
                modelArray[row][column].elementType = TIRElementMainTypes.elementUndefined
            }
        }
        
        return (oldCoords, newCoords)
    }
    
    func refillFieldByColumns() -> [[TIRRealTIRModelElement]]//заполним пустые места и вернём список заполненных столбцов
    {
        var columnsFilled = [[TIRRealTIRModelElement]]()
        for column in 0..<itemsPerRow
        {
            var elementsFilled = [TIRRealTIRModelElement]()
            for row in 0..<rowsCount
            {
                let element = modelArray[row][column]
                if element.elementType == TIRElementMainTypes.elementUndefined
                {
                    element.elementType = TIRElementMainTypes.randomType()
                    elementsFilled.append(element)
                }
            }
            
            if elementsFilled.count > 0 { columnsFilled.append(elementsFilled) }
        }
        
        return columnsFilled
    }
}
