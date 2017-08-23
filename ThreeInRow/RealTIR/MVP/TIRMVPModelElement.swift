//
//  TIRMVPModelElement.swift
//  ThreeInRow
//
//  Created by DMITRY SINYOV on 12.05.17.
//  Copyright © 2017 DMITRY SINYOV. All rights reserved.
//

import UIKit

class TIRMVPModelElement: NSObject
{
    var elementType: TIRElementMainTypes = .elementUndefined
    var coordinates: TIRRowColumn = TIRRowColumn(row: 0, column: 0)
}
