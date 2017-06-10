//
//  TIRRealTIRCollectionViewController.swift
//  ThreeInRow
//
//  Created by DMITRY SINYOV on 11.05.17.
//  Copyright © 2017 DMITRY SINYOV. All rights reserved.
//

import UIKit

class TIRRowColumn: NSObject
{
    var row: Int = 0
    var column: Int = 0
    
    init(row: Int, column: Int)
    {
        self.row = row
        self.column = column
    }
    
    override func isEqual(_ object: Any?) -> Bool
    {
        if let coord = object as? TIRRowColumn
        {
            if row == coord.row && column == coord.column
            {
                return true
            }
        }
        return false
    }
}

fileprivate let reuseIdentifier = "cellID"

class TIRRealTIRCollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, TIRRealTIRCollectionViewLayoutProtocol
{
    private var modelArray = [[TIRRealTIRModelElement]]()
    private let itemsPerRow: Int = 8
    private let rowsCount: Int = 8
    
    private var selectedIndexPath: IndexPath?
    private var tapGesture: UITapGestureRecognizer?
    private var panGesture: UIPanGestureRecognizer?
    
    private var isAnimating: Bool = false
    
    @IBOutlet weak var mainCollectionView: UICollectionView!
    
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
        
        modelArray = (0..<rowsCount).map
        { (i) -> [TIRRealTIRModelElement] in
            
            let rowContent: [TIRRealTIRModelElement] = (0..<itemsPerRow).map
            { (j) -> TIRRealTIRModelElement in
                
                let modelElement = TIRRealTIRModelElement()
                
//                let randomParameterRed = CGFloat(arc4random_uniform(255))
//                let randomParameterGreen = CGFloat(arc4random_uniform(255))
//                let randomParameterBlue = CGFloat(arc4random_uniform(255))
//                modelElement.mainColor = UIColor(red: randomParameterRed / 255.0, green: randomParameterGreen / 255.0, blue: randomParameterBlue / 255.0, alpha: 1.0)
//                modelElement.contentColor = UIColor(red: 0.1, green: 0.6, blue: 0.3, alpha: 1.0)
//                modelElement.customContentHeight = CGFloat(arc4random_uniform(5))
                
                modelElement.elementType = TIRElementMainTypes.randomType()
                modelElement.coordinates = TIRRowColumn(row: i, column: j)
                
                return modelElement
            }
            
            return rowContent
        }
        
        //print("\(modelArray)")
        
        installGestureDraggingRecognizer()
        
        self.automaticallyAdjustsScrollViewInsets = false
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        let fromRow = fromIndex.row / itemsPerRow
        let fromColumn = fromIndex.row % itemsPerRow
        let toRow = toIndex.row / itemsPerRow
        let toColumn = toIndex.row % itemsPerRow
        
        //print("\(fromRow) \(fromColumn) \(toRow) \(toColumn) \(NSDate())")
        
