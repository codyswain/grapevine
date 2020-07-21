//
//  CommentsManager.swift
//  Grapevine-130
//
//  Created by Cody Swain, Kelsey Lieberman on July 20th.
//  Copyright © 2020 Cody Swain, Kelsey Lieberman. All rights reserved.
//

import Foundation

protocol GroupsManagerDelegate {
    func didFailWithError(error: Error)
    
    // TO-DO: why is GroupsManager passed back  in here? Can it be removed?
    func didUpdateGroups(_ groupManager: GroupsManager, groups: [Group])
    
    // TO-DO: pass back groupID and groupName
    // then pop it into the table, so you don't have to re-query posts
    func didCreateGroup()
}

struct GroupsManager {
    let fetchGroupsURL = Constants.serverURL + "groups/?"
    let createGroupURL = Constants.serverURL + "groups"
    var delegate: GroupsManagerDelegate?
    
    /// Fetch the groups a user belongs to
    // TO-DO: implement server side routing
    func fetchGroups(userID: String){
        let urlString = "\(fetchGroupsURL)&userID=\(userID)"
        performRequest(with: urlString)
    }
    
    /// Create a group
    // TO-DO: implement server side routing
    func createGroup(groupName: String, ownerID: String){
        /**
         Fires of performPOSTRequest which creates a group
        - Parameters:
        - groupName: Name of group as defined by a user
        - ownerID: User ID of the creator of the group
        - Returns: The uniquely generated group ID
        */
        performPOSTRequest(groupName: groupName, ownerID: ownerID)
    }
    
    // TO-DO: can performRequest and performPOSTRequest be consolidated??
    
    /// This is currently used to fetch groups (GET request)
    func performRequest(with urlString: String) {
        if let url = URL(string: urlString) {
            let session = URLSession(configuration: .default)
            print("Sent request URL: \(url)")
            let task = session.dataTask(with: url) { (data, response, error) in
                if error != nil {
                    self.delegate?.didFailWithError(error: error!)
                    return
                }
                if let safeData = data {
                    print("Request returned: groups fetched")
                    if let groups = self.parseJSON(safeData) {
                        self.delegate?.didUpdateGroups(self, groups: groups)
                        print("Request returned and processed \(groups.count) groups")
                    }
                }
            }
            task.resume()
        }
    }
    
    /// This is currently used to create a group (POST request)
    func performPOSTRequest(groupName: String, ownerID: String){
        let json: [String: Any] = [
            "ownerID": ownerID,
            "groupName": groupName
        ]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        let url = URL(string:createGroupURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // insert json data to the request
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if error != nil {
                self.delegate?.didFailWithError(error: error!)
                print("Comment POST req error")
                return
            }
            if let safeData = data {
                print("Comment POST req returned: \(safeData)")
                self.delegate?.didCreateGroup()
                return
            }
        }
        task.resume()
    }
    
    // TO-DO: modularize this function because currently it is being used
    // in multiple different *Manager.swift files
    func parseJSON(_ data: Data) -> [Group]? {
        let decoder = JSONDecoder()
        var groups : [Group] = []
        do {
            groups = try decoder.decode(Array<Group>.self, from: data)
        } catch {
            delegate?.didFailWithError(error: error)
        }
        return groups
    }
}
