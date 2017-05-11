//
//  TIRRealTIRCollectionViewLayout.swift
//  ThreeInRow
//
//  Created by DMITRY SINYOV on 11.05.17.
//  Copyright © 2017 DMITRY SINYOV. All rights reserved.
//

import UIKit

protocol TIRRealTIRCollectionViewLayoutProtocol: class
{
    func collectionView(numberOfColumnsIn collectionView:UICollectionView) -> UInt
    func collectionView(heightForCustomContentIn collectionView:UICollectionView, indexPath:IndexPath) -> CGFloat
}

class TIRRealTIRCollectionViewLayout: UICollectionViewLayout
{
    weak var delegate: TIRRealTIRCollectionViewLayoutProtocol?
    
    private var cache = [TIRCollectionViewLayoutAttributes]()
    var numberOfColumns: UInt = 3
    var cellPadding: CGFloat = 20.0
    
    private var contentHeight: CGFloat = 0.0
    private var contentWidth: CGFloat {
        let insets = collectionView!.contentInset
        return collectionView!.bounds.width - (insets.left + insets.right)
    }
    override class var layoutAttributesClass: AnyClass
    {
        return TIRCollectionViewLayoutAttributes.self
    }
    
    override func prepare()
    {
        super.prepare()
        
        guard delegate != nil else { return }
        
        let newNumberOfColumns = delegate!.collectionView(numberOfColumnsIn: collectionView!)
        
        cache.removeAll()
        
        numberOfColumns = newNumberOfColumns
        
        let columnWidth = contentWidth / CGFloat(numberOfColumns)
        
        var xOffset = [CGFloat]()
        for column in 0 ..< numberOfColumns
        {
            xOffset.append(CGFloat(column) * columnWidth )
        }
        var column = 0
        var yOffset = [CGFloat](repeating: 0, count: Int(numberOfColumns))
        
        for item in 0 ..< collectionView!.numberOfItems(inSection:0)
        {
            let indexPath = IndexPath(item: item, section: 0)
            
            let height = columnWidth
            
            let frame = CGRect(x: xOffset[column], y: yOffset[column], width: columnWidth, height: height)
            let insetFrame = frame.insetBy(dx:cellPadding, dy:cellPadding)
            
            let attributes = TIRCollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.contentCustomHeight = delegate!.collectionView(heightForCustomContentIn: collectionView!, indexPath: indexPath)
            
            attributes.frame = insetFrame
            cache.append(attributes)
            
            contentHeight = max(contentHeight, frame.maxY)
            yOffset[column] = yOffset[column] + height
            
            if column >= Int(numberOfColumns - 1) {column = 0}
            else {column += 1}
        }
        
    }
    
    override var collectionViewContentSize: CGSize
    {
        return CGSize(width: contentWidth, height: contentHeight)
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]?
    {
        var layoutAttributes = [UICollectionViewLayoutAttributes]()
        
        for attributes in cache
        {
            if attributes.frame.intersects(rect)
            {
                layoutAttributes.append(attributes)
            }
        }
        
        return layoutAttributes
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes?
    {
        return cache[indexPath.row]
    }
}
