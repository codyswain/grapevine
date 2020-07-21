//
//  ProfileViewController.swift
//  Grapevine-130
//
//  Created by Cody Swain, Kelsey Lieberman on 5/15/20.
//  Copyright © 2020 Cody Swain, Kelsey Lieberman. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import MaterialComponents.MaterialBottomNavigation
import MessageUI

/// Manages control flow of the score screen.
class GroupsViewController: UIViewController {
    

    //MARK: Properties
    
    @IBOutlet weak var tableView: UITableView!
    var groups: [Group] = []
    var groupsManager = GroupsManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    

    @IBAction func createGroupButton(_ sender: Any) {
        print("DEBUGGING: Create group button pressed")
    }
    
    
    @IBAction func joinGroupButton(_ sender: Any) {
        print("DEBUGGING: Join group button pressed")
    }
    
    //MARK: Private Methods
     
    private func loadSampleGroups() {
        
    }
    
}

extension GroupsViewController: GroupsManagerDelegate{
    func didFailWithError(error: Error) {
        print(error)
    }
    
    func didUpdateGroups(_ groupManager: GroupsManager, groups: [Group]) {
        print("To Do")
    }
    
    func didCreateGroup() {
        print("To Do")
    }
    
    
    /// Fires when groups are fetched
    /// TO-DO: load this data into groups table
    func didUpdateGroups(groups: [Group]) {
        print(groups)
    }
    
    /// Fires when a user creates a group
    /// TO-DO: segue to feed and load in group
    func didCreateGroup(groupID: String, groupName: String) {
        print(groupID)
        print(groupName)
    }
}
