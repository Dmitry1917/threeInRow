//
//  TIRVIPModelElement.swift
//  ThreeInRow
//
//  Created by DMITRY SINYOV on 25.07.17.
//  Copyright © 2017 DMITRY SINYOV. All rights reserved.
//

import UIKit

class TIRVIPModelElement: NSObject {
    var elementType: TIRElementMainTypes = .elementUndefined
    var coordinates: (row: Int, column: Int) = (0, 0)
    
    func isNeighbor(checkedElement: TIRVIPModelElement) -> Bool//проверка, что ячейки являются соседями по горизонтали или вертикали
    {
        if abs(self.coordinates.row - checkedElement.coordinates.row) == 1 && self.coordinates.column == checkedElement.coordinates.column || abs(self.coordinates.column - checkedElement.coordinates.column) == 1 && self.coordinates.row == checkedElement.coordinates.row { return true }
        else { return false }
    }
}
