//
//  TIRVIPERModelElement.swift
//  ThreeInRow
//
//  Created by DMITRY SINYOV on 21.08.17.
//  Copyright © 2017 DMITRY SINYOV. All rights reserved.
//

import UIKit

class TIRVIPERModelElement: NSObject
{
    var elementType: TIRElementMainTypes = .elementUndefined
    var coordinates: TIRRowColumn = TIRRowColumn(row: 0, column: 0)
}
