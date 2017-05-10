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
    var customContentHeight: CGFloat? = 0.0
    override func copy(with zone: NSZone? = nil) -> Any
    {
        let copiedAttributes = super.copy(with: zone) as! TIRCircularCollectionViewLayoutAttributes
        copiedAttributes.anchorPoint = self.anchorPoint
        copiedAttributes.angle = self.angle
        copiedAttributes.customContentHeight = self.customContentHeight
        return copiedAttributes
    }
}

protocol TIRCircularCollectionViewLayoutProtocol: class
{
    func collectionView(heightForCustomContentIn collectionView:UICollectionView, indexPath:IndexPath) -> CGFloat
}

class TIRCircularCollectionViewLayout: UICollectionViewLayout
{
    weak var delegate: TIRCircularCollectionViewLayoutProtocol?
    
    var attributesList = [TIRCircularCollectionViewLayoutAttributes]()
    let itemSize = CGSize(width: 133, height: 173)
    
    var angleAtExtreme: CGFloat
    {
        return collectionView!.numberOfItems(inSection: 0) > 0 ?
            -CGFloat(collectionView!.numberOfItems(inSection: 0) - 1) * anglePerItem : 0
    }
    var angle: CGFloat
    {
        return angleAtExtreme * collectionView!.contentOffset.x / (collectionViewContentSize.width -
            collectionView!.bounds.width)
    }
    
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
        
        //print("prepare circular layout \(NSDate())")
        
        let centerX = collectionView!.contentOffset.x + collectionView!.bounds.width / 2.0
        let anchorPointY = ((itemSize.height / 2.0) + radius) / itemSize.height
        
        //ниже блок оптимизаций, позволяющий не высчитывать параметры для объектов за пределами зоны видимости
        let theta = atan2(collectionView!.bounds.width / 2.0, radius + (itemSize.height / 2.0) - (collectionView!.bounds.height / 2.0))
        var startIndex = 0
        var endIndex = collectionView!.numberOfItems(inSection: 0) - 1
        
        if (angle < -theta)
        {
            startIndex = Int(floor((-theta - angle) / anglePerItem))
        }
        
        endIndex = min(endIndex, Int(ceil((theta - angle) / anglePerItem)))
        
        if (endIndex < startIndex)
        {
            endIndex = 0
            startIndex = 0
        }
        
        attributesList = (startIndex...endIndex).map
        { (i) -> TIRCircularCollectionViewLayoutAttributes in
            
            let attributes = TIRCircularCollectionViewLayoutAttributes(forCellWith: IndexPath(item: i, section: 0))
            attributes.size = self.itemSize
            
            attributes.center = CGPoint(x: centerX, y: self.collectionView!.bounds.midY)
            
            attributes.angle = self.angle + (self.anglePerItem * CGFloat(i))
            attributes.anchorPoint = CGPoint(x: 0.5, y: anchorPointY)
            
            attributes.customContentHeight = delegate?.collectionView(heightForCustomContentIn: collectionView!, indexPath: IndexPath(item: i, section: 0))
            
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
    
    override func shouldInvalidateLayout(forBoundsChange: CGRect) -> Bool
    {
        return true
    }
}