        if abs(fromRow - toRow) < 2 && fromColumn == toColumn || abs(fromColumn - toColumn) < 2 && fromRow == toRow { return true }
        else { return false }
    }
    func canSwap(fromIndex: IndexPath, toIndex: IndexPath) -> Bool//проверка, что ячейки можно поменять реально (получившееся состояние будет допустимым)
    {
        //TODO: привести этот метод в порядок - разбить на более читабельные части, устранить повторяемость и т.д.
        //достаточно проверить соседей в радиусе 2-х клеток (от обеих поменянных местами), чтобы знать о тройках
        let toRow = toIndex.row / itemsPerRow
        let toColumn = toIndex.row % itemsPerRow
        let fromRow = fromIndex.row / itemsPerRow
        let fromColumn = fromIndex.row % itemsPerRow
        
        let checkedModelElementFrom = modelArray[fromRow][fromColumn]
        let checkedModelElementTo = modelArray[toRow][toColumn]
        
        //проще оказалось временно поменять модель для проверки, чем постоянно учитывать, что она пока не соответствует проверяемому
        modelArray[fromRow][fromColumn] = modelArray[toRow][toColumn]
        modelArray[toRow][toColumn] = checkedModelElementFrom
        
        //найдём все ячейки того же типа, что и приверяемая
        let result = findThrees(checkedModelElement: checkedModelElementFrom, coords: TIRRowColumn(row: toRow, column: toColumn)) || findThrees(checkedModelElement: checkedModelElementTo, coords: TIRRowColumn(row: fromRow, column: fromColumn))//координаты переставлены, так как модель изменена на время проверки
        
        modelArray[toRow][toColumn] = modelArray[fromRow][fromColumn]
        modelArray[fromRow][fromColumn] = checkedModelElementFrom
        
        return result
    }
    func findThrees(checkedModelElement: TIRRealTIRModelElement, coords: TIRRowColumn) -> Bool
    {
        var sameTypeArray: [TIRRowColumn] = []
        
        var minRow = coords.row - 2
        var maxRow = coords.row + 2
        var minColumn = coords.column - 2
        var maxColumn = coords.column + 2
        
        if minRow < 0 { minRow = 0 }
        if maxRow > rowsCount - 1 { maxRow = rowsCount - 1}
        if minColumn < 0 { minColumn = 0 }
        if maxColumn > itemsPerRow - 1 { maxColumn = itemsPerRow - 1 }
        
        for row in minRow...maxRow
        {
            for column in minColumn...maxColumn
            {
                let modelElement = modelArray[row][column]
                
                if modelElement.elementType == checkedModelElement.elementType
                {
                    sameTypeArray.append(TIRRowColumn(row: row, column: column))
                }
            }
        }
        
        //print("\(sameTypeArray)")
        
        //проверим наличие подходящих групп соседних ячеек
        
        //для каждой ячейки находим соседние того же типа, затем для получившегося массива проверяем оставшиеся на подходящие соседства (у пары ячеек уже можно определить направление, значит нужно проверить только две подходящие координаты)
        for coordFirst in sameTypeArray
        {
            for coordSecond in sameTypeArray
            {
                guard coordFirst != coordSecond else { continue }
                //соседи ли
                if abs(coordFirst.row - coordSecond.row) < 2 && coordFirst.column == coordSecond.column || abs(coordFirst.column - coordSecond.column) < 2 && coordFirst.row == coordSecond.row
                {
                    //проверим наличие третьей по линии найденных ячеек
                    if coordFirst.row == coordSecond.row//на одной горизонтали
                    {
                        let minColumn = min(coordFirst.column, coordSecond.column) - 1
                        let maxColumn = max(coordFirst.column, coordSecond.column) + 1
                        
                        let seekCoordMin = TIRRowColumn(row: coordFirst.row, column: minColumn)
                        let seekCoordMax = TIRRowColumn(row: coordFirst.row, column: maxColumn)
                        
                        if sameTypeArray.contains(seekCoordMin) || sameTypeArray.contains(seekCoordMax) { return true }//нашли тройку - проверка удачна
                    }
                    else//на одной вертикали
                    {
                        let minRow = min(coordFirst.row, coordSecond.row) - 1
                        let maxRow = max(coordFirst.row, coordSecond.row) + 1
                        
                        let seekCoordMin = TIRRowColumn(row: minRow, column: coordFirst.column)
                        let seekCoordMax = TIRRowColumn(row: maxRow, column: coordFirst.column)
                        
                        if sameTypeArray.contains(seekCoordMin) || sameTypeArray.contains(seekCoordMax) { return true }//нашли тройку - проверка удачна
                    }
                    
                }
            }
        }
        
        return false
    }
    func findIdenticalNeighbors()
    {
        for row: [TIRRealTIRModelElement] in modelArray
        {
            for element: TIRRealTIRModelElement in row
            {
                print("\(element)")
            }
        }
    }
//    func getNeighbors(checkedModelElement: TIRRealTIRModelElement, coord: TIRRowColumn) -> [TIRRealTIRModelElement]
//    {
//        
//    }
    
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! TIRRealTIRCollectionViewCell
        
        // Configure the cell
        
        let row = indexPath.row / itemsPerRow
        let column = indexPath.row % itemsPerRow
        let modelElement = modelArray[row][column]
        //print("\(row) \(column)")
//        cell.setMainColor(mainColor: modelElement.mainColor)
//        cell.setContentColor(contentColor: modelElement.contentColor)
        cell.setType(newType: modelElement.elementType!)
        
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
        let rowSource = sourceIndexPath.row / itemsPerRow
        let columnSource = sourceIndexPath.row % itemsPerRow
        let sourceModelElement = modelArray[rowSource][columnSource]
        
        let rowDestination = destinationIndexPath.row / itemsPerRow
        let columnDestination = destinationIndexPath.row % itemsPerRow
        let destinationModelElement = modelArray[rowDestination][columnDestination]
        
        sourceModelElement.coordinates = TIRRowColumn(row: rowDestination, column: columnDestination)
        destinationModelElement.coordinates = TIRRowColumn(row: rowSource, column: columnSource)
        modelArray[rowSource][columnSource] = modelArray[rowDestination][columnDestination]
        modelArray[rowDestination][columnDestination] = sourceModelElement
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
        return UInt(itemsPerRow)
    }
    
    func collectionView(heightForCustomContentIn collectionView:UICollectionView, indexPath:IndexPath) -> CGFloat
    {
//        let row = indexPath.row / itemsPerRow
//        let column = indexPath.row % itemsPerRow
        
        return 0//(modelArray[row][column]).customContentHeight
    }
}
