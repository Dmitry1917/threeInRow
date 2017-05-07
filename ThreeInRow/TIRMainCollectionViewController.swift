//
//  TIRMainCollectionViewController.swift
//  ThreeInRow
//
//  Created by DMITRY SINYOV on 04.05.17.
//  Copyright © 2017 DMITRY SINYOV. All rights reserved.
//

import UIKit

class TIRMainCollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, TIRCollectionViewLayoutProtocol {

    @IBOutlet weak var mainCollectionView: UICollectionView!
    
    fileprivate var modelArray = [[TIRModelElement]]()
    
    fileprivate let reuseIdentifier = "cellID"
    //fileprivate let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
    fileprivate let itemsPerRow: Int = 3
    fileprivate let rowsCount: Int = 4
    
    //для перетаскивания
    private var longPress:UILongPressGestureRecognizer?
    private var originalIndexPath: IndexPath? = IndexPath()//параметр был нужен для последовательного передвижения на несколько позиций от исходной за одно изменение модели данных
    private var draggingIndexPath: IndexPath? = IndexPath()
    private var draggingView: UIView?
    private var dragOffset: CGPoint = CGPoint()
    private var draggedCell: UICollectionViewCell?
    
    private var currentSwap: TIRSwapCells = TIRSwapCells()
    private var isSwapAnimatedNow: Bool = false
    private var needCleanDragging: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Register cell classes
        //self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        if let layout = mainCollectionView.collectionViewLayout as? TIRCollectionViewLayout
        {
            layout.delegate = self
        }
        
        self.mainCollectionView.delegate = self
        self.mainCollectionView.dataSource = self
        self.mainCollectionView?.register(UINib(nibName: "TIRCollectionViewCell", bundle : nil), forCellWithReuseIdentifier: reuseIdentifier)
        
//        //жесты для перетаскивания
//        let action = #selector(self.handleLongGesture(gesture:))
//        let longPressGesture = UILongPressGestureRecognizer(target: self, action: action)
//        self.mainCollectionView.addGestureRecognizer(longPressGesture)
        
        //создадим модель
        modelArray = Array(repeatElement(Array(repeatElement(TIRModelElement(), count: itemsPerRow)), count: rowsCount))
        
        for row in 0..<rowsCount
        {
            for column in 0..<itemsPerRow
            {
                //print("\(row) \(column)")
                
                let modelElement = TIRModelElement()
                
                let randomParameterRed = CGFloat(arc4random_uniform(255))
                let randomParameterGreen = CGFloat(arc4random_uniform(255))
                let randomParameterBlue = CGFloat(arc4random_uniform(255))
                modelElement.mainColor = UIColor(red: randomParameterRed / 255.0, green: randomParameterGreen / 255.0, blue: randomParameterBlue / 255.0, alpha: 1.0)
                modelElement.contentColor = UIColor.green
                
                modelArray[row][column] = modelElement
            }
        }
        
        let actionDoubleTap = #selector(self.handleDoubleTap(gesture:))
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: actionDoubleTap)
        doubleTapGesture.numberOfTapsRequired = 2
        self.mainCollectionView.addGestureRecognizer(doubleTapGesture)
        
        installGestureDraggingRecognizer()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using [segue destinationViewController].
     // Pass the selected object to the new view controller.
     }
     */
    
    // MARK: UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return itemsPerRow * rowsCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! TIRCollectionViewCell
        
        // Configure the cell
        
