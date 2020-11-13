//
//  ActivityViewController.swift
//  Grapevine
//
//  Created by Cody Swain on 11/12/20.
//  Copyright © 2020 Cody Swain. All rights reserved.
//

import Foundation
import UIKit
import MaterialComponents.MaterialBottomNavigation

class ActivityViewController: UIViewController {
    
    // MARK: Outlets
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: Variables
    var activities: [Activity] = []
    var activityManager = ActivityManager()
    

    // TODO: Reduce code-reuse by modularizing this.
    lazy var bottomNavBar: UITabBar = {
        let tab = UITabBar()
        self.view.addSubview(tab)
        tab.translatesAutoresizingMaskIntoConstraints = false
        tab.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        tab.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        tab.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true //This line will change in second part of this post.
        return tab
    }()
    
    // MARK: View Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        bottomNavBar = prepareBottomNavBar(sender: self, bottomNavBar: bottomNavBar, tab: "Me")
        self.view.addSubview(bottomNavBar)
        prepareTableView()
        
        // Retrieve test activities
        // This should print something to console
        activityManager.delegate = self
        activityManager.fetchTestActivities()
    }
    
    // TODO: Reduce code-reuse by modularizing this.
    func prepareTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UINib(nibName: Constants.activityCellNibName, bundle: nil), forCellReuseIdentifier: Constants.cellIdentifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 140
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 50, right: 0)
        tableView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
    }
}

// MARK: Tab Navigation
extension ActivityViewController: UITabBarDelegate {
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if item.tag == 0 {
            bottomNavBar.selectedItem = bottomNavBar.items?[0]
            self.performSegue(withIdentifier: "activityToPosts", sender: self)
        } else if item.tag == 1 {
            bottomNavBar.selectedItem = bottomNavBar.items?[1]
        } else {
            bottomNavBar.selectedItem = bottomNavBar.items?[2]
            self.performSegue(withIdentifier: "activityToProfile", sender: self)
        }
    }
}

extension ActivityViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return activities.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier, for: indexPath) as! ActivityTableViewCell
        
        let activityTitle = activities[indexPath.row].title
        let activityBody = activities[indexPath.row].body
        
        cell.activityTitleLabel.text = activityTitle
        cell.activityBodyLabel.text = activityBody
        
        // Enable cell communication with this view controller
        cell.delegate = self
        
        return cell
    }
}

// MARK: Activity Manager Delegate Handling
extension ActivityViewController: ActivityManagerDelegate {
    func didUpdateActivities(activities: [Activity]) {
        print("Properly fetched test activities: \(activities)")
        self.activities = activities
    }
}

// MARK: Individual Cell Delegate Handling
extension ActivityViewController: ActivityTableViewCellDelegate {
    
}
