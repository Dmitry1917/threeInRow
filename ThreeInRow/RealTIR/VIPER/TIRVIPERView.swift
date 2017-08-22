//
//  TIRVIPERView.swift
//  ThreeInRow
//
//  Created by DMITRY SINYOV on 21.08.17.
//  Copyright © 2017 DMITRY SINYOV. All rights reserved.
//

import UIKit

fileprivate let reuseIdentifier = "cellID"

protocol TIRVIPERViewProtocol: class
{
    func animateFieldChanges(oldViewCoords: [(row: Int, column: Int)], newViewCoords: [(row: Int, column: Int)], completionHandler: (() -> Void)?)
    func animateFieldRefill(columns: [[TIRVIPERViewModelElement]])
    
    func animateElementsRemove(elements: [TIRVIPERViewModelElement], completion: @escaping () -> Void)
    
    func animationSequenceStoped()
}
//view не должен напрямую запрашивать данные из презентера
class TIRVIPERView: UIViewController {

    @IBOutlet weak var mainCollectionView: UICollectionView!
    
    fileprivate var selectedIndexPath: IndexPath?
    private var tapGesture: UITapGestureRecognizer?
    private var panGesture: UIPanGestureRecognizer?
    fileprivate var snapshotPatterns = [TIRElementMainTypes : UIImage]()
    fileprivate var isAnimating = false
    
    var presenter: TIRVIPERPresenterFromViewProtocol!
    
    fileprivate var itemsPerRow = 0
    fileprivate var rowsCount = 0
    fileprivate var currentField = [[TIRVIPERViewModelElement]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
        
        presenter.prepareFieldPresentation()
    }

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        //сделаем снапшоты всех типов ячеек
        let examples = examplesAllTypes()
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
    
    func examplesAllTypes() -> [TIRVIPERViewModelElement]
    {
        var examples = [TIRVIPERViewModelElement]()
        
        for elementType in TIRElementMainTypes.allReal()
        {
            var found = false
            for row in 0..<rowsCount
            {
                for column in 0..<itemsPerRow
                {
                    let element = currentField[row][column]
                    if element.type == elementType
                    {
                        examples.append(element)
                        found = true
                        break
                    }
                }
                if found { break }
            }
        }
        
        return examples
    }
    
    //animateElementsRemove
    func addSnapshootsForElements(elements: [TIRVIPERViewModelElement]) -> [UIView]
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
    
    //animatefieldchanges
    
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
    
    //animatefieldrefill
    
    func addSnaphootsForColumns(columns: [[TIRVIPERViewModelElement]], yShift: CGFloat) -> [UIImageView]
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
    
