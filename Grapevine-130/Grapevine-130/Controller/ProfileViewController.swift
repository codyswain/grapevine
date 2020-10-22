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
    lazy var bottomNavBar: UITabBar = {
        let tab = UITabBar()
        self.view.addSubview(tab)
        tab.translatesAutoresizingMaskIntoConstraints = false
        tab.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        tab.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        tab.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true //This line will change in second part of this post.
        return tab
    }()
    
    // MARK: Properties
    @IBOutlet weak var DarkModeSwitch: UISwitch!
    @IBOutlet weak var DarkModeLabel: UILabel!
    
    @IBOutlet weak var MyKarmaButton: UIButton!
    @IBOutlet weak var MyCommentsButton: UIButton!
    @IBOutlet weak var MyPostsButton: UIButton!
    @IBOutlet weak var RulesButton: UIButton!
    @IBOutlet weak var ContactButton: UIButton!
    @IBOutlet weak var FeedbackButton: UIButton!
    
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
    @IBOutlet weak var feedbackWidth: NSLayoutConstraint!
    @IBOutlet weak var feedbackHeight: NSLayoutConstraint!
        
    @IBOutlet weak var YourGrapevineLabel: UILabel!
    @IBOutlet weak var leadingToKarmaConstraint: NSLayoutConstraint!
    @IBOutlet weak var leadingToCommentsConstraint: NSLayoutConstraint!
    @IBOutlet weak var leadingToContactConstraint: NSLayoutConstraint!
    /// Intializes the score screen.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the initial state of switch and text
        initializeTheme()
        
        // Add menu navigation bar programatically
        bottomNavBar = prepareBottomNavBar(sender: self, bottomNavBar: bottomNavBar, tab: "Me")
        self.view.addSubview(bottomNavBar)
        
        // size buttons
        resizeButtonsBasedOnPhoneSize()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        // Button styling
        self.view = styleButton(button: MyKarmaButton, view: self.view, color1: Constants.Colors.darkPurple!, color2: Constants.Colors.mediumPink)
        self.view = styleButton(button: MyPostsButton, view: self.view, color1: Constants.Colors.mediumPink, color2: Constants.Colors.darkPink)
        self.view = styleButton(button: MyCommentsButton, view: self.view, color1: Constants.Colors.mediumPink, color2: Constants.Colors.darkPink)
        self.view = styleButton(button: RulesButton, view: self.view, color1: Constants.Colors.darkPink, color2: Constants.Colors.yellow)
        self.view = styleButton(button: ContactButton, view: self.view, color1: Constants.Colors.darkPink, color2: Constants.Colors.yellow)
        self.view = styleButton(button: FeedbackButton, view: self.view, color1:  #colorLiteral(red: 0.9764705882, green: 0.5960784314, blue: 0.3647058824, alpha: 1), color2: Constants.Colors.yellow)
    }
    
    func resizeButtonsBasedOnPhoneSize(){
        let buttonWidths: [NSLayoutConstraint] = [self.karmaWidth, self.postsWidth, self.commentsWidth, self.rulesWidth, self.contactWidth, self.feedbackWidth]
        let buttonHeights: [NSLayoutConstraint] = [self.karmaHeight, self.postsHeight, self.commentsHeight, self.rulesHeight, self.contactHeight, self.feedbackHeight]
        
        let iPhoneSESize:CGFloat = 135
        let iPhoneXSize:CGFloat = 159
        let iPhone11Size:CGFloat = 179
        if UIDevice.current.deviceType == .iPhone11 || UIDevice.current.deviceType == .iPhones_6Plus_6sPlus_7Plus_8Plus || UIDevice.current.deviceType == .iPhone11ProMax{
            for w in buttonWidths { w.constant = iPhone11Size }
            for h in buttonHeights { h.constant = iPhone11Size }
        } else if UIDevice.current.deviceType == .iPhones_5_5s_5c_SE {
            for w in buttonWidths { w.constant = iPhoneSESize }
            for h in buttonHeights { h.constant = iPhoneSESize }
            YourGrapevineLabel.font = .systemFont(ofSize: 24, weight: .bold)
            MyKarmaButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
            MyPostsButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
            MyCommentsButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
            RulesButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
            ContactButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
            FeedbackButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
            leadingToKarmaConstraint.constant = 18
            leadingToContactConstraint.constant = 18
            leadingToCommentsConstraint.constant = 18

        } else {
            for w in buttonWidths { w.constant = iPhoneXSize }
            for h in buttonHeights { h.constant = iPhoneXSize }
        }
    }
    
    func initializeTheme() {
        let defaults = UserDefaults.standard
        if let curTheme = defaults.string(forKey: Globals.userDefaults.themeKey){
            if (curTheme == "dark") {
                DarkModeSwitch.setOn(true, animated: true)
                DarkModeLabel.text = "🌚"
                Globals.ViewSettings.backgroundColor = Constants.Colors.extremelyDarkGrey
                Globals.ViewSettings.labelColor = .white
                super.overrideUserInterfaceStyle = .dark
            } else {
                DarkModeSwitch.setOn(false, animated: true)
                DarkModeLabel.text = "🌝"
                Globals.ViewSettings.backgroundColor = .white
                Globals.ViewSettings.labelColor = .black
                super.overrideUserInterfaceStyle = .light
            }
        }
        else {
            DarkModeSwitch.setOn(false, animated: true)
            DarkModeLabel.text = "🌝"
            Globals.ViewSettings.backgroundColor = .white
            Globals.ViewSettings.labelColor = .black
            super.overrideUserInterfaceStyle = .light
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return setStatusBarStyle()
    }
    
    @IBAction func DarkModeSwitchPressed(_ sender: Any) {
        //Changes UI to dark or light mode
        if DarkModeSwitch.isOn{
            DarkModeLabel.text = "🌚"
            super.overrideUserInterfaceStyle = .dark
            Globals.ViewSettings.backgroundColor = Constants.Colors.extremelyDarkGrey
            Globals.ViewSettings.labelColor = .white
            let defaults = UserDefaults.standard
            defaults.set("dark", forKey: Globals.userDefaults.themeKey)
            UIView.animate(withDuration: 1.0) {
                super.setNeedsStatusBarAppearanceUpdate()
                self.bottomNavBar = bottomNavBarStyling(bottomNavBar: self.bottomNavBar)
            }
        }
        else{
            DarkModeLabel.text = "🌝"
            super.overrideUserInterfaceStyle = .light
            Globals.ViewSettings.backgroundColor = .white
            Globals.ViewSettings.labelColor = .black
            let defaults = UserDefaults.standard
            defaults.set("light", forKey: Globals.userDefaults.themeKey)
            UIView.animate(withDuration: 1.0) {
                super.setNeedsStatusBarAppearanceUpdate()
                self.bottomNavBar = bottomNavBarStyling(bottomNavBar: self.bottomNavBar)
            }
        }
    }
    
    @IBAction func KarmaButtonPressed(_ sender: Any) {
        self.performSegue(withIdentifier: "profileToKarma", sender: self)
    }
    
    @IBAction func PostsButtonPressed(_ sender: Any) {
        bottomNavBar.selectedItem = bottomNavBar.items?[2]
        self.performSegue(withIdentifier: "profileToMyPosts", sender: self)
    }
    
    @IBAction func CommentsButtonPressed(_ sender: Any) {
        bottomNavBar.selectedItem = bottomNavBar.items?[2]
        self.performSegue(withIdentifier: "profileToMyComments", sender: self)

    }
    
    @IBAction func RulesButtonPressed(_ sender: Any) {
        let alert = MDCAlertController(title: "Rules", message: "1. Posting bullying, threats, terrorism, harrassment, or stalking will not be allowed and may force law enforcement to be involved.\n\n2. Using names of individual people (non-public figures) is not allowed.\n\n3. Anonymity is a privilege, not a right. You can be banned at any time for any reason. \n\n4. You must be at least 18 years old.")
        alert.addAction(MDCAlertAction(title: "Ok"))
        makePopup(alert: alert, image: "map.fill")
        self.present(alert, animated: true)
    }
    
    @IBAction func ContactButtonPressed(_ sender: Any) {
        let alert = MDCAlertController(title: "Contact", message: "Our email is teamgrapevineofficial@gmail.com and our Instagram is teamgrapevine.")
        alert.addAction(MDCAlertAction(title: "Cancel"))
        alert.addAction(MDCAlertAction(title: "Email") { (action) in
            let url = NSURL(string: "mailto:teamgrapevineofficial@gmail.com")
            if UIApplication.shared.canOpenURL(url! as URL) {
                UIApplication.shared.open(url! as URL, completionHandler: nil)
            }
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
    
    @IBAction func FeedbackButtonPressed(_ sender: Any) {
        let alert = MDCAlertController(title: "Feedback", message: "We love to hear what you think about our app. If you'd like to give us some feeback, fill ou this google form.")
        alert.addAction(MDCAlertAction(title: "Cancel"))
        alert.addAction(MDCAlertAction(title: "Feedback") { (action) in
            let url = NSURL(string: "https://docs.google.com/forms/d/e/1FAIpQLSd57KPx9llPdMWau2WPkNvesaYJq6FPtmoKZuPiY-sudjw4Sg/viewform?usp=sf_link")
            if UIApplication.shared.canOpenURL(url! as URL) {
                UIApplication.shared.open(url! as URL, completionHandler: nil)
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

extension ProfileViewController: UITabBarDelegate {
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if item.tag == 0 {
            bottomNavBar.selectedItem = bottomNavBar.items?[0]
            self.performSegue(withIdentifier: "profileToPosts", sender: self)
        } else if item.tag == 1 {
            bottomNavBar.selectedItem = bottomNavBar.items?[2]
            self.performSegue(withIdentifier: "profileToCreatePost", sender: self)
        } else {
            bottomNavBar.selectedItem = bottomNavBar.items?[2]
        }
    }
}
