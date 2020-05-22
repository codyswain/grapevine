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
        if item.tag == 0 {
            bottomNavBar.selectedItem = bottomNavBar.items[0]
            self.performSegue(withIdentifier: "profileToPosts", sender: self)
        } else if item.tag == 1 {
            bottomNavBar.selectedItem = bottomNavBar.items[1]
            self.performSegue(withIdentifier: "profileToKarma", sender: self)
        } else if item.tag == 2 {
            bottomNavBar.selectedItem = bottomNavBar.items[4]
            self.performSegue(withIdentifier: "profileToCreatePost", sender: self)
        } else if item.tag == 3 {
            bottomNavBar.selectedItem = bottomNavBar.items[3]
        } else if item.tag == 4 {
            bottomNavBar.selectedItem = bottomNavBar.items[4]
        }
    }
}