    func addSnapshootForElement(element: TIRVIPERViewModelElement, yShift: CGFloat) -> UIImageView?
    {
        guard let image = snapshotPatterns[element.type] else { return nil }
        
        let snapshoot = UIImageView.init(image: image)
        
        var finalFrame = frameForCoord(row: element.row, column: element.column)
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
        case .began: handleGesture(atLocation: location, canChooseFirstSelectedCell: true)
        case .changed: handleGesture(atLocation: location, canChooseFirstSelectedCell: false)
        case .ended: handleGesture(atLocation: location, canChooseFirstSelectedCell: gesture is UITapGestureRecognizer)
        default:
            break
        }
    }
    
    //TODO: сильно сцепленный метод - возможно, есть способ разделить логику presenter и view лучше, но пока идей нет
    func handleGesture(atLocation location: CGPoint, canChooseFirstSelectedCell: Bool!)
    {
        guard !isAnimating else { return }
        guard let indexPath = mainCollectionView.indexPathForItem(at:location) else { return }
        guard collectionView(mainCollectionView, canMoveItemAt: indexPath) == true else { return }
        guard let cell = mainCollectionView.cellForItem(at:indexPath) as? TIRRealTIRCollectionViewCell else { return }
        
        if selectedIndexPath == nil
        {
            guard canChooseFirstSelectedCell == true else { return }
            selectedIndexPath = indexPath
            cell.showBorder()
        }
        else
        {
            if indexPath != selectedIndexPath
            {
                guard mainCollectionView.cellForItem(at:selectedIndexPath!) != nil else { return }
                let fromCoord = coordsForIndexPath(indexPath: selectedIndexPath!)
                let toCoord = coordsForIndexPath(indexPath: indexPath)
                presenter.swapElementsByCoordsIfCan(first: fromCoord, second: toCoord)
            }
        }
    }

    
    func createSnapshots(elements: [TIRVIPERViewModelElement]) -> [UIView]
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
            let indexPath = indexPathForCoords(row: coord.row, column: coord.column)
            guard let cell = mainCollectionView.cellForItem(at: indexPath) else { continue }
            
            guard let snapshot = cell.snapshotView(afterScreenUpdates: true) else { continue }
            
            snapshot.frame = cell.frame
            
            snapshots.append(snapshot)
        }
        
        return snapshots
    }
    
    func createSnapshotImages(elements: [TIRVIPERViewModelElement]) -> [UIImage]
    {
        var snapshots = [UIImage]()
        for element in elements
        {
            let indexPath = indexPathForCoords(row: element.row, column: element.column)
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
            frames.append(frameForCoord(row: coord.row, column: coord.column))
        }
        return frames
    }
    
    func frameForCoord(row: Int, column: Int) -> CGRect
    {
        let indexPath = indexPathForCoords(row: row, column: column)
        guard let cell = mainCollectionView.cellForItem(at: indexPath) else { return CGRect() }
        return cell.frame
    }
    
    func indexPathForCoords(row: Int, column: Int) -> IndexPath
    {
        return IndexPath(row: row * Int(collectionView(numberOfColumnsIn: mainCollectionView)) + column, section: 0)
    }
    func coordsForIndexPath(indexPath: IndexPath) -> (row: Int, column: Int)
    {
        let row = indexPath.row / Int(self.collectionView(numberOfColumnsIn: mainCollectionView))
        let column = indexPath.row % Int(self.collectionView(numberOfColumnsIn: mainCollectionView))
        return (row, column)
    }
}

extension TIRVIPERView: UICollectionViewDelegate, UICollectionViewDataSource {
    
    // MARK: UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return itemsPerRow * rowsCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! TIRRealTIRCollectionViewCell
        
        cell.isHidden = false
        
        let coord = coordsForIndexPath(indexPath: indexPath)
        guard let viewElement = presenter.elementByCoord(row: coord.row, column: coord.column) else { return cell }
        
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
        let source = coordsForIndexPath(indexPath: sourceIndexPath)
        let destination = coordsForIndexPath(indexPath: destinationIndexPath)
        presenter.moveElementFromTo(row1: source.row, column1: source.column, row2: destination.row, column2: destination.column)
    }
    
    //MARK: UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool
    {
        return false
    }
}

extension TIRVIPERView: TIRRealTIRCollectionViewLayoutProtocol {
    
    //MARK: TIRCollectionViewLayoutProtocol
    func collectionView(numberOfColumnsIn collectionView: UICollectionView) -> UInt
    {
        return UInt(itemsPerRow)
    }
    
    func collectionView(heightForCustomContentIn collectionView:UICollectionView, indexPath:IndexPath) -> CGFloat
    {
        return 0
    }
}

extension TIRVIPERView: TIRVIPERViewProtocol {
    
    func animateFieldChanges(oldViewCoords: [(row: Int, column: Int)], newViewCoords: [(row: Int, column: Int)], completionHandler: (() -> Void)?)
    {
        let movingSnapshots = self.addSnapshootsForCoords(coords: oldViewCoords)
        
        let newFrames = self.framesForCoords(coords: newViewCoords)
        
        //сделать невидимыми ячейки на старых местах
        self.makeCellsInvisibleOnCoords(coords: oldViewCoords)
        
        self.animateSnapshootsShift(snapshoots: movingSnapshots, newFrames: newFrames, completionShift: completionHandler)
    }
    
