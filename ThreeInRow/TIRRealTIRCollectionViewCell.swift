//
//  TIRRealTIRCollectionViewCell.swift
//  ThreeInRow
//
//  Created by DMITRY SINYOV on 12.05.17.
//  Copyright © 2017 DMITRY SINYOV. All rights reserved.
//

import UIKit

class TIRRealTIRCollectionViewCell: UICollectionViewCell
{

    @IBOutlet weak private var mainContentView: UIView!
    @IBOutlet weak private var someContentView: UIView!
    @IBOutlet weak private var contentHeightConstraint: NSLayoutConstraint!
    
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
    
    func setMainColor(mainColor: UIColor)
    {
        mainContentView.backgroundColor = mainColor
    }
    func setContentColor(contentColor: UIColor)
    {
        someContentView.backgroundColor = contentColor
    }
    func setContentHeightConstraint(newConstant: CGFloat)
    {
        contentHeightConstraint.constant = newConstant
    }
    
    func showBorder()
    {
        self.layer.borderColor = UIColor.red.cgColor
        self.layer.borderWidth = 2.0
    }
    func hideBorder()
    {
        self.layer.borderColor = UIColor.clear.cgColor
        self.layer.borderWidth = 0.0
    }

}
