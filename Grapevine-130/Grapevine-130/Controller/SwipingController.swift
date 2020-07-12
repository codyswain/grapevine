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
        return setStatusBarStyle()
    }
    
    override func viewDidLoad(){
        super.viewDidLoad()
        
        //set dark/light mode
        if Globals.ViewSettings.currentMode == .dark {
            super.overrideUserInterfaceStyle = .dark
        }
        else if Globals.ViewSettings.currentMode == .light {
            super.overrideUserInterfaceStyle = .light
        }
        
        collectionView?.backgroundColor = .green
        
    }
}
