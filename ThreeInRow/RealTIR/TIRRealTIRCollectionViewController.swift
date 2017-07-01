//
//  TIRRealTIRCollectionViewController.swift
//  ThreeInRow
//
//  Created by DMITRY SINYOV on 11.05.17.
//  Copyright © 2017 DMITRY SINYOV. All rights reserved.
//

import UIKit

fileprivate let reuseIdentifier = "cellID"

class TIRRealTIRCollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, TIRRealTIRCollectionViewLayoutProtocol
{
    private var model: TIRRealTIRModel = TIRRealTIRModel()
    private var selectedIndexPath: IndexPath?
    private var tapGesture: UITapGestureRecognizer?
    private var panGesture: UIPanGestureRecognizer?
    
    private var isAnimating: Bool = false
    
    @IBOutlet weak var mainCollectionView: UICollectionView!
    
    private var snapshotPatterns = [TIRElementMainTypes : UIImage]()
    
    //FIXME: разобраться с замыканиями и возможными retain cycle в них
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        model.setupModel()
        
        if let layout = mainCollectionView.collectionViewLayout as? TIRRealTIRCollectionViewLayout
        {
            layout.delegate = self
        }
        
        self.mainCollectionView.delegate = self
        self.mainCollectionView.dataSource = self
        self.mainCollectionView!.register(UINib(nibName: "TIRRealTIRCollectionViewCell", bundle : nil), forCellWithReuseIdentifier: reuseIdentifier)
        
        installGestureDraggingRecognizer()
        
