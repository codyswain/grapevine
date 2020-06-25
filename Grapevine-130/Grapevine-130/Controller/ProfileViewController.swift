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
        
    @IBOutlet weak var MyCommentsButton: UIButton!
    @IBOutlet weak var MyPostsButton: UIButton!
    @IBOutlet weak var MyKarmaButton: UIButton!
    
    /// Intializes the score screen.
    override func viewDidLoad() {
        super.viewDidLoad()
                
        // Add menu navigation bar programatically
        bottomNavBar = prepareBottomNavBar(sender: self, bottomNavBar: bottomNavBar, tab: "Me")
        self.view.addSubview(bottomNavBar)
        
        // Buttons
        self.view = styleButton(button: MyCommentsButton, view: self.view)
        self.view = styleButton(button: MyPostsButton, view: self.view)
        self.view = styleButton(button: MyKarmaButton, view: self.view)
    }
    
    @IBAction func KarmaButtonPressed(_ sender: Any) {
        self.performSegue(withIdentifier: "profileToKarma", sender: self)
    }
    
    @IBAction func PostsButtonPressed(_ sender: Any) {
    }
    
    @IBAction func CommentsButtonPressed(_ sender: Any) {
    }
}

extension ProfileViewController: MDCBottomNavigationBarDelegate {
    func bottomNavigationBar(_ bottomNavigationBar: MDCBottomNavigationBar, didSelect item: UITabBarItem) {
        if item.tag == 0 {
            bottomNavBar.selectedItem = bottomNavBar.items[0]
            self.performSegue(withIdentifier: "profileToPosts", sender: self)
        } else if item.tag == 1 {
            bottomNavBar.selectedItem = bottomNavBar.items[1]
            self.performSegue(withIdentifier: "profileToCreatePost", sender: self)
        } else {
            bottomNavBar.selectedItem = bottomNavBar.items[2]
        }
    }
}
