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
import MessageUI

/// Manages control flow of the score screen.
class ProfileViewController: UIViewController, MFMailComposeViewControllerDelegate {
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
        let alert = MDCAlertController(title: "Rules", message: "1. Posting threats, terrorism, harrassment, or stalking will not be allowed and may force law enforcement to be involved.\n\n2. Using names of individual people (non-public figures) is not allowed.\n\n3. Anonymity is a privilege, not a right. You can be banned at any time for any reason.")
        alert.backgroundColor = .systemBackground
        alert.titleColor = .label
        alert.messageColor = .label
        alert.addAction(MDCAlertAction(title: "Ok"))
        makePopup(alert: alert, image: "map.fill")
        self.present(alert, animated: true)
    }
    
    @IBAction func ContactButtonPressed(_ sender: Any) {
        let alert = MDCAlertController(title: "Contact", message: "Our email is teamgrapevineofficial@gmail.com and our Instagram is teamgrapevine.")
        alert.backgroundColor = .systemBackground
        alert.titleColor = .label
        alert.messageColor = .label
        alert.addAction(MDCAlertAction(title: "Cancel"))
        alert.addAction(MDCAlertAction(title: "Email") { (action) in
            let url = NSURL(string: "mailto:teamgrapevineofficial@gmail.com")
            UIApplication.shared.openURL(url! as URL)
        })
        alert.addAction(MDCAlertAction(title: "Instagram") { (action) in
            let appURL = URL(string: "instagram://user?username=teamgrapevine")!
            let application = UIApplication.shared
            if application.canOpenURL(appURL){
                application.open(appURL)
            } else {
                let webURL = URL(string: "https://instagram.com/teamgrapevine")!
                application.open(webURL)
            }
        })
        makePopup(alert: alert, image: "viewfinder.circle.fill")
        self.present(alert, animated: true)
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
    
    private func mailComposeController(controller: MFMailComposeViewController!, didFinishWithResult result: MFMailComposeResult, error: NSError!) {
        dismiss(animated: true, completion: nil)
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
