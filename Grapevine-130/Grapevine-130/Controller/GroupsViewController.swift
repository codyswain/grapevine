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
    func setGroupsView(groupName: String, groupID: String)
}

/// Manages control flow of the score screen.
class GroupsViewController: UIViewController {

    //MARK: Properties
    
    @IBOutlet weak var joinGroupButton: UIButton!
    @IBOutlet weak var creatGroupButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    var groups: [Group] = []
    var selectedGroup = ""
    var groupsManager = GroupsManager()
    var delegate: GroupsViewControllerDelegate?
    
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
    
    //Dim background of ViewController so you can see top of this view
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        UIView.animate(withDuration: 0.5) {
            self.presentingViewController?.view.backgroundColor = .systemGray5
        }
    }
    
    //Un-dim background of ViewController when GroupsView is closed
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        UIView.animate(withDuration: 0.5) {
            self.presentingViewController?.view.backgroundColor = .systemBackground
        }
    }
    
    //MARK: View Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Set dark/light mode
        setTheme(curView: self)
        
        //Set button styling
        creatGroupButton.layer.cornerRadius = 10
        joinGroupButton.layer.cornerRadius = 10
        
        //load the table
        tableView.dataSource = self
        tableView.delegate = self
        tableView.refreshControl = refresher
        tableView.register(UINib(nibName: Constants.groupsCellNibName, bundle: nil), forCellReuseIdentifier: Constants.cellIdentifier)
        tableView.rowHeight = 50
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        
        //Grapevine is the default group
        let grapevine = Group(id: "Grapevine", name: "Grapevine", ownerID: "Grapevine")
        groups += [grapevine]
        
        //load the sample data
        loadSampleGroups()
        
        groupsManager.delegate = self
    }
    
    //MARK: Utility Methods
    
    //Creates and Presentat a popup that takes user input
    func showAlertWithInput(title: String, message: String, placeholder: String, completion: @escaping (_ text: String?) -> Void ) {
        
        var inputText = ""
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        setTheme(curView: alert)
        alert.addTextField(configurationHandler: { (textField) -> Void in textField.placeholder = placeholder})
        alert.addAction(UIAlertAction(title: "Submit", style: .default, handler: { (action) -> Void in
            let textOfTask = alert.textFields![0] as UITextField
            inputText = textOfTask.text!
            completion(inputText)
        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            completion(nil)
        }))
        
        let attributedString1 = NSAttributedString(string: title, attributes: [
            NSAttributedString.Key.font : UIFont.systemFont(ofSize: 15), //your font here
            NSAttributedString.Key.foregroundColor : Globals.ViewSettings.labelColor
        ])
        let attributedString2 = NSAttributedString(string: message, attributes: [
            NSAttributedString.Key.font : UIFont.systemFont(ofSize: 12), //your font here
            NSAttributedString.Key.foregroundColor : Globals.ViewSettings.labelColor
        ])
        alert.setValue(attributedString1, forKey: "attributedTitle")
        alert.setValue(attributedString2, forKey: "attributedMessage")
        
        self.present(alert, animated: true, completion: nil)
    }
    
    //MARK: Cell Interaction Methods

    @IBAction func createGroupButton(_ sender: Any) {
        print("DEBUGGING: Create group button pressed")
        var newGroupName = ""
        showAlertWithInput(title: "New Group", message: "You are about to create an anonymous group chat. Enter an interesting name for your group chat below", placeholder: "Group Name") { (text) in
            // handle completion result
            if let inputText = text {
                newGroupName = inputText
                print("New Group Name: ", newGroupName)
                //dont let them name their group grapevine
                if newGroupName.trimmingCharacters(in: .whitespacesAndNewlines).caseInsensitiveCompare("Grapevine") == ComparisonResult.orderedSame {
                    let alert = MDCAlertController(title: "Invalid Group Name", message: "Grapevine is our name. You can't use that.")
                    alert.addAction(MDCAlertAction(title: "Ok"))
                    makePopup(alert: alert, image: "Grapes")
                    self.present(alert, animated: true)
                }
                // Maybe to do: check valid group names
                self.groupsManager.createGroup(groupName: newGroupName, ownerID: Constants.userID)
                //TO DO: Send new group to database
            }
        }
    }
    
    
    @IBAction func joinGroupButton(_ sender: Any) {
        print("DEBUGGING: Join group button pressed")
        var groupCode = ""
        showAlertWithInput(title: "Join Group", message: "Enter your one-time group code to join an anonymous group", placeholder: "Group code") { (text) in
            // handle completion result
            if let inputText = text {
                groupCode = inputText
                print("Group Code: ", groupCode)
                
                //TO DO: Check database for group with join code matching input and authprize user
                self.groupsManager.joinGroup(key: groupCode, userID: Constants.userID)
                
                //TO DO: If Authorized, add group to My Groups Table
                
            }
        }
    }
    
    @objc func refresh(){
        //refresh groups
        groupsManager.fetchGroups(userID: Constants.userID)
    }
    
    //MARK: Private Methods
     
    private func loadSampleGroups() {
        let group1 = Group(id: "testGroup1ID", name: "testGroup1aqzwsxedcrfvtgbyhnuybgtvfcrdxesedrcftvgybgtfcrdxesedrftvgybhungfdcrxessxedcrftvgybhunbgvfcdxsdcrftvgybhunbgvftxesxedrcftvgybhunijhbgvftcdrxsedcrftvgbyhunjinhbgvfcdxssexdrcftvgybhungfvtcdrxsedcrftvygbuhnbgfcdxsdrcftvgybhun", ownerID: "testOwnerId1")
        let group2 = Group(id: "testGroup2ID", name: "testGroup2", ownerID: "testOwnerId2")
        let group3 = Group(id: "testGroup2ID", name: "testGroup3", ownerID: "testOwnerId3")
        
        groups += [group1, group2, group3]
    }
    
}

