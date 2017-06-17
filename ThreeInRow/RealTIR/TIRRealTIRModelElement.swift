//
//  TIRRealTIRModelElement.swift
//  ThreeInRow
//
//  Created by DMITRY SINYOV on 12.05.17.
//  Copyright © 2017 DMITRY SINYOV. All rights reserved.
//

import UIKit

class TIRRowColumn: NSObject
{
    var row: Int = 0
    var column: Int = 0
    
    init(row: Int, column: Int)
    {
        self.row = row
        self.column = column
    }
    
    func isNeighbor(checkedCoord: TIRRowColumn) -> Bool//проверка, что ячейки являются соседями по горизонтали или вертикали
    {
        if abs(self.row - checkedCoord.row) < 2 && self.column == checkedCoord.column || abs(self.column - checkedCoord.column) < 2 && self.row == checkedCoord.row { return true }
        else { return false }
    }
    
    override func isEqual(_ object: Any?) -> Bool
    {
        if let coord = object as? TIRRowColumn
        {
            if row == coord.row && column == coord.column
            {
                return true
            }
        }
        return false
    }
}

enum TIRElementMainTypes
{
    case elementUndefined
    case elementRed
    case elementGreen
    case elementBlue
    case elementYellow
    case elementOrange
    case elementPurple
    
    static func randomType() -> TIRElementMainTypes
    {
        let allTypes: [TIRElementMainTypes] = [.elementRed, .elementGreen, .elementBlue, .elementYellow, .elementOrange, .elementPurple]
        let index = Int(arc4random_uniform(UInt32(allTypes.count)))
        return allTypes[index]
    }
}

class TIRRealTIRModelElement: NSObject
{
    var elementType: TIRElementMainTypes = .elementUndefined
    var coordinates: TIRRowColumn = TIRRowColumn(row: 0, column: 0)
}
