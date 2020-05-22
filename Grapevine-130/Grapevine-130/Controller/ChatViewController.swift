//  ChatViewController.swift
//  Grapevine-130
//
//  Created by Cody Swain on 5/22/20.
//  Copyright © 2020 Cody Swain. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import MaterialComponents.MaterialBottomNavigation

/// Manages control flow of the score screen.
class ChatViewController: UIViewController {
    var bottomNavBar = MDCBottomNavigationBar()
        
    /// Intializes the score screen.
    override func viewDidLoad() {
        super.viewDidLoad()
                
        // Add menu navigation bar programatically
        bottomNavBar = prepareBottomNavBar(sender: self, bottomNavBar: bottomNavBar, tab: "Chat")
        self.view.addSubview(bottomNavBar)
    }
}

extension ChatViewController: MDCBottomNavigationBarDelegate {
    func bottomNavigationBar(_ bottomNavigationBar: MDCBottomNavigationBar, didSelect item: UITabBarItem) {
        if item.tag == 0 {
            bottomNavBar.selectedItem = bottomNavBar.items[0]
            self.performSegue(withIdentifier: "chatToPosts", sender: self)
        } else if item.tag == 1 {
            bottomNavBar.selectedItem = bottomNavBar.items[1]
            self.performSegue(withIdentifier: "chatToKarma", sender: self)
        } else if item.tag == 2 {
            bottomNavBar.selectedItem = bottomNavBar.items[3]
            self.performSegue(withIdentifier: "chatToCreatePost", sender: self)
        } else if item.tag == 3 {
            bottomNavBar.selectedItem = bottomNavBar.items[3]
        } else if item.tag == 4 {
            bottomNavBar.selectedItem = bottomNavBar.items[4]
            self.performSegue(withIdentifier: "chatToProfile", sender: self)
        }
    }
}
