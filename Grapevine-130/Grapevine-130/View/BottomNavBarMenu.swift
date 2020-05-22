//
//  BottomNavBarMenu.swift
//  Grapevine-130
//
//  Created by Anthony Humay on 5/15/20.
//  Copyright © 2020 Anthony Humay. All rights reserved.
//

import Foundation
import UIKit
import MaterialComponents.MaterialBottomNavigation
import MaterialComponents.MaterialButtons
import MaterialComponents.MaterialButtons_Theming

func prepareBottomNavBar(sender: UIViewController, bottomNavBar: MDCBottomNavigationBar, tab: String) -> MDCBottomNavigationBar {
    var bottomNavBarFrame = CGRect(x: 0, y: sender.view.frame.height - 80, width: sender.view.frame.width, height: 80)
    
    // Extend the Bottom Navigation to the bottom of the screen.
    if #available(iOS 11.0, *) {
        bottomNavBarFrame.size.height += sender.view.safeAreaInsets.bottom
        bottomNavBarFrame.origin.y -= sender.view.safeAreaInsets.bottom
    }
    bottomNavBar.frame = bottomNavBarFrame
    
    // Potential other images: pencil.and.outline, doc.append, quote.bubble, scribble
//    let postTab = UITabBarItem(title: "Posts", image: UIImage(systemName: "scribble"), tag: 0)
    let postTab = UITabBarItem(title: "", image: UIImage(systemName: "line.horizontal.3.decrease.circle.fill"), tag: 0)
//    let karmaTab = UITabBarItem(title: "Karma", image: UIImage(systemName: "k.circle.fill"), tag: 1)
    let karmaTab = UITabBarItem(title: "", image: UIImage(systemName: "k.circle.fill"), tag: 1)
    let createTab = UITabBarItem(title: "", image:UIImage(systemName: "plus.circle"), tag: 2)
//    let chatTab = UITabBarItem(title: "Chat", image:UIImage(systemName: "scribble"), tag: 4)
    let chatTab = UITabBarItem(title: "", image:UIImage(systemName: "message.circle.fill"), tag: 3)
//    let meTab = UITabBarItem(title: "Me", image: UIImage(systemName: "person.circle.fill"), tag: 5)
    let meTab = UITabBarItem(title: "", image: UIImage(systemName: "person.circle.fill"), tag: 4)

    bottomNavBar.items = [postTab, karmaTab, createTab, chatTab, meTab]
    
    if tab == "Posts" {
        bottomNavBar.selectedItem = postTab
    } else if tab == "Karma" {
        bottomNavBar.selectedItem = karmaTab
    } else if (tab == ""){
        // Never actually change to this selection
    } else if (tab == "chatTab"){
       //
    } else {
        bottomNavBar.selectedItem = meTab
    }
    
    bottomNavBar.delegate = (sender as! MDCBottomNavigationBarDelegate)
    
    return bottomNavBarStyling(bottomNavBar: bottomNavBar)
}

func bottomNavBarStyling(bottomNavBar: MDCBottomNavigationBar) -> MDCBottomNavigationBar {
    bottomNavBar.itemTitleFont = UIFont.boldSystemFont(ofSize: 40)
    bottomNavBar.itemsContentVerticalMargin = 5
    bottomNavBar.backgroundColor = UIColor(white: 1, alpha: 0.97)
    // Ripple effect: this doesn't turn it off for whatever reason
    bottomNavBar.enableRippleBehavior = false
    return bottomNavBar
}
