//
//  ProfileViewController.swift
//  Grapevine-130
//
//  Created by Anthony Humay on 5/15/20.
//  Copyright © 2020 Anthony Humay. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import MaterialComponents.MaterialBottomNavigation

/// Manages control flow of the score screen.
class ProfileViewController: UIViewController {
    var bottomNavBar = MDCBottomNavigationBar()
        
    /// Intializes the score screen.
    override func viewDidLoad() {
        super.viewDidLoad()
                
        // Add menu navigation bar programatically
        bottomNavBar = prepareBottomNavBar(sender: self, bottomNavBar: bottomNavBar, tab: "Me")
        self.view.addSubview(bottomNavBar)
    }
}

extension ProfileViewController: MDCBottomNavigationBarDelegate {
    func bottomNavigationBar(_ bottomNavigationBar: MDCBottomNavigationBar, didSelect item: UITabBarItem) {
        if item.title! == "Posts" {
            self.performSegue(withIdentifier: "profileToPosts", sender: self)
        } else if item.title! == "Karma" {
            self.performSegue(withIdentifier: "profileToKarma", sender: self)
        } else if item.title! == "Me" {
            
        }
    }
}
