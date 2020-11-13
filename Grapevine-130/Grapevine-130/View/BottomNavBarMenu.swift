//
//  BottomNavBarMenu.swift
//  Grapevine
//
//  Created by Anthony Humay on 5/15/20.
//  Modified by Cody Swain, Kelsey Lieberman.
//  Copyright © 2020 Grapevine. All rights reserved.

import Foundation
import UIKit

func prepareBottomNavBar(sender: UIViewController, bottomNavBar: UITabBar, tab: String) -> UITabBar {
    
    // Support different device sizes
    let navBarHeight = UITabBarController().tabBar.frame.size.height
    
    let bottomNavBarFrame = CGRect(
        x: 0,
        y:sender.view.frame.height - navBarHeight,
        width: sender.view.frame.width,
        height: navBarHeight)
    bottomNavBar.frame = bottomNavBarFrame

    let postTab = UITabBarItem(
        title: "",
        image: UIImage(systemName: "house.fill"),
        tag: 0)
//    let createTab = UITabBarItem(
//        title: "",
//        image:UIImage(named: "newPostButton")?.withRenderingMode(.alwaysOriginal).withTintColor(UIColor(named: "GrapevinePurple")!),
//        tag: 1)
    let notificationTab = UITabBarItem(
        title: "",
        image: UIImage(systemName: "bell.fill"),
        tag: 1)
    let meTab = UITabBarItem(
        title: "",
        image: UIImage(systemName: "person.crop.circle.fill"),
        tag: 2)
    bottomNavBar.items = [postTab, notificationTab, meTab]
    
    if (tab == "Posts") {
        bottomNavBar.selectedItem = postTab
    } else if (tab == "Activity"){
        bottomNavBar.selectedItem = notificationTab
    } else if (tab == "Profile"){
        bottomNavBar.selectedItem = meTab
    }
    
    bottomNavBar.delegate = (sender as! UITabBarDelegate)
    return bottomNavBarStyling(bottomNavBar: bottomNavBar)
}

func bottomNavBarStyling(bottomNavBar: UITabBar) -> UITabBar {
    bottomNavBar.backgroundColor = .none
    bottomNavBar.isTranslucent = false
    
    if let curTheme = UserDefaults.standard.string(forKey: Globals.userDefaults.themeKey){
        if (curTheme == "dark") {
            bottomNavBar.unselectedItemTintColor = UIColor.systemGray5
            bottomNavBar.tintColor = UIColor.systemGray2
        } else {
            bottomNavBar.unselectedItemTintColor = Constants.Colors.veryDarkGrey
            bottomNavBar.tintColor = .black
        }
    } else {
        bottomNavBar.unselectedItemTintColor = Constants.Colors.veryDarkGrey
        bottomNavBar.tintColor = .black
    }
    return bottomNavBar
}
