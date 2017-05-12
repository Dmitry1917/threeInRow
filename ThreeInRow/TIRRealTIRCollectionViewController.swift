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
    private var modelArray = [[TIRModelElement]]()
    private let itemsPerRow: Int = 3
    private let rowsCount: Int = 4
    
    private var selectedIndexPath: IndexPath?
    private var tapGesture: UITapGestureRecognizer?
    private var panGesture: UIPanGestureRecognizer?
    
    private var isAnimating: Bool = false
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        if let layout = collectionView.collectionViewLayout as? TIRRealTIRCollectionViewLayout
        {
            layout.delegate = self
        }
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView!.register(UINib(nibName: "TIRRealTIRCollectionViewCell", bundle : nil), forCellWithReuseIdentifier: reuseIdentifier)
        
        modelArray = (0..<rowsCount).map
        { (i) -> [TIRModelElement] in
            
            let rowContent: [TIRModelElement] = (0..<itemsPerRow).map
            { (j) -> TIRModelElement in
                
                let modelElement = TIRModelElement()
                
                let randomParameterRed = CGFloat(arc4random_uniform(255))
                let randomParameterGreen = CGFloat(arc4random_uniform(255))
                let randomParameterBlue = CGFloat(arc4random_uniform(255))
                modelElement.mainColor = UIColor(red: randomParameterRed / 255.0, green: randomParameterGreen / 255.0, blue: randomParameterBlue / 255.0, alpha: 1.0)
                modelElement.contentColor = UIColor.green
                modelElement.customContentHeight = CGFloat(arc4random_uniform(30))
                
                return modelElement
            }
            
            return rowContent
        }
        
        //print("\(modelArray)")
        
        installGestureDraggingRecognizer()
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
            collectionView.addGestureRecognizer(tapGesture!)
        }
        if panGesture == nil
        {
            let action = #selector(self.handleGesture(gesture:))
            panGesture = UIPanGestureRecognizer(target: self, action: action)
            collectionView.addGestureRecognizer(panGesture!)
        }
    }
    func handleGesture(gesture: UIGestureRecognizer)
    {
        let location = gesture.location(in:collectionView)
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
        guard let indexPath = collectionView.indexPathForItem(at:location) else { return }
        guard collectionView(collectionView, canMoveItemAt: indexPath) == true else { return }
        guard let cell = collectionView.cellForItem(at:indexPath) as? TIRRealTIRCollectionViewCell else { return }
        
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
                guard let selectedCell = collectionView.cellForItem(at:selectedIndexPath!) as? TIRRealTIRCollectionViewCell else { return }
                isAnimating = true
                selectedCell.hideBorder()
                self.collectionView(collectionView, moveItemAt: selectedIndexPath!, to: indexPath)
                
                collectionView.performBatchUpdates({
                    self.collectionView.moveItem(at: self.selectedIndexPath!, to: indexPath)
                    self.collectionView.moveItem(at: indexPath, to: self.selectedIndexPath!)
                    
                }, completion: {(finished) in
                    self.isAnimating = false
                    self.selectedIndexPath = nil
                })
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
        return itemsPerRow * rowsCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! TIRRealTIRCollectionViewCell
        
        // Configure the cell
        
        let row = indexPath.row / itemsPerRow
        let column = indexPath.row % itemsPerRow
        let modelElement = modelArray[row][column]
        //print("\(row) \(column)")
        cell.setMainColor(mainColor: modelElement.mainColor)
        cell.setContentColor(contentColor: modelElement.contentColor)
        
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
        let sourcedModelElement = modelArray[rowSource][columnSource]
        
        let rowDestination = destinationIndexPath.row / itemsPerRow
        let columnDestination = destinationIndexPath.row % itemsPerRow
        
        modelArray[rowSource][columnSource] = modelArray[rowDestination][columnDestination]
        modelArray[rowDestination][columnDestination] = sourcedModelElement
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
        let row = indexPath.row / itemsPerRow
        let column = indexPath.row % itemsPerRow
        
        return (modelArray[row][column]).customContentHeight
    }
}
