//
//  TIRCircularCollectionViewLayout.swift
//  ThreeInRow
//
//  Created by DMITRY SINYOV on 10.05.17.
//  Copyright © 2017 DMITRY SINYOV. All rights reserved.
//

import UIKit

class TIRCircularCollectionViewLayoutAttributes: UICollectionViewLayoutAttributes
{
    var anchorPoint = CGPoint(x: 0.5, y: 0.5)
    var angle: CGFloat = 0
    {
        didSet
        {
            zIndex = Int(angle * 1000000)
            transform = CGAffineTransform(rotationAngle: angle)
        }
    }
    override func copy(with zone: NSZone? = nil) -> Any
    {
        let copiedAttributes = super.copy(with: zone) as! TIRCircularCollectionViewLayoutAttributes
        copiedAttributes.anchorPoint = self.anchorPoint
        copiedAttributes.angle = self.angle
        return copiedAttributes
    }
}

class TIRCircularCollectionViewLayout: UICollectionViewLayout
{
    var attributesList = [TIRCircularCollectionViewLayoutAttributes]()
    let itemSize = CGSize(width: 133, height: 173)
    
    var radius:CGFloat = 500
    {
        didSet
        {
            invalidateLayout()
        }
    }
    
    var anglePerItem: CGFloat
    {
        return atan(itemSize.width / radius)
    }
    
    override class var layoutAttributesClass: AnyClass
    {
        return TIRCircularCollectionViewLayoutAttributes.self
    }
    
    override var collectionViewContentSize: CGSize
    {
        return CGSize(width: CGFloat(collectionView!.numberOfItems(inSection: 0)) * itemSize.width, height: collectionView!.bounds.height)
    }
    
    override func prepare()
    {
        super.prepare()
        
        let centerX = collectionView!.contentOffset.x + collectionView!.bounds.width / 2.0
        attributesList = (0..<collectionView!.numberOfItems(inSection: 0)).map
            { (i) -> TIRCircularCollectionViewLayoutAttributes in
            
            let attributes = TIRCircularCollectionViewLayoutAttributes(forCellWith: IndexPath(item: i, section: 0))
            attributes.size = self.itemSize
            
            attributes.center = CGPoint(x: centerX, y: self.collectionView!.bounds.midY)
            
            attributes.angle = self.anglePerItem * CGFloat(i)
            return attributes
        }
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]?
    {
        return attributesList
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes?
    {
        return attributesList[indexPath.row]
    }
}
