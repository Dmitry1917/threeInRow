//
//  TIRCollectionViewLayoutAttributes.swift
//  ThreeInRow
//
//  Created by DMITRY SINYOV on 05.05.17.
//  Copyright © 2017 DMITRY SINYOV. All rights reserved.
//

import UIKit

class TIRCollectionViewLayoutAttributes: UICollectionViewLayoutAttributes
{
    var contentCustomHeight: CGFloat = 0.0
    
    //эти два метода нужно реализовать для корректной работы (что вполне логично)
    override func copy(with zone: NSZone? = nil) -> Any
    {
        let copy = super.copy(with: zone) as! TIRCollectionViewLayoutAttributes
        copy.contentCustomHeight = contentCustomHeight
        return copy
    }
    
    override func isEqual(_ object: Any?) -> Bool
    {
        if let attributes = object as? TIRCollectionViewLayoutAttributes
        {
            if attributes.contentCustomHeight == contentCustomHeight
            {
                return super.isEqual(object)
            }
        }
        return false
    }
}