//        let randomParameterRed = CGFloat(arc4random_uniform(255))
//        let randomParameterGreen = CGFloat(arc4random_uniform(255))
//        let randomParameterBlue = CGFloat(arc4random_uniform(255))
//        cell.backgroundColor = UIColor(red: randomParameterRed / 255.0, green: randomParameterGreen / 255.0, blue: randomParameterBlue / 255.0, alpha: 1.0)
//        cell.someContentView.backgroundColor = UIColor.red
        
        let row = indexPath.row / itemsPerRow
        let column = indexPath.row % itemsPerRow
        let modelElement = modelArray[row][column]
        //print("\(row) \(column)")
        cell.backgroundColor = modelElement.mainColor
        cell.someContentView.backgroundColor = modelElement.contentColor
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool
    {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath)
    {
        //обновим модель
        let rowSource = sourceIndexPath.row / itemsPerRow
        let columnSource = sourceIndexPath.row % itemsPerRow
        let sourcedModelElement = modelArray[rowSource][columnSource]
        
        let rowDestination = destinationIndexPath.row / itemsPerRow
        let columnDestination = destinationIndexPath.row % itemsPerRow
        
        modelArray[rowSource][columnSource] = modelArray[rowDestination][columnDestination]
        modelArray[rowDestination][columnDestination] = sourcedModelElement
    }
    
    // MARK: UICollectionViewDelegate
    
    /*
     // Uncomment this method to specify if the specified item should be highlighted during tracking
     override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
     return true
     }
     */
    
    /*
     // Uncomment this method to specify if the specified item should be selected
     override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
     return true
     }
     */
    
    /*
     // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
     override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
     return false
     }
     
     override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
     return false
     }
     
     override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
     
     }
     */
    
    //это работает только для стандартного layout (flow) - для произвольного появляется много багов и использовать нельзя
//    func handleLongGesture(gesture: UILongPressGestureRecognizer)
//    {
//        switch gesture.state
//        {
//        case UIGestureRecognizerState.began:
//            guard let selectedIndexPath = self.mainCollectionView.indexPathForItem(at: gesture.location(in: self.mainCollectionView))
//                else
//            {
//                break;
//            }
//            self.mainCollectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
//        case UIGestureRecognizerState.changed:
//            self.mainCollectionView.updateInteractiveMovementTargetPosition(gesture.location(in: self.mainCollectionView))
//        case UIGestureRecognizerState.ended:
//            self.mainCollectionView.endInteractiveMovement()
//        default:
//            self.mainCollectionView.cancelInteractiveMovement()
//        }
//    }
    
    
    //MARK: TIRCollectionViewLayoutProtocol
