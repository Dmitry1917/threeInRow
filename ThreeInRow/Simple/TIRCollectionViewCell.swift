//
//  TIRCollectionViewCell.swift
//  ThreeInRow
//
//  Created by DMITRY SINYOV on 04.05.17.
//  Copyright © 2017 DMITRY SINYOV. All rights reserved.
//

import UIKit

class TIRCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var someContentView: UIView!
    @IBOutlet weak var contentHeightConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes)
    {
        super.apply(layoutAttributes)
        
        if let attributes = layoutAttributes as? TIRCollectionViewLayoutAttributes
        {
            contentHeightConstraint.constant = attributes.contentCustomHeight
        }
        
        if let circularlayoutAttributes = layoutAttributes as? TIRCircularCollectionViewLayoutAttributes
        {
            self.layer.anchorPoint = circularlayoutAttributes.anchorPoint
            self.center.y += (circularlayoutAttributes.anchorPoint.y - 0.5) * self.bounds.height
            contentHeightConstraint.constant = circularlayoutAttributes.customContentHeight == nil ? 0 : circularlayoutAttributes.customContentHeight!
        }
    }
}
