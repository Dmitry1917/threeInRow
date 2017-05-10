//
//  TIRCirlularCollectionViewController2.swift
//  ThreeInRow
//
//  Created by DMITRY SINYOV on 10.05.17.
//  Copyright © 2017 DMITRY SINYOV. All rights reserved.
//

import UIKit

private let reuseIdentifier = "cellID"

class TIRCirlularCollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, TIRCircularCollectionViewLayoutProtocol {

    @IBOutlet weak var mainCollectionView: UICollectionView!
    
    fileprivate var modelArray = [TIRModelElement]()
    fileprivate var itemsCount = 10
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        if let layout = mainCollectionView.collectionViewLayout as? TIRCircularCollectionViewLayout
        {
            layout.delegate = self
        }
        
        self.mainCollectionView.delegate = self
        self.mainCollectionView.dataSource = self
        self.mainCollectionView!.register(UINib(nibName: "TIRCollectionViewCell", bundle : nil), forCellWithReuseIdentifier: reuseIdentifier)
        
        // Do any additional setup after loading the view.
        
        modelArray = Array(repeatElement(TIRModelElement(), count: itemsCount))
        
        for index in 0..<itemsCount
        {
            let modelElement = TIRModelElement()
            
            let randomParameterRed = CGFloat(arc4random_uniform(255))
            let randomParameterGreen = CGFloat(arc4random_uniform(255))
            let randomParameterBlue = CGFloat(arc4random_uniform(255))
            modelElement.mainColor = UIColor(red: randomParameterRed / 255.0, green: randomParameterGreen / 255.0, blue: randomParameterBlue / 255.0, alpha: 1.0)
            modelElement.contentColor = UIColor.green
            modelElement.customContentHeight = CGFloat(arc4random_uniform(50))
            
            modelArray[index] = modelElement
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return itemsCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! TIRCollectionViewCell
        
        let modelElement = modelArray[indexPath.row]
        cell.backgroundColor = modelElement.mainColor
        cell.someContentView.backgroundColor = modelElement.contentColor
        
        return cell
    }
    
    //MARK: TIRCircularCollectionViewLayoutProtocol
    func collectionView(heightForCustomContentIn collectionView:UICollectionView, indexPath:IndexPath) -> CGFloat
    {
        return (modelArray[indexPath.row]).customContentHeight
    }
}
