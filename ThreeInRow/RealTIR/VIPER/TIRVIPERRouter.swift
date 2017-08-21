//
//  TIRVIPERRouter.swift
//  ThreeInRow
//
//  Created by DMITRY SINYOV on 21.08.17.
//  Copyright © 2017 DMITRY SINYOV. All rights reserved.
//

import UIKit

protocol TIRVIPERRouterProtocol {
    static func createTIRModule() -> UIViewController
}

class TIRVIPERRouter: TIRVIPERRouterProtocol {
    static func createTIRModule() -> UIViewController {
        
        let storyboard = UIStoryboard(name: "TIRVIPERView", bundle: Bundle.main)
        
        let view = storyboard.instantiateViewController(withIdentifier: "TIRVIPERView") as! TIRVIPERView
        let interactor = TIRVIPERInteractor()
        let presenter = TIRVIPERPresenter(view: view, interactor: interactor)
        
        view.presenter = presenter
        
        return view
    }
}
