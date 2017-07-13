//
//  TIRRealTIRCollectionViewController.swift
//  ThreeInRow
//
//  Created by DMITRY SINYOV on 11.05.17.
//  Copyright © 2017 DMITRY SINYOV. All rights reserved.
//

import UIKit

fileprivate let reuseIdentifier = "cellID"

protocol TIRRealTIRViewProtocol: class
{
    func animateFieldChanges(oldViewCoords: [(row: Int, column: Int)], newViewCoords: [(row: Int, column: Int)], completionHandler: (() -> Void)?)
    func animateFieldRefill(columns: [[TIRRealTIRViewModelElement]])
    
    func animateElementsRemove(elements: [TIRRealTIRViewModelElement], completion: @escaping () -> Void)
}

class TIRRealTIRCollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, TIRRealTIRCollectionViewLayoutProtocol, TIRRealTIRViewProtocol
{
    var presenter: TIRRealTIRPresenterProtocol!
    private var selectedIndexPath: IndexPath?
    private var tapGesture: UITapGestureRecognizer?
    private var panGesture: UIPanGestureRecognizer?
    
    @IBOutlet weak var mainCollectionView: UICollectionView!
    
    private var snapshotPatterns = [TIRElementMainTypes : UIImage]()
    
    //FIXME: разобраться с замыканиями и возможными retain cycle в них
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
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
        let examples = presenter.examplesAllTypes()
        let snapshots = createSnapshotImages(elements: examples)
        for number in 0..<examples.count
        {
            snapshotPatterns.updateValue(snapshots[number], forKey: examples[number].type)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func animateElementsRemove(elements: [TIRRealTIRViewModelElement], completion: @escaping () -> Void)
    {
        let snapshoots = addSnapshootsForElements(elements: elements)
        animateSnapshootRemoveWithCompletion(snapshoots: snapshoots, completion: completion)
    }
    
    func addSnapshootsForElements(elements: [TIRRealTIRViewModelElement]) -> [UIView]
    {
        let snapshoots = createSnapshots(elements: elements)
        for snapshoot in snapshoots
        {
            mainCollectionView.addSubview(snapshoot)
        }
        return snapshoots
    }
    
    func animateSnapshootRemoveWithCompletion(snapshoots:[UIView], completion: @escaping () -> Swift.Void)
    {
        mainCollectionView.reloadData()
        UIView.animate(withDuration:0.5, animations: {
            
            snapshoots.forEach { snapshoot in
                
                snapshoot.transform = CGAffineTransform.init(scaleX: 0.1, y: 0.1)
            }
            
        }, completion: { (completed) in
            
            snapshoots.forEach { snapshoot in
                
                snapshoot.removeFromSuperview()
            }
            
            completion()
        })
    }
    
    func animateFieldChanges(oldViewCoords: [(row: Int, column: Int)], newViewCoords: [(row: Int, column: Int)], completionHandler: (() -> Void)?)
    {
        let movingSnapshots = self.addSnapshootsForCoords(coords: oldViewCoords)
        
        let newFrames = self.framesForCoords(coords: newViewCoords)
        
        //сделать невидимыми ячейки на старых местах
        self.makeCellsInvisibleOnCoords(coords: oldViewCoords)
        
        self.animateSnapshootsShift(snapshoots: movingSnapshots, newFrames: newFrames, completionShift: completionHandler)
    }
    
    func addSnapshootsForCoords(coords: [(row: Int, column: Int)]) -> [UIView]
    {
        let snapshots = self.createSnapshots(coords: coords)
        snapshots.forEach{ snapshot in
            
            self.mainCollectionView.addSubview(snapshot)
        }
        return snapshots
    }
    
    func makeCellsInvisibleOnCoords(coords: [(row: Int, column: Int)])
    {
        for coord in coords
        {
            let indexPath = IndexPath(row: coord.row * Int(self.collectionView(numberOfColumnsIn: self.mainCollectionView)) + coord.column, section: 0)
            guard let cell = self.mainCollectionView.cellForItem(at: indexPath) else { continue }
            cell.isHidden = true
        }
    }
    
    func animateSnapshootsShift(snapshoots: [UIView], newFrames: [CGRect], completionShift: ( () -> Void)?)
    {
        UIView.animate(withDuration: 0.5, animations: {
            
            for number in 0..<snapshoots.count
            {
                snapshoots[number].frame = newFrames[number]
            }
            
        }, completion: { finished in
            
            self.mainCollectionView.reloadData()
            self.mainCollectionView.layoutIfNeeded()//этот вызов нужен, так как reloadData не делает немедленной перерисовки и нельзя снять скриншоты в начале следующей операции
            
            snapshoots.forEach { snapshoot in
                
                snapshoot.removeFromSuperview()
            }
            
            if completionShift != nil { completionShift!() }
        })
    }
    
    //заполним пустые места
    func animateFieldRefill(columns: [[TIRRealTIRViewModelElement]])
    {
        let yShift : CGFloat = -100.0
        
        let snapshoots = addSnaphootsForColumns(columns: columns, yShift: yShift)
        
        animateSnapshootsShift(snapshoots: snapshoots, yShift: -yShift)
    }
    
    func addSnaphootsForColumns(columns: [[TIRRealTIRViewModelElement]], yShift: CGFloat) -> [UIImageView]
    {
        var snapshoots = [UIImageView]()
        for column in columns
        {
            for element in column
            {
                guard let snapshoot = addSnapshootForElement(element: element, yShift: yShift) else { continue }
                snapshoots.append(snapshoot)
            }
        }
        return snapshoots
    }
    
    func addSnapshootForElement(element: TIRRealTIRViewModelElement, yShift: CGFloat) -> UIImageView?
    {
        guard let image = snapshotPatterns[element.type] else { return nil }
        
        let snapshoot = UIImageView.init(image: image)
        
        var finalFrame = frameForCoord(coord: (row: element.row, column: element.column))
        finalFrame.origin.y += yShift
        snapshoot.frame = finalFrame
        mainCollectionView.addSubview(snapshoot)
        
        return snapshoot
    }
    
    func animateSnapshootsShift(snapshoots: [UIView], yShift: CGFloat)
    {
        UIView.animate(withDuration: 0.5, animations: {
            
            for snapshoot in snapshoots
            {
                snapshoot.frame.origin.y += yShift
            }
            
        }, completion: { finished in
            
            self.mainCollectionView.reloadData()
            self.mainCollectionView.layoutIfNeeded()
            
            snapshoots.forEach { snapshoot in
                snapshoot.removeFromSuperview()
            }
            
            self.presenter.removeThreesAndMore()
        })
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
        guard !presenter.isAnimating else { return }
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
                
                if presenter.canTrySwap(fromIndex: selectedIndexPath!, toIndex: indexPath)
                {
                    presenter.isAnimating = true
                    selectedCell.hideBorder()
                    
                    mainCollectionView.performBatchUpdates({
                        self.mainCollectionView.moveItem(at: self.selectedIndexPath!, to: indexPath)
                        self.mainCollectionView.moveItem(at: indexPath, to: self.selectedIndexPath!)
                        
                    }, completion: {(finished) in
                        
                        if self.presenter.canSwap(fromIndex: self.selectedIndexPath!, toIndex: indexPath)
                        {
                            self.collectionView(self.mainCollectionView, moveItemAt: self.selectedIndexPath!, to: indexPath)
                            //self.isAnimating = false
                            self.selectedIndexPath = nil
                            
                            self.presenter.removeThreesAndMore()
                        }
                        else
                        {
                            self.mainCollectionView.performBatchUpdates({
                                self.mainCollectionView.moveItem(at: self.selectedIndexPath!, to: indexPath)
                                self.mainCollectionView.moveItem(at: indexPath, to: self.selectedIndexPath!)
                                
                            }, completion: {(finished) in
                                self.presenter.isAnimating = false
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
    
    
    // MARK: UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return presenter.itemsPerRow * presenter.rowsCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! TIRRealTIRCollectionViewCell
        
        cell.isHidden = false
        
        let row = indexPath.row / presenter.itemsPerRow
        let column = indexPath.row % presenter.itemsPerRow
        guard let viewElement = presenter.elementByCoord(row: row, column: column) else { return cell }
        
        cell.setType(newType: viewElement.type)
        
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
        let rowSource = sourceIndexPath.row / presenter.itemsPerRow
        let columnSource = sourceIndexPath.row % presenter.itemsPerRow
        let rowDestination = destinationIndexPath.row / presenter.itemsPerRow
        let columnDestination = destinationIndexPath.row % presenter.itemsPerRow
        
        presenter.swapElementsByCoords(row1: rowSource, column1: columnSource, row2: rowDestination, column2: columnDestination)
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
        return UInt(presenter.itemsPerRow)
    }
    
    func collectionView(heightForCustomContentIn collectionView:UICollectionView, indexPath:IndexPath) -> CGFloat
    {
//        let row = indexPath.row / itemsPerRow
//        let column = indexPath.row % itemsPerRow
        
        return 0//(modelArray[row][column]).customContentHeight
    }
    
    func createSnapshots(elements: [TIRRealTIRViewModelElement]) -> [UIView]
    {
        var coords = [(row: Int, column: Int)]()
        for element in elements
        {
            coords.append((row: element.row, column: element.column))
        }
        return createSnapshots(coords: coords)
    }
    func createSnapshots(coords: [(row: Int, column: Int)]) -> [UIView]
    {
        var snapshots = [UIView]()
        for coord in coords
        {
            let indexPath = IndexPath(row: coord.row * presenter.itemsPerRow + coord.column, section: 0)
            guard let cell = mainCollectionView.cellForItem(at: indexPath) else { continue }
            
            guard let snapshot = cell.snapshotView(afterScreenUpdates: true) else { continue }
            
            snapshot.frame = cell.frame
            
            snapshots.append(snapshot)
        }
        
        return snapshots
    }
    
    func createSnapshotImages(elements: [TIRRealTIRViewModelElement]) -> [UIImage]
    {
        var snapshots = [UIImage]()
        for element in elements
        {
            let indexPath = IndexPath(row: element.row * presenter.itemsPerRow + element.column, section: 0)
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
    
    func framesForCoords(coords: [(row: Int, column: Int)]) -> [CGRect]
    {
        var frames = [CGRect]()
        for coord in coords
        {
            frames.append(frameForCoord(coord: coord))
        }
        return frames
    }
    
    func frameForCoord(coord: (row: Int, column: Int)) -> CGRect
    {
        let indexPath = IndexPath(row: coord.row * presenter.itemsPerRow + coord.column, section: 0)
        guard let cell = mainCollectionView.cellForItem(at: indexPath) else { return CGRect() }
        return cell.frame
    }
}
