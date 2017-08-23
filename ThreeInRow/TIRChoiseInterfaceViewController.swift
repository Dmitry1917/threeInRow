//
//  TIRChoiseInterfaceViewController.swift
//  ThreeInRow
//
//  Created by DMITRY SINYOV on 10.05.17.
//  Copyright © 2017 DMITRY SINYOV. All rights reserved.
//

import UIKit

class TIRChoiseInterfaceViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        let nextController = segue.destination
        
        if nextController is TIRRealTIRCollectionViewController
        {
            print("TIRRealTIRCollectionViewController choosed")
            let model = TIRRealTIRModel()
            let presenter = TIRRealTIRPresenter(view: nextController as! TIRRealTIRCollectionViewController, model: model)
            
            (nextController as! TIRRealTIRCollectionViewController).presenter = presenter
        }
        if nextController is TIRVIPCollectionViewController
        {
            print("TIRVIPCollectionViewController choosed")
            let interactor = TIRVIPInteractor()
            let presenter = TIRVIPPresenter(view: nextController as! TIRVIPCollectionViewController)
            
            (nextController as! TIRVIPCollectionViewController).interactor = interactor
            interactor.presenter = presenter
        }
    }

    @IBAction func customReorderTaped(_ sender: Any)
    {
        self.performSegue(withIdentifier: "customReorder", sender: nil)
    }
    
    @IBAction func circularTaped(_ sender: Any)
    {
        self.performSegue(withIdentifier: "circular", sender: nil)
    }
    
    @IBAction func threeInRowTaped(_ sender: Any)
    {
        self.performSegue(withIdentifier: "realTIRVIP", sender: nil)//realTIRMVP
//        let viperView = TIRVIPERRouter.createTIRModule()
//        self.navigationController?.pushViewController(viperView, animated: true)
    }
}