    func animateFieldRefill(columns: [[TIRVIPERViewModelElement]])
    {
        let yShift : CGFloat = -100.0
        
        let snapshoots = addSnaphootsForColumns(columns: columns, yShift: yShift)
        
        animateSnapshootsShift(snapshoots: snapshoots, yShift: -yShift)
    }
    
    func animateElementsRemove(elements: [TIRVIPERViewModelElement], completion: @escaping () -> Void)
    {
        let snapshoots = addSnapshootsForElements(elements: elements)
        animateSnapshootRemoveWithCompletion(snapshoots: snapshoots, completion: completion)
    }
    
    func animationSequenceStoped()
    {
        isAnimating = false
    }
}

extension TIRVIPERView: TIRVIPERPresenterToViewProtocol {
    
    func setField(newField: [[TIRVIPERViewModelElement]], reloadNow: Bool) {
        currentField = newField
        rowsCount = currentField.count
        
        if rowsCount > 0 { itemsPerRow = currentField[0].count } else { itemsPerRow = 0 }
        
        if reloadNow { mainCollectionView.reloadData() }
    }
    
    func chooseCell(coord:(row: Int, column: Int))
    {
        let currentSelectedCell = mainCollectionView.cellForItem(at:selectedIndexPath!) as? TIRRealTIRCollectionViewCell
        let indexPath = indexPathForCoords(row: coord.row, column: coord.column)
        let cell = mainCollectionView.cellForItem(at:indexPath) as? TIRRealTIRCollectionViewCell
        selectedIndexPath = indexPath
        currentSelectedCell?.hideBorder()
        cell?.showBorder()
    }
    
    func animateUnsuccessfullSwap(first: (row: Int, column: Int), second: (row: Int, column: Int)) {
        
        let firstIndexPath = indexPathForCoords(row: first.row, column: first.column)
        let secondIndexPath = indexPathForCoords(row: second.row, column: second.column)
        
        guard let firstCell = mainCollectionView.cellForItem(at:firstIndexPath) as? TIRRealTIRCollectionViewCell else { return }
        guard let secondCell = mainCollectionView.cellForItem(at:secondIndexPath) as? TIRRealTIRCollectionViewCell else { return }
        
        isAnimating = true
        firstCell.hideBorder()
        secondCell.hideBorder()
        
        mainCollectionView.performBatchUpdates({
            self.mainCollectionView.moveItem(at: firstIndexPath, to: secondIndexPath)
            self.mainCollectionView.moveItem(at: secondIndexPath, to: firstIndexPath)
            
        }, completion: {(finished) in
            
            self.mainCollectionView.performBatchUpdates({
                self.mainCollectionView.moveItem(at: firstIndexPath, to: secondIndexPath)
                self.mainCollectionView.moveItem(at: secondIndexPath, to: firstIndexPath)
                
            }, completion: {(finished) in
                self.isAnimating = false
                self.selectedIndexPath = nil
            })
        })
    }
    
    func animateSuccessfullSwap(first: (row: Int, column: Int), second: (row: Int, column: Int)) {
        let firstIndexPath = indexPathForCoords(row: first.row, column: first.column)
        let secondIndexPath = indexPathForCoords(row: second.row, column: second.column)
        
        guard let firstCell = mainCollectionView.cellForItem(at:firstIndexPath) as? TIRRealTIRCollectionViewCell else { return }
        guard let secondCell = mainCollectionView.cellForItem(at:secondIndexPath) as? TIRRealTIRCollectionViewCell else { return }
        
        isAnimating = true
        firstCell.hideBorder()
        secondCell.hideBorder()
        selectedIndexPath = nil
        
        mainCollectionView.performBatchUpdates({
            self.mainCollectionView.moveItem(at: firstIndexPath, to: secondIndexPath)
            self.mainCollectionView.moveItem(at: secondIndexPath, to: firstIndexPath)
            
        }, completion: {(finished) in
            //поменяли элементы в локальной модели
            let tempElement = self.currentField[first.row][first.column]
            self.currentField[first.row][first.column] = self.currentField[second.row][second.column]
            self.currentField[second.row][second.column] = tempElement
            
            //self.interactor.removeThreesAndMore()
        })
    }
}
