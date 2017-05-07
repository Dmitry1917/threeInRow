//
//  TIRCollectionViewLayout.swift
//  ThreeInRow
//
//  Created by DMITRY SINYOV on 04.05.17.
//  Copyright © 2017 DMITRY SINYOV. All rights reserved.
//

import UIKit

class TIRSwapCells: NSObject
{
    var originalIndexPath: IndexPath?
    var newIndexPath: IndexPath?
}

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
    
    private var longPress:UILongPressGestureRecognizer?
    private var originalIndexPath: IndexPath? = IndexPath()//параметр был нужен для последовательного передвижения на несколько позиций от исходной за одно изменение модели данных
    private var draggingIndexPath: IndexPath? = IndexPath()
    private var draggingView: UIView?
    private var dragOffset: CGPoint = CGPoint()
    private var draggedCell: UICollectionViewCell?
    
    private var currentSwap: TIRSwapCells = TIRSwapCells()
    private var isSwapAnimatedNow: Bool = false
    private var needCleanDragging: Bool = false
    
    override class var layoutAttributesClass: AnyClass
    {
        return TIRCollectionViewLayoutAttributes.self
    }
    
    override func prepare()
    {
        super.prepare()
        
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
                attributes.contentCustomHeight = 0.0//CGFloat(arc4random_uniform(30))
                
                attributes.frame = insetFrame
                cache.append(attributes)
                
                // 6
                contentHeight = max(contentHeight, frame.maxY)
                yOffset[column] = yOffset[column] + height
                
                if column >= Int(numberOfColumns - 1) {column = 0}
                else {column += 1}
            }
        }
        
        installGestureRecognizer()
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
    
    //пока нерабочий вариант
//    override func invalidationContext(forInteractivelyMovingItems targetIndexPaths: [IndexPath], withTargetPosition targetPosition: CGPoint, previousIndexPaths: [IndexPath], previousPosition: CGPoint) -> UICollectionViewLayoutInvalidationContext
//    {
//        let context = super.invalidationContext(forInteractivelyMovingItems: targetIndexPaths, withTargetPosition: targetPosition, previousIndexPaths: previousIndexPaths, previousPosition: previousPosition)
//        
//        self.collectionView?.moveItem(at: previousIndexPaths[0], to: targetIndexPaths[0])
//        
//        return context
//    }
    
    //MARK:двигаем элементы
    func installGestureRecognizer()
    {
        if longPress == nil
        {
            let action = #selector(self.handleLongGesture(gesture:))
            longPress = UILongPressGestureRecognizer(target: self, action: action)
            longPress!.minimumPressDuration = 0.2
            collectionView?.addGestureRecognizer(longPress!)
        }
    }
    func handleLongGesture(gesture: UILongPressGestureRecognizer)
    {
        let location = longPress!.location(in:collectionView!)
        switch longPress!.state
        {
            case .began: startDragAtLocation(location:location)
            case .changed: updateDragAtLocation(location:location)
            case .ended: endDragAtLocation(location:location)
            default:
                break
        }
    }
    
    func startDragAtLocation(location: CGPoint)
    {
        guard let cv = self.collectionView else { return }
        guard let indexPath = cv.indexPathForItem(at:location) else { return }
        guard cv.dataSource?.collectionView?(cv, canMoveItemAt: indexPath) == true else { return }
        guard let cell = cv.cellForItem(at:indexPath) else { return }
        
        originalIndexPath = indexPath
        draggingIndexPath = indexPath
        draggingView = cell.snapshotView(afterScreenUpdates:true)
        draggingView!.frame = cell.frame
        cv.addSubview(draggingView!)
        
        dragOffset = CGPoint(x:draggingView!.center.x - location.x, y:draggingView!.center.y - location.y)
        
//        draggingView?.layer.shadowPath = UIBezierPath(rect: draggingView!.bounds).cgPath
//        draggingView?.layer.shadowColor = UIColor.black.cgColor
//        draggingView?.layer.shadowOpacity = 0.8
//        draggingView?.layer.shadowRadius = 10
        
        draggedCell = cell
        
        invalidateLayout()
        
        UIView.animate(withDuration:0.4, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0, options: [], animations: {
            self.draggingView?.alpha = 0.95
            self.draggingView?.transform = CGAffineTransform.init(scaleX: 1.2, y: 1.2)
        }, completion: { (completed) in
            
            self.draggedCell?.isHidden = true
        })
    }
    func updateDragAtLocation(location: CGPoint)
    {
        guard let view = draggingView else { return }
        guard let cv = collectionView else { return }
        
        view.center = CGPoint(x: location.x + dragOffset.x, y: location.y + dragOffset.y)
        
        guard !isSwapAnimatedNow else { return }
        guard let newIndexPath = cv.indexPathForItem(at:location) else { return }
        
        guard newIndexPath != draggingIndexPath else { return }
        guard let oldIndexPath = draggingIndexPath else { return }
        
        //старая версия - просто переставляет стандартно (элементы по порядку слеваа направо)
        //                cv.moveItem(at:draggingIndexPath!, to: newIndexPath)
        //                draggingIndexPath = newIndexPath
        
        
        self.draggingIndexPath = newIndexPath
        isSwapAnimatedNow = true
        //в принципе, можно выполнить self.draggingIndexPath = newIndexPath сразу в блоке анимаций (или перед), но это означает, что при каких-либо проблемах с ними получим некорректное состояние - поэтому лучше запоминать текущую перестановку и менять по завершении - хотя не уверен, что так лучше
        cv.performBatchUpdates({
            cv.moveItem(at: newIndexPath, to: oldIndexPath)
            cv.moveItem(at: oldIndexPath, to: newIndexPath)
            
        }, completion: {(finished) in
            //self.draggingIndexPath = newIndexPath
            cv.dataSource?.collectionView?(cv, moveItemAt: oldIndexPath, to: newIndexPath)
            self.originalIndexPath = newIndexPath
            
            self.isSwapAnimatedNow = false
            
            if self.needCleanDragging { self.cleanDraggingReal() }
        })
    }
    func endDragAtLocation(location: CGPoint)
    {
        
        guard let dragView = draggingView else { return }
        guard let indexPath = draggingIndexPath else { return }
        guard let cv = collectionView else { return }
        guard let datasource = cv.dataSource else { return }
        
        let targetCenter = datasource.collectionView(cv, cellForItemAt: indexPath).center
        
//        let shadowFade = CABasicAnimation(keyPath: "shadowOpacity")
//        shadowFade.fromValue = 0.8
//        shadowFade.toValue = 0
//        shadowFade.duration = 0.4
//        dragView.layer.add(shadowFade, forKey: "shadowFade")
        
        UIView.animate(withDuration:0.4, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: [], animations: {
            dragView.center = targetCenter
            dragView.transform = CGAffineTransform.identity
            
        }) { (completed) in
            
//            if !(indexPath == self.originalIndexPath!)
//            {
//                datasource.collectionView?(cv, moveItemAt: self.originalIndexPath!, to: indexPath)
//            }
            
            self.cleanDraggingIfCan()
            self.invalidateLayout()
        }
        
        //cleanDraggingIfCan()
    }
    
    func cleanDraggingIfCan()
    {
        if isSwapAnimatedNow
        {//сейчас идёт анимация
            needCleanDragging = true
        }
        else
        {
            cleanDraggingReal()
        }
    }
    
    func cleanDraggingReal()
    {
        self.draggedCell?.isHidden = false
        draggingView?.removeFromSuperview()
        self.draggingIndexPath = nil
        self.draggingView = nil
    }
}
