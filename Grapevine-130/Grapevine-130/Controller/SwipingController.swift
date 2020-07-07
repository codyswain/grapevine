//
//  SwipingController.swift
//  Grapevine-130
//
//  Created by Cody Swain on 4/18/20.
//  Copyright © 2020 Anthony Humay. All rights reserved.
//

import Foundation
import UIKit

class SwipingController: UICollectionViewController {
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        //Changes colors of status bar so it will be visible in dark or light mode
        if Globals.ViewSettings.CurrentMode == .dark {
            return .lightContent
        }
        else{
            return .darkContent
        }
    }
    
    override func viewDidLoad(){
        super.viewDidLoad()
        
        //set dark/light mode
        if Globals.ViewSettings.CurrentMode == .dark {
            super.overrideUserInterfaceStyle = .dark
        }
        else if Globals.ViewSettings.CurrentMode == .light {
            super.overrideUserInterfaceStyle = .light
        }
        
        collectionView?.backgroundColor = .green
        
    }
}
