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

protocol GroupsViewControllerDelegate {
    func groupSelected(_ cell: UITableViewCell)
}

/// Manages control flow of the score screen.
class GroupsViewController: UIViewController {

    //MARK: Properties
    
    @IBOutlet weak var joinGroupButton: UIButton!
    @IBOutlet weak var creatGroupButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    var groups: [Group] = []
    var groupsManager = GroupsManager()
    var delegate: ViewControllerDelegate?
    
    // Define Refresher
    lazy var refresher: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = .label
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return refreshControl
    }()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return setStatusBarStyle()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Set dark/light mode
        setTheme(curView: self)
        
        //Set button styling
        creatGroupButton.layer.cornerRadius = 10
        joinGroupButton.layer.cornerRadius = 10
        
        //load the table
        tableView.dataSource = self
        tableView.refreshControl = refresher
        tableView.register(UINib(nibName: Constants.groupsCellNibName, bundle: nil), forCellReuseIdentifier: Constants.cellIdentifier)
        tableView.rowHeight = 50
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        
        //load the sample data
        loadSampleGroups()
        
    }
    

    @IBAction func createGroupButton(_ sender: Any) {
        print("DEBUGGING: Create group button pressed")
        let title = "New Group"
        let message = "You are about to create an anonymous group chat. Enter an interesting name for your group chat below"
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alert.addTextField { (textField) in
            textField.placeholder = "Group Name"
        }

        alert.addAction(UIAlertAction(title: "Submit", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0]
            print("Text field: \(String(describing: textField!.text))")
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        let attributedString1 = NSAttributedString(string: title, attributes: [
            NSAttributedString.Key.font : UIFont.systemFont(ofSize: 15), //your font here
            NSAttributedString.Key.foregroundColor : Globals.ViewSettings.labelColor
        ])
        let attributedString2 = NSAttributedString(string: message, attributes: [
            NSAttributedString.Key.font : UIFont.systemFont(ofSize: 12), //your font here
            NSAttributedString.Key.foregroundColor : Globals.ViewSettings.labelColor
        ])
        
        alert.view.subviews.first?.subviews.first?.subviews.first?.backgroundColor = Globals.ViewSettings.backgroundColor
        alert.view.tintColor = Globals.ViewSettings.labelColor
        alert.setValue(attributedString1, forKey: "attributedTitle")
        alert.setValue(attributedString2, forKey: "attributedMessage")
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
    @IBAction func joinGroupButton(_ sender: Any) {
        print("DEBUGGING: Join group button pressed")
    }
    
    @objc func refresh(){
        //refresh groups
        groupsManager.fetchGroups(userID: Constants.userID)
    }
    
    //MARK: Private Methods
     
    private func loadSampleGroups() {
        let group1 = Group(groupID: "testGroup1ID", groupName: "testGroup1aqzwsxedcrfvtgbyhnuybgtvfcrdxesedrcftvgybgtfcrdxesedrftvgybhungfdcrxessxedcrftvgybhunbgvfcdxsdcrftvgybhunbgvftxesxedrcftvgybhunijhbgvftcdrxsedcrftvgbyhunjinhbgvfcdxssexdrcftvgybhungfvtcdrxsedcrftvygbuhnbgfcdxsdrcftvgybhun", ownerID: "testOwnerId1")
        let group2 = Group(groupID: "testGroup2ID", groupName: "testGroup2", ownerID: "testOwnerId2")
        let group3 = Group(groupID: "testGroup2ID", groupName: "testGroup3", ownerID: "testOwnerId3")
        
        groups += [group1, group2, group3]
    }
    
}

extension GroupsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return groups.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier, for: indexPath) as! GroupTableViewCell
        
        let group = groups[indexPath.row]
        cell.groupLabel.text = group.groupName
        
        if group.ownerID == Constants.userID {
            cell.enableDelete()
        } else {
            cell.disableDelete()
        }
        
        return cell
    }
    
    
}

extension GroupsViewController: GroupsManagerDelegate {
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

extension GroupsViewController: GroupTableViewCellDelegate {
    /** Deletes a group.
    - Parameters:
       - cell: Group to be deleted. */
    func deleteCell(_ cell: UITableViewCell) {
        let alert = MDCAlertController(title: "Are you sure?", message: "Deleting a comment is permanent. The comment's score will still count towards your karma.")

        alert.addAction(MDCAlertAction(title: "Cancel"))
        alert.addAction(MDCAlertAction(title: "I'm Sure, Delete"){ (action) in
            let indexPath = self.tableView.indexPath(for: cell)!
            let row = indexPath.row
            let groupIDtoDelete = self.groups[row].groupID
//            self.groupsManager.deleteGroup(groupID: groupIDtoDelete)
            self.groups.remove(at: row)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
        })

        makePopup(alert: alert, image: "x.circle.fill")
        self.present(alert, animated: true)
    }
    
    func groupSelected(_ cell: UITableViewCell) {
        let indexPath = self.tableView.indexPath(for: cell)!
        let row = indexPath.row
        let groupName = self.groups[row].groupName
        let groupID = self.groups[row].groupID
        self.delegate?.setGroupView(groupName: groupName, groupID: groupID)
    }
}