        self.automaticallyAdjustsScrollViewInsets = false
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        //сделаем снапшоты всех типов ячеек
        let examples = model.examplesAllTypes()
        let snapshots = createSnapshotImages(elements: examples)
        for number in 0..<examples.count
        {
            snapshotPatterns.updateValue(snapshots[number], forKey: examples[number].elementType)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func clearThreesButtonTouched(_ sender: UIButton)
    {
        //следующие шаги:
        //получаем из модели список ячеек на удаление//
        //получаем список сдвигаемых ячеек из старых и их новые координаты//
        //получаем список на добавление//
        //обновляем модель, но не таблицу//
        //создаём снапшоты для всех список ячеек и анимируем процесс//
        //обновляем таблицу и убираем снапшоты//
        
        //разбить процесс на разумные блоки
        
        let chainsForRemove = model.findChains()
        
        //подготовка к анимации удаления
        var removingElements = [TIRRealTIRModelElement]()
        for chain in chainsForRemove
        {
            removingElements.append(contentsOf: chain)
        }
        let snapshots = createSnapshots(elements: removingElements)
        for snapshot in snapshots
        {
            mainCollectionView.addSubview(snapshot)
        }
        
        //удалим цепочки
        model.removeChains(chains: chainsForRemove)
        //обновим поле, но не снапшоты поверх него
        mainCollectionView.reloadData()
        
        UIView.animate(withDuration:0.5, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0, options: [], animations: {
            
            snapshots.forEach { snapshot in
                
                snapshot.transform = CGAffineTransform.init(scaleX: 0.1, y: 0.1)
            }
            
        }, completion: { (completed) in
            
            snapshots.forEach { snapshot in
                
                snapshot.removeFromSuperview()
            }
            
            //создадим снапшоты на старых местах и сдвинем на новые
            let (oldCoords, newCoords) = self.model.useGravityOnField()
            
            let movingSnapshots = self.createSnapshots(coords: oldCoords)
            
            var newFrames = [CGRect]()
            for coord in newCoords
            {
                let indexPath = IndexPath(row: coord.row * self.model.itemsPerRow + coord.column, section: 0)
                guard let cell = self.mainCollectionView.cellForItem(at: indexPath) else { continue }
                newFrames.append(cell.frame)
            }
            
            movingSnapshots.forEach{ snapshot in
                
                self.mainCollectionView.addSubview(snapshot)
            }
            
            //сделать невидимыми ячейки на старых местах
            for coord in oldCoords
            {
                let indexPath = IndexPath(row: coord.row * self.model.itemsPerRow + coord.column, section: 0)
                guard let cell = self.mainCollectionView.cellForItem(at: indexPath) else { continue }
                cell.isHidden = true
            }
            
            UIView.animate(withDuration: 0.5, animations: {
                
                for number in 0..<movingSnapshots.count
                {
                    movingSnapshots[number].frame = newFrames[number]
                }
                
            }, completion: { finished in
                
                self.mainCollectionView.reloadData()
                
                movingSnapshots.forEach { snapshot in
                    
                    snapshot.removeFromSuperview()
                }
                
            })
            
        })
    }
    
    @IBAction func fillEmptiesButtonTouched(_ sender: UIButton)
    {
        let refilledColumns = model.refillFieldByColumns()
        
        var snapshoots = [UIView]()
        let yShift : CGFloat = 100.0
        for column in refilledColumns
        {
            //создадим снапшоты нужных типов из образцов
            
            for element in column
            {
                guard let image = snapshotPatterns[element.elementType] else { continue }
                
                let snapshoot = UIImageView.init(image: image)
                
                var finalFrame = frameForCoord(coord: element.coordinates)
                finalFrame.origin.y -= yShift
                snapshoot.frame = finalFrame
                
                snapshoots.append(snapshoot)
                
                mainCollectionView.addSubview(snapshoot)
            }
            
        }
        
        UIView.animate(withDuration: 0.5, animations: {
            
            for snapshoot in snapshoots
            {
                snapshoot.frame.origin.y += yShift
            }
            
        }, completion: { finished in
            
            self.mainCollectionView.reloadData()
            
            snapshoots.forEach { snapshoot in
                snapshoot.removeFromSuperview()
            }
        })
        
        //mainCollectionView.reloadData()
        
    }
    
    //жесты
    func installGestureDraggingRecognizer()
    {
        if tapGesture == nil
        {
            let action = #selector(self.handleGesture(gesture:))
            tapGesture = UITapGestureRecognizer(target: self, action: action)
            mainCollectionView.addGestureRecognizer(tapGesture!)
        }
        if panGesture == nil
        {
            let action = #selector(self.handleGesture(gesture:))
            panGesture = UIPanGestureRecognizer(target: self, action: action)
            mainCollectionView.addGestureRecognizer(panGesture!)
        }
    }
    func handleGesture(gesture: UIGestureRecognizer)
    {
        let location = gesture.location(in:mainCollectionView)
        switch gesture.state
        {
        case .began: handleGesture(atLocation: location, canStart: true)
        case .changed: handleGesture(atLocation: location, canStart: false)
        case .ended: handleGesture(atLocation: location, canStart: gesture is UITapGestureRecognizer)
        default:
            break
        }
    }
    func handleGesture(atLocation location: CGPoint, canStart: Bool!)
    {
        guard !isAnimating else { return }
        guard let indexPath = mainCollectionView.indexPathForItem(at:location) else { return }
        guard collectionView(mainCollectionView, canMoveItemAt: indexPath) == true else { return }
        guard let cell = mainCollectionView.cellForItem(at:indexPath) as? TIRRealTIRCollectionViewCell else { return }
        
        if selectedIndexPath == nil
        {
            guard canStart == true else { return }
            selectedIndexPath = indexPath
            cell.showBorder()
        }
        else
        {
            if indexPath == selectedIndexPath
            {
                
            }
            else
            {
                guard let selectedCell = mainCollectionView.cellForItem(at:selectedIndexPath!) as? TIRRealTIRCollectionViewCell else { return }
                
                if canTrySwap(fromIndex: selectedIndexPath!, toIndex: indexPath)
                {
                    isAnimating = true
                    selectedCell.hideBorder()
                    
                    mainCollectionView.performBatchUpdates({
                        self.mainCollectionView.moveItem(at: self.selectedIndexPath!, to: indexPath)
                        self.mainCollectionView.moveItem(at: indexPath, to: self.selectedIndexPath!)
                        
                    }, completion: {(finished) in
                        
                        if self.canSwap(fromIndex: self.selectedIndexPath!, toIndex: indexPath)
                        {
                            self.collectionView(self.mainCollectionView, moveItemAt: self.selectedIndexPath!, to: indexPath)
                            self.isAnimating = false
                            self.selectedIndexPath = nil
                        }
                        else
                        {
                            self.mainCollectionView.performBatchUpdates({
                                self.mainCollectionView.moveItem(at: self.selectedIndexPath!, to: indexPath)
                                self.mainCollectionView.moveItem(at: indexPath, to: self.selectedIndexPath!)
                                
                            }, completion: {(finished) in
                                self.isAnimating = false
                                self.selectedIndexPath = nil
                            })
                        }
                        
                    })
                }
                else//если не можем в принципе менять эти ячейки, то выбрать новую базовую
                {
                    guard canStart == true else { return }
                    selectedIndexPath = indexPath
                    selectedCell.hideBorder()
                    cell.showBorder()
                }
                
            }
        }
    }
    func canTrySwap(fromIndex: IndexPath, toIndex: IndexPath) -> Bool//проверка, что ячейки являются соседями по горизонтали или вертикали
    {
        let fromRow = fromIndex.row / model.itemsPerRow
        let fromColumn = fromIndex.row % model.itemsPerRow
        let toRow = toIndex.row / model.itemsPerRow
        let toColumn = toIndex.row % model.itemsPerRow
        
        return model.canTrySwap(fromCoord: TIRRowColumn(row: fromRow, column: fromColumn), toCoord: TIRRowColumn(row: toRow, column: toColumn))
    }
    func canSwap(fromIndex: IndexPath, toIndex: IndexPath) -> Bool//проверка, что ячейки можно поменять реально (получившееся состояние будет допустимым)
    {
        let toRow = toIndex.row / model.itemsPerRow
        let toColumn = toIndex.row % model.itemsPerRow
        let fromRow = fromIndex.row / model.itemsPerRow
        let fromColumn = fromIndex.row % model.itemsPerRow
        
        return model.canSwap(fromCoord: TIRRowColumn(row: fromRow, column: fromColumn), toCoord: TIRRowColumn(row: toRow, column: toColumn))
    }
    
    // MARK: UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return model.itemsPerRow * model.rowsCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! TIRRealTIRCollectionViewCell
        
        cell.isHidden = false
        
        let row = indexPath.row / model.itemsPerRow
        let column = indexPath.row % model.itemsPerRow
        let modelElement = model.elementByCoord(coord: TIRRowColumn(row: row, column: column))
        
        guard modelElement != nil else { return cell }
        
        cell.setType(newType: modelElement!.elementType)
        
        if indexPath == selectedIndexPath { cell.showBorder() }
        else { cell.hideBorder() }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool
    {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath)
    {
        //обновим модель
        let rowSource = sourceIndexPath.row / model.itemsPerRow
        let columnSource = sourceIndexPath.row % model.itemsPerRow
        let rowDestination = destinationIndexPath.row / model.itemsPerRow
        let columnDestination = destinationIndexPath.row % model.itemsPerRow
        
        model.swapElementsByCoords(firstCoord: TIRRowColumn(row: rowSource, column: columnSource), secondCoord: TIRRowColumn(row: rowDestination, column: columnDestination))
    }
    
    //MARK: UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool
    {
        return false
    }
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
//    {
//        selectedIndexPath = indexPath
//        let cell = collectionView.cellForItem(at: indexPath) as! TIRRealTIRCollectionViewCell
//        cell.showBorder()
//    }
//    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath)
//    {
//        selectedIndexPath = nil
//        let cell = collectionView.cellForItem(at: indexPath) as! TIRRealTIRCollectionViewCell
//        cell.hideBorder()
//    }
    
    //MARK: TIRCollectionViewLayoutProtocol
    func collectionView(numberOfColumnsIn collectionView: UICollectionView) -> UInt
    {
        return UInt(model.itemsPerRow)
    }
    
    func collectionView(heightForCustomContentIn collectionView:UICollectionView, indexPath:IndexPath) -> CGFloat
    {
//        let row = indexPath.row / itemsPerRow
//        let column = indexPath.row % itemsPerRow
        
        return 0//(modelArray[row][column]).customContentHeight
    }
    
    func createSnapshots(elements: [TIRRealTIRModelElement]) -> [UIView]
    {
        var snapshots = [UIView]()
        for element in elements
        {
            let indexPath = IndexPath(row: element.coordinates.row * model.itemsPerRow + element.coordinates.column, section: 0)
            guard let cell = mainCollectionView.cellForItem(at: indexPath) else { continue }
            
            guard let snapshot = cell.snapshotView(afterScreenUpdates: true) else { continue }
            
            snapshot.frame = cell.frame
            
            snapshots.append(snapshot)
        }
        
        return snapshots
    }
    func createSnapshots(coords: [TIRRowColumn]) -> [UIView]
    {
        var snapshots = [UIView]()
        for coord in coords
        {
            let indexPath = IndexPath(row: coord.row * model.itemsPerRow + coord.column, section: 0)
            guard let cell = mainCollectionView.cellForItem(at: indexPath) else { continue }
            
            guard let snapshot = cell.snapshotView(afterScreenUpdates: true) else { continue }
            
            snapshot.frame = cell.frame
            
            snapshots.append(snapshot)
        }
        
        return snapshots
    }
    
    func createSnapshotImages(elements: [TIRRealTIRModelElement]) -> [UIImage]
    {
        var snapshots = [UIImage]()
        for element in elements
        {
            let indexPath = IndexPath(row: element.coordinates.row * model.itemsPerRow + element.coordinates.column, section: 0)
            guard let cell = mainCollectionView.cellForItem(at: indexPath) else { continue }
            
            guard let snapshot = imageOfView(view: cell) else { continue }
            
            snapshots.append(snapshot)
        }
        
        return snapshots
    }
    func imageOfView(view: UIView) -> UIImage?
    {
        UIGraphicsBeginImageContext(view.frame.size)
        //view.layer.render(in:UIGraphicsGetCurrentContext()!)
        view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    func frameForCoord(coord: TIRRowColumn) -> CGRect
    {
        let indexPath = IndexPath(row: coord.row * model.itemsPerRow + coord.column, section: 0)
        guard let cell = mainCollectionView.cellForItem(at: indexPath) else { return CGRect() }
        return cell.frame
    }
}
