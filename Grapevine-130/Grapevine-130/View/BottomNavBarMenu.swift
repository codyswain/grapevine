//
//  BottomNavBarMenu.swift
//  Grapevine-130
//
//  Created by Anthony Humay on 5/15/20.
//  Copyright © 2020 Anthony Humay. All rights reserved.
//

import Foundation
import UIKit
//import MaterialComponents.MaterialBottomNavigation
//import MaterialComponents.MaterialButtons
//import MaterialComponents.MaterialButtons_Theming

func prepareBottomNavBar(sender: UIViewController, bottomNavBar: UITabBar, tab: String) -> UITabBar {
    let navBarHeight = UITabBarController().tabBar.frame.size.height ///need for different iphone sizes
    print(navBarHeight)
    let bottomNavBarFrame = CGRect(x: 0, y:sender.view.frame.height - navBarHeight, width: sender.view.frame.width, height: navBarHeight)
    bottomNavBar.frame = bottomNavBarFrame
    if let curTheme = UserDefaults.standard.string(forKey: Globals.userDefaults.themeKey){
        if (curTheme == "dark") {
            bottomNavBar.unselectedItemTintColor = UIColor.systemGray5
            bottomNavBar.tintColor = UIColor.systemGray2

        } else {
            bottomNavBar.unselectedItemTintColor = Constants.Colors.veryDarkGrey
            bottomNavBar.tintColor = .black

        }
    }

    let postTab = UITabBarItem(title: "", image: UIImage(systemName: "house.fill"), tag: 0)
    let createTab = UITabBarItem(title: "", image:UIImage(named: "newPostButton")?.withRenderingMode(.alwaysOriginal), tag: 1)
    let meTab = UITabBarItem(title: "", image: UIImage(systemName: "person.crop.circle.fill"), tag: 2) // old icon: person.circle.fill
    bottomNavBar.items = [postTab, createTab, meTab]
    if (tab == "Posts") {
        bottomNavBar.selectedItem = postTab
    } else if (tab == "") {
        // Tab bar hidden for this page...
        // So there is no highlighted icon
    } else {
        bottomNavBar.selectedItem = meTab
    }
    bottomNavBar.delegate = (sender as! UITabBarDelegate)
    return bottomNavBarStyling(bottomNavBar: bottomNavBar)
}

func bottomNavBarStyling(bottomNavBar: UITabBar) -> UITabBar {
    bottomNavBar.backgroundColor = UIColor.systemBackground.withAlphaComponent(1)
    bottomNavBar.isTranslucent = false
    let topBorder = CALayer()
    topBorder.frame = CGRect(x: 0.0, y: -2, width: bottomNavBar.frame.size.width, height: 2)
    bottomNavBar.layer.addSublayer(topBorder)
    topBorder.backgroundColor = Constants.Colors.darkPurple.cgColor

    return bottomNavBar
}


//func prepareBottomNavBar(sender: UIViewController, bottomNavBar: MDCBottomNavigationBar, tab: String) -> MDCBottomNavigationBar {
//    var bottomNavBarFrame = CGRect(x: 0, y: sender.view.frame.height - 80, width: sender.view.frame.width, height: 80)
//
//    // Extend the Bottom Navigation to the bottom of the screen.
//    // TODO: Clean this commented code up
//    // THIS CAUSED NAVBAR TO SHIFT WEIRDLY MAYBE OKAY TO DELETE
////    if #available(iOS 11.0, *) {
////        bottomNavBarFrame.size.height += sender.view.safeAreaInsets.bottom
////        bottomNavBarFrame.origin.y -= sender.view.safeAreaInsets.bottom
////    }
//    bottomNavBar.frame = bottomNavBarFrame
//    bottomNavBar.unselectedItemTintColor = UIColor.systemGray5
//    bottomNavBar.selectedItemTintColor = UIColor.systemGray2
//    if let curTheme = UserDefaults.standard.string(forKey: Globals.userDefaults.themeKey){
//        if (curTheme == "dark") {
//            bottomNavBar.unselectedItemTintColor = UIColor.systemGray5
//            bottomNavBar.selectedItemTintColor = UIColor.systemGray2
//            purpleShade = Constants.Colors.darkPurple
//
//        } else {
//            bottomNavBar.unselectedItemTintColor = Constants.Colors.veryDarkGrey
//            bottomNavBar.selectedItemTintColor = .black
//            purpleShade = Constants.Colors.lightPurple
//
//        }
//    }
//
//    let postTab = UITabBarItem(title: "", image: UIImage(systemName: "house.fill"), tag: 0)
//    let createTab = UITabBarItem(title: "", image:UIImage(named: "newPostButton"), tag: 1)
//    let meTab = UITabBarItem(title: "", image: UIImage(systemName: "person.crop.circle.fill"), tag: 2) // old icon: person.circle.fill
//    bottomNavBar.items = [postTab, createTab, meTab]
//    if (tab == "Posts") {
//        bottomNavBar.selectedItem = postTab
//    } else if (tab == "") {
//        // Tab bar hidden for this page...
//        // So there is no highlighted icon
//    } else {
//        bottomNavBar.selectedItem = meTab
//    }
//    bottomNavBar.delegate = (sender as! MDCBottomNavigationBarDelegate)
//    return bottomNavBarStyling(bottomNavBar: bottomNavBar)
//}
//
//func bottomNavBarStyling(bottomNavBar: MDCBottomNavigationBar) -> MDCBottomNavigationBar {
//    bottomNavBar.itemTitleFont = UIFont.boldSystemFont(ofSize: 40)
//    bottomNavBar.itemsContentVerticalMargin = 5
//    bottomNavBar.backgroundColor = UIColor.systemBackground.withAlphaComponent(1)
//    bottomNavBar.items[1].c
//
//    // Ripple effect: this doesn't turn it off for whatever reason
//    bottomNavBar.enableRippleBehavior = false
//    return bottomNavBar
//}
