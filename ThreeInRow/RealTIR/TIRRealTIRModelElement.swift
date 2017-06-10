//
//  TIRRealTIRModelElement.swift
//  ThreeInRow
//
//  Created by DMITRY SINYOV on 12.05.17.
//  Copyright © 2017 DMITRY SINYOV. All rights reserved.
//

import UIKit

enum TIRElementMainTypes
{
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
    var elementType: TIRElementMainTypes = .elementRed
    var coordinates: TIRRowColumn = TIRRowColumn(row: 0, column: 0)
}
