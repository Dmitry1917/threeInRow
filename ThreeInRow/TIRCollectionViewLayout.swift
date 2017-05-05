//
//  TIRCollectionViewLayout.swift
//  ThreeInRow
//
//  Created by DMITRY SINYOV on 04.05.17.
//  Copyright © 2017 DMITRY SINYOV. All rights reserved.
//

import UIKit

protocol TIRCollectionViewLayoutProtocol
{
    //func collectionView(collectionView:UICollectionView, sizeForObjectAtIndexPath indexPath:NSIndexPath) -> CGSize
    func collectionView(collectionView:UICollectionView, heightForItemAtIndexPath indexPath:IndexPath, withWidth:CGFloat) -> CGFloat
    func collectionView(numberOfColumnsIn collectionView:UICollectionView) -> UInt
}

class TIRCollectionViewLayout: UICollectionViewLayout
{
    var delegate: TIRCollectionViewLayoutProtocol!
    
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
        if cache.isEmpty
        {
            numberOfColumns = delegate.collectionView(numberOfColumnsIn: collectionView!)
            // 2
            let columnWidth = contentWidth / CGFloat(numberOfColumns)
            
//            let size = delegate.collectionView(collectionView: collectionView!, sizeForObjectAtIndexPath: NSIndexPath(item: 0, section: 0))
            
            var xOffset = [CGFloat]()
            for column in 0 ..< numberOfColumns
            {
                xOffset.append(CGFloat(column) * columnWidth )
            }
            var column = 0
            var yOffset = [CGFloat](repeating: 0, count: Int(numberOfColumns))
            
            // 3
            for item in 0 ..< collectionView!.numberOfItems(inSection:0)
            {
                let indexPath = IndexPath(item: item, section: 0)
                
                // 4
                //let width = columnWidth - cellPadding * 2
                //let cellContentHeight = delegate.collectionView(collectionView: collectionView!, heightForItemAtIndexPath: indexPath, withWidth: width)
                //let annotationHeight:CGFloat = 0//delegate.collectionView(collectionView!, heightForAnnotationAtIndexPath: indexPath, withWidth: width)
                let height = columnWidth//cellPadding +  cellContentHeight + annotationHeight + cellPadding
                
                
                
                let frame = CGRect(x: xOffset[column], y: yOffset[column], width: columnWidth, height: height)
                let insetFrame = frame.insetBy(dx:cellPadding, dy:cellPadding)
                
                // 5
                let attributes = TIRCollectionViewLayoutAttributes(forCellWith: indexPath)
                attributes.contentCustomHeight = CGFloat(arc4random_uniform(30))
                
                attributes.frame = insetFrame
                cache.append(attributes)
                
                // 6
                contentHeight = max(contentHeight, frame.maxY)
                yOffset[column] = yOffset[column] + height
                
                if column >= Int(numberOfColumns - 1) {column = 0}
                else {column += 1}
            }
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
}