//    func collectionView(collectionView: UICollectionView, sizeForObjectAtIndexPath indexPath: NSIndexPath) -> CGSize
//    {
//        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
//        let availableWidth = view.frame.width - paddingSpace
//        let widthPerItem = availableWidth / itemsPerRow
//        
//        return CGSize(width: widthPerItem, height: widthPerItem)
//    }
    
    //даже, если высоты такие, что одна ячейка как две соседних - всё равно по-умолчанию они идут последовательно слева направо по рядам, хотя визуально ряды и пересекаются (первая верхняя, вторая верхняя ... последняя верхняя, первая вторая сверху, вторая вторая сверху ... последняя вторая сверху и т.д.)
    func collectionView(collectionView:UICollectionView, heightForItemAtIndexPath indexPath:IndexPath, withWidth:CGFloat) -> CGFloat
    {
        let randParameter = CGFloat(arc4random_uniform(100))
        
        return 10 + randParameter
    }
    
    func collectionView(numberOfColumnsIn collectionView: UICollectionView) -> UInt
    {
        return UInt(itemsPerRow)
    }
    
    func handleDoubleTap(gesture: UITapGestureRecognizer)
    {
        self.mainCollectionView.reloadData()
    }
    
    
    //MARK:двигаем элементы
    func installGestureDraggingRecognizer()
    {
        if longPress == nil
        {
            let action = #selector(self.handleLongGesture(gesture:))
            longPress = UILongPressGestureRecognizer(target: self, action: action)
            longPress!.minimumPressDuration = 0.2
            mainCollectionView.addGestureRecognizer(longPress!)
        }
    }
    func handleLongGesture(gesture: UILongPressGestureRecognizer)
    {
        let location = longPress!.location(in:mainCollectionView)
        switch longPress!.state
        {
        case .began: startDragAtLocation(location:location)
        case .changed: updateDragAtLocation(location:location)
        case .ended: endDragAtLocation(location:location)
        default:
            cleanDraggingIfCan()
            break
        }
    }
    
    func startDragAtLocation(location: CGPoint)
    {
        guard let indexPath = mainCollectionView.indexPathForItem(at:location) else { return }
        guard collectionView(mainCollectionView, canMoveItemAt: indexPath) == true else { return }
        guard let cell = mainCollectionView.cellForItem(at:indexPath) else { return }
        
        originalIndexPath = indexPath
        draggingIndexPath = indexPath
        draggingView = cell.snapshotView(afterScreenUpdates:true)
        draggingView!.frame = cell.frame
        mainCollectionView.addSubview(draggingView!)
        
        dragOffset = CGPoint(x:draggingView!.center.x - location.x, y:draggingView!.center.y - location.y)
        
        //        draggingView?.layer.shadowPath = UIBezierPath(rect: draggingView!.bounds).cgPath
        //        draggingView?.layer.shadowColor = UIColor.black.cgColor
        //        draggingView?.layer.shadowOpacity = 0.8
        //        draggingView?.layer.shadowRadius = 10
        
        draggedCell = cell
        
        //invalidateLayout()
        
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
        
        //print("can move really")
        
        view.center = CGPoint(x: location.x + dragOffset.x, y: location.y + dragOffset.y)
        
        guard !isSwapAnimatedNow else { return }
        guard let newIndexPath = mainCollectionView.indexPathForItem(at:location) else { /*print("wrong new index");*/ return }
        
        guard newIndexPath != draggingIndexPath else { return }
        guard let oldIndexPath = draggingIndexPath else { return }
        
        guard canSwap(fromIndex: oldIndexPath, toIndex: newIndexPath) else { return }
        
        //старая версия - просто переставляет стандартно (элементы по порядку слеваа направо)
        //                cv.moveItem(at:draggingIndexPath!, to: newIndexPath)
        //                draggingIndexPath = newIndexPath
        
        
        self.draggingIndexPath = newIndexPath
        isSwapAnimatedNow = true
        //в принципе, можно выполнить self.draggingIndexPath = newIndexPath сразу в блоке анимаций (или перед), но это означает, что при каких-либо проблемах с ними получим некорректное состояние - поэтому лучше запоминать текущую перестановку и менять по завершении - хотя не уверен, что так лучше
        mainCollectionView.performBatchUpdates({
            self.mainCollectionView.moveItem(at: newIndexPath, to: oldIndexPath)
            self.mainCollectionView.moveItem(at: oldIndexPath, to: newIndexPath)
            
        }, completion: {(finished) in
            //self.draggingIndexPath = newIndexPath
            self.collectionView(self.mainCollectionView, moveItemAt: oldIndexPath, to: newIndexPath)
            self.originalIndexPath = newIndexPath
            
            self.isSwapAnimatedNow = false
            
            if self.needCleanDragging { self.cleanDraggingReal() }
        })
    }
    func endDragAtLocation(location: CGPoint)
    {
        
        guard let dragView = draggingView else { return }
        guard let indexPath = draggingIndexPath else { return }
        
        let targetCenter = collectionView(mainCollectionView, cellForItemAt: indexPath).center
        
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
            //self.invalidateLayout()
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
    
    func canSwap(fromIndex: IndexPath, toIndex: IndexPath) -> Bool
    {
        let fromRow = fromIndex.row / itemsPerRow
        let fromColumn = fromIndex.row % itemsPerRow
        let toRow = toIndex.row / itemsPerRow
        let toColumn = toIndex.row % itemsPerRow
        
        //print("\(fromRow) \(fromColumn) \(toRow) \(toColumn) \(NSDate())")
        
        if abs(fromRow - toRow) < 2 && fromColumn == toColumn || abs(fromColumn - toColumn) < 2 && fromRow == toRow { return true }
        else { return false }
    }
}

/*
//все эти методы можно перенести прямо в класс выше, если указать, что он соответствует этому делегату - проверил
extension TIRMainCollectionViewController : UICollectionViewDelegateFlowLayout
{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets
    {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat
    {
        return sectionInsets.left
    }
}
*/
