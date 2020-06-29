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
    
    @IBOutlet weak var MyKarmaButton: UIButton!
    @IBOutlet weak var MyCommentsButton: UIButton!
    @IBOutlet weak var MyPostsButton: UIButton!
    @IBOutlet weak var RulesButton: UIButton!
    @IBOutlet weak var ContactButton: UIButton!
    
    @IBOutlet weak var karmaWidth: NSLayoutConstraint!
    @IBOutlet weak var karmaHeight: NSLayoutConstraint!
    @IBOutlet weak var postsHeight: NSLayoutConstraint!
    @IBOutlet weak var postsWidth: NSLayoutConstraint!
    @IBOutlet weak var commentsHeight: NSLayoutConstraint!
    @IBOutlet weak var commentsWidth: NSLayoutConstraint!
    @IBOutlet weak var rulesWidth: NSLayoutConstraint!
    @IBOutlet weak var rulesHeight: NSLayoutConstraint!
    @IBOutlet weak var contactWidth: NSLayoutConstraint!
    @IBOutlet weak var contactHeight: NSLayoutConstraint!

    /// Intializes the score screen.
    override func viewDidLoad() {
        super.viewDidLoad()

        // Add menu navigation bar programatically
        bottomNavBar = prepareBottomNavBar(sender: self, bottomNavBar: bottomNavBar, tab: "Me")
        self.view.addSubview(bottomNavBar)
        
        // size buttons
        resizeButtonsBasedOnPhoneSize()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Button styling
        self.view = styleButton(button: MyKarmaButton, view: self.view, color1: Constants.Colors.darkPurple, color2: Constants.Colors.mediumPink)
        self.view = styleButton(button: MyPostsButton, view: self.view, color1: Constants.Colors.mediumPink, color2: Constants.Colors.darkPink)
        self.view = styleButton(button: MyCommentsButton, view: self.view, color1: Constants.Colors.mediumPink, color2: Constants.Colors.darkPink)
        self.view = styleButton(button: RulesButton, view: self.view, color1: Constants.Colors.darkPink, color2: Constants.Colors.yellow)
        self.view = styleButton(button: ContactButton, view: self.view, color1: Constants.Colors.darkPink, color2: Constants.Colors.yellow)
    }
    
    func resizeButtonsBasedOnPhoneSize(){
        let buttonWidths: [NSLayoutConstraint] = [self.karmaWidth, self.postsWidth, self.commentsWidth, self.rulesWidth, self.contactWidth]
        let buttonHeights: [NSLayoutConstraint] = [self.karmaHeight, self.postsHeight, self.commentsHeight, self.rulesHeight, self.contactHeight]

        let iPhoneXSize:CGFloat = 159
        let iPhone11Size:CGFloat = 179
        if UIDevice.current.deviceType == .iPhone11 || UIDevice.current.deviceType == .iPhones_6Plus_6sPlus_7Plus_8Plus {
            for w in buttonWidths { w.constant = iPhone11Size }
            for h in buttonHeights { h.constant = iPhone11Size }
        } else {
            for w in buttonWidths { w.constant = iPhoneXSize }
            for h in buttonHeights { h.constant = iPhoneXSize }
        }
    }
    
    @IBAction func KarmaButtonPressed(_ sender: Any) {
        self.performSegue(withIdentifier: "profileToKarma", sender: self)
    }
    
    @IBAction func PostsButtonPressed(_ sender: Any) {
        bottomNavBar.selectedItem = bottomNavBar.items[2]
        self.performSegue(withIdentifier: "profileToMyPosts", sender: self)
    }
    
    @IBAction func CommentsButtonPressed(_ sender: Any) {
        bottomNavBar.selectedItem = bottomNavBar.items[2]
        self.performSegue(withIdentifier: "profileToMyComments", sender: self)

    }
    
    @IBAction func RulesButtonPressed(_ sender: Any) {
    }
    
    @IBAction func ContactButtonPressed(_ sender: Any) {
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "profileToMyPosts" {
            let destinationVC = segue.destination as! ViewController
            destinationVC.currentMode = "myPosts"
        }
        if segue.identifier == "profileToMyComments" {
            let destinationVC = segue.destination as! ViewController
            destinationVC.currentMode = "myComments"
        }
    }

}

extension ProfileViewController: MDCBottomNavigationBarDelegate {
    func bottomNavigationBar(_ bottomNavigationBar: MDCBottomNavigationBar, didSelect item: UITabBarItem) {
        if item.tag == 0 {
            bottomNavBar.selectedItem = bottomNavBar.items[0]
            self.performSegue(withIdentifier: "profileToPosts", sender: self)
        } else if item.tag == 1 {
            bottomNavBar.selectedItem = bottomNavBar.items[2]
            self.performSegue(withIdentifier: "profileToCreatePost", sender: self)
        } else {
            bottomNavBar.selectedItem = bottomNavBar.items[2]
        }
    }
}