//MARK: Table View Control

extension GroupsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return groups.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            let row = indexPath.row
            let groupName = self.groups[row].name
            self.selectedGroup = groupName
            let groupID = self.groups[row].id
            self.delegate?.setGroupsView(groupName: groupName, groupID: groupID)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier, for: indexPath) as! GroupTableViewCell
        
        let group = groups[indexPath.row]
        cell.groupLabel.text = group.name
        
        if group.ownerID == Constants.userID {
            cell.enableDelete()
        } else {
            cell.disableDelete()
        }
        
        if group.name == self.selectedGroup {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: UITableView.ScrollPosition.middle)
        }
        
        return cell
    }
    
    
}

//MARK: Delegate Extensions

extension GroupsViewController: GroupsManagerDelegate {
    func didCreateGroup() {
        print("Created group")
    }
    
    func didFailWithError(error: Error) {
        print(error)
    }
    
    func didUpdateGroups(_ groupManager: GroupsManager, groups: [Group]) {
        print("UPDATE")
        DispatchQueue.main.async {
            self.refresher.endRefreshing()
        }
    }
    
    func didJoinGroup(){
        
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
    //Deletes group from the table and calls function in groupsManager to delete group from database
    func deleteCell(_ cell: UITableViewCell) {
        let alert = MDCAlertController(title: "Are you sure?", message: "Deleting a comment is permanent. The comment's score will still count towards your karma.")

        alert.addAction(MDCAlertAction(title: "Cancel"))
        alert.addAction(MDCAlertAction(title: "I'm Sure, Delete"){ (action) in
            let indexPath = self.tableView.indexPath(for: cell)!
            let row = indexPath.row
            let groupIDtoDelete = self.groups[row].id
//            self.groupsManager.deleteGroup(groupID: groupIDtoDelete)
            self.groups.remove(at: row)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
        })

        makePopup(alert: alert, image: "x.circle.fill")
        self.present(alert, animated: true)
    }
}

//MARK: Utility Extensions

extension UIView {
    func traverseRadius(_ radius: Float) {
        layer.cornerRadius = CGFloat(radius)

        for subview: UIView in subviews {
            subview.traverseRadius(radius)
        }
    }
}
