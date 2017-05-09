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
    private var originalIndexPath: IndexPath?//параметр был нужен для последовательного передвижения на несколько позиций от исходной за одно изменение модели данных
    private var draggingIndexPath: IndexPath?
    private var justReleasedIndexPath: IndexPath?
    private var draggingView: UIView?
    private var dragOffset: CGPoint = CGPoint()
    private var draggingCell: UICollectionViewCell?
    
    private var currentSwap: TIRSwapCells = TIRSwapCells()
    private var isSwapAnimatedNow: Bool = false
    //private var isReleaseCellAnimatedNow: Bool = false
    private var needCleanDragging: Bool = false
    
    private var animationCounter: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        if let layout = mainCollectionView.collectionViewLayout as? TIRCollectionViewLayout
        {
            layout.delegate = self
        }
        
        self.mainCollectionView.delegate = self
        self.mainCollectionView.dataSource = self
        self.mainCollectionView?.register(UINib(nibName: "TIRCollectionViewCell", bundle : nil), forCellWithReuseIdentifier: reuseIdentifier)
        
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
                modelElement.customContentHeight = CGFloat(arc4random_uniform(30))
                
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
    
    func collectionView(heightForCustomContentIn collectionView:UICollectionView, indexPath:IndexPath) -> CGFloat
    {
        let row = indexPath.row / itemsPerRow
        let column = indexPath.row % itemsPerRow
        
        return (modelArray[row][column]).customContentHeight
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
            cleanDraggingIfCan(lastDraggingView: draggingView, lastDraggingCell: draggingCell, lastDraggingIndexPath: draggingIndexPath, lastJustReleasedIndexPath: justReleasedIndexPath)
            break
        }
    }
    
    func startDragAtLocation(location: CGPoint)
    {
        //guard !isReleaseCellAnimatedNow else { return }
        guard let indexPath = mainCollectionView.indexPathForItem(at:location) else { return }
        guard indexPath != justReleasedIndexPath else { return }//чтобы не хватать только что отпущенную, анимируемую ячейку
        guard collectionView(mainCollectionView, canMoveItemAt: indexPath) == true else { return }
        guard let cell = mainCollectionView.cellForItem(at:indexPath) else { return }
        
        originalIndexPath = indexPath
        draggingIndexPath = indexPath
        draggingView = cell.snapshotView(afterScreenUpdates:true)
        draggingView!.frame = cell.frame
        mainCollectionView.addSubview(draggingView!)
        
        dragOffset = CGPoint(x:draggingView!.center.x - location.x, y:draggingView!.center.y - location.y)
        
        draggingView?.layer.shadowPath = UIBezierPath(rect: draggingView!.bounds).cgPath
        draggingView?.layer.shadowColor = UIColor.black.cgColor
        draggingView?.layer.shadowOpacity = 0.8
        draggingView?.layer.shadowRadius = 10
        
        draggingCell = cell
        
        self.draggingCell?.isHidden = true
        
        UIView.animate(withDuration:0.4, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0, options: [], animations: {
            self.draggingView?.alpha = 0.95
            self.draggingView?.transform = CGAffineTransform.init(scaleX: 1.2, y: 1.2)
        }, completion: { (completed) in
            
        })
    }
    func updateDragAtLocation(location: CGPoint)
    {
        //guard !isReleaseCellAnimatedNow else { return }
        guard draggingIndexPath != justReleasedIndexPath else { return }//чтобы не двигать только что отпущенную, анимируемую ячейку
        guard let view = draggingView else { return }
        
        //print("can move really")
        
        view.center = CGPoint(x: location.x + dragOffset.x, y: location.y + dragOffset.y)
        
        guard !isSwapAnimatedNow else { return }
        guard let newIndexPath = mainCollectionView.indexPathForItem(at:location) else { /*print("wrong new index");*/ return }
        
        guard newIndexPath != draggingIndexPath else { return }
        guard let oldIndexPath = draggingIndexPath else { return }
        
        guard canSwap(fromIndex: oldIndexPath, toIndex: newIndexPath) else { return }
        
        //старая версия - просто переставляет стандартно (элементы по порядку слева направо)
        //                cv.moveItem(at:draggingIndexPath!, to: newIndexPath)
        //                draggingIndexPath = newIndexPath
        
        
        self.draggingIndexPath = newIndexPath
        isSwapAnimatedNow = true
        
        self.collectionView(self.mainCollectionView, moveItemAt: oldIndexPath, to: newIndexPath)//обновляем модель тут - до успешной анимации, чтобы параметры из модели корректно применились к атрибутам layout
        //в принципе, можно выполнить self.draggingIndexPath = newIndexPath сразу в блоке анимаций (или перед), но это означает, что при каких-либо проблемах с ними получим некорректное состояние - поэтому лучше запоминать текущую перестановку и менять по завершении - хотя не уверен, что так лучше
        
//        let lastDraggingView = draggingView
//        let lastDraggingCell = draggingCell
//        let lastDraggingIndexPath = draggingIndexPath
//        let lastJustReleasedIndexPath = justReleasedIndexPath
        mainCollectionView.performBatchUpdates({
            self.mainCollectionView.moveItem(at: newIndexPath, to: oldIndexPath)
            self.mainCollectionView.moveItem(at: oldIndexPath, to: newIndexPath)
            
        }, completion: {(finished) in
            self.originalIndexPath = newIndexPath
            
            self.isSwapAnimatedNow = false
            
            //if self.needCleanDragging { self.cleanDraggingReal(lastDraggingView: lastDraggingView, lastDraggingCell: lastDraggingCell, lastDraggingIndexPath: lastDraggingIndexPath, lastJustReleasedIndexPath: lastJustReleasedIndexPath) }
        })
    }
    func endDragAtLocation(location: CGPoint)
    {
        //guard !isReleaseCellAnimatedNow else { return }
        guard let dragView = draggingView else { return }
        guard let indexPath = draggingIndexPath else { return }
        //guard indexPath != justReleasedIndexPath else { return }//чтобы не обрабатывать только что отпущенную, анимируемую ячейку снова
        
        let targetCenter = collectionView(mainCollectionView, cellForItemAt: indexPath).center
        
        //анимация исчезновения настоящей тени и движения ячейки одновременно приводит к мельканию тени в конце анимации - нужно проанимировать одним способом и движение и тень, а не пересекая CAAnimation и UIView.animate
        //на самом деле мелькание вызывалось нижеописанной проблемой с необходимостью задавать финальный параметр до анимации, но пересечение приводит к некоторым другим визуальным сбоям, хотя и малозаметным и допустимым (например, размер ячейки меняется быстрее, чем исчезает тень, но это поправимо)
        
        justReleasedIndexPath = draggingIndexPath
        
        //isReleaseCellAnimatedNow = true
        
        CATransaction.begin()
        let shadowFade = CABasicAnimation(keyPath: "shadowOpacity")
        shadowFade.fromValue = 0.8
        
        //такое разбиение пришлось делать, так как иначе компилятор сообщал, что не может распарсить выражение
        let betweenX: Double = Double(dragView.layer.position.x - targetCenter.x)
        let betweenY: Double = Double(dragView.layer.position.y - targetCenter.y)
        let betweenPoints:Double = sqrt(betweenX * betweenX + betweenY * betweenY)
        var animationTime:Double = betweenPoints / 300
        if animationTime < 0.45 { animationTime = 0.45 }
        if animationTime > 0.8 { animationTime = 0.8 }
        
        let moveAnimation = CASpringAnimation(keyPath: "position")
        moveAnimation.damping = 10.0
        moveAnimation.mass = 0.70
        moveAnimation.initialVelocity = 0.0
        moveAnimation.stiffness = 140.0
        moveAnimation.fromValue = dragView.layer.position
        moveAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        
        let transformAnimation = CABasicAnimation(keyPath: "transform.scale")
        transformAnimation.fromValue = dragView.transform.a//scale.x (для y использовать d)
        
        let animationGroup = CAAnimationGroup()
        animationGroup.duration = animationTime
        animationGroup.animations = [shadowFade, moveAnimation, transformAnimation]
        
        
        let lastDraggingView = draggingView
        let lastDraggingCell = draggingCell
        let lastDraggingIndexPath = draggingIndexPath
        let lastJustReleasedIndexPath = justReleasedIndexPath
        
        animationCounter += 1
        let counter = animationCounter
        print("before animation \(counter)")
        CATransaction.setCompletionBlock({
            print("after animation \(counter)")
            self.cleanDraggingIfCan(lastDraggingView: lastDraggingView, lastDraggingCell: lastDraggingCell, lastDraggingIndexPath: lastDraggingIndexPath, lastJustReleasedIndexPath: lastJustReleasedIndexPath)
            //self.isReleaseCellAnimatedNow = false
        })
        
        dragView.transform = CGAffineTransform.identity
        dragView.layer.shadowOpacity = 0.0
        dragView.layer.position = targetCenter//ключевой момент при анимации перемещения таким способом - нужно задать финальное значение перед анимацией, иначе будет мелькающее перемещение по завершении (также в этом случае не нужно задавать финальную позицию в параметрах анимации)
        
        dragView.layer.add(animationGroup, forKey: "animationGroup")
        
        CATransaction.commit()
    }
    
    func cleanDraggingIfCan(lastDraggingView: UIView?, lastDraggingCell: UICollectionViewCell?, lastDraggingIndexPath: IndexPath?, lastJustReleasedIndexPath: IndexPath?)
    {
        //проверить - можно ли вообще обойтись без isSwapAnimatedNow или требуется проверять - нужная ли анимация обрывается
//        if isSwapAnimatedNow
//        {//сейчас идёт анимация
//            print("isSwapAnimatedNow")
//            needCleanDragging = true
//        }
//        else
        //{
            cleanDraggingReal(lastDraggingView: lastDraggingView, lastDraggingCell: lastDraggingCell, lastDraggingIndexPath: lastDraggingIndexPath, lastJustReleasedIndexPath: lastJustReleasedIndexPath)
        //}
    }
    
    func cleanDraggingReal(lastDraggingView: UIView?, lastDraggingCell: UICollectionViewCell?, lastDraggingIndexPath: IndexPath?, lastJustReleasedIndexPath: IndexPath?)
    {
        //print("clean \(animationCounter) \(lastDraggingView) \(lastDraggingCell)")
        needCleanDragging = false
        lastDraggingCell?.isHidden = false
        lastDraggingView?.removeFromSuperview()
        if draggingView == lastDraggingView { draggingView = nil }
        //if draggingIndexPath == lastDraggingIndexPath { draggingIndexPath = nil }
        if justReleasedIndexPath == lastJustReleasedIndexPath { justReleasedIndexPath = nil }
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
