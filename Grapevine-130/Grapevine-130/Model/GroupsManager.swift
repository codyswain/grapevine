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
    func didCreateGroup(groupID: String)
}

struct GroupsManager {
//    let fetchGroupsURL = Constants.serverURL + "groups/?"
//    let createGroupURL = Constants.serverURL + "groups"
    let fetchGroupsURL = Constants.testServerURL + "groups/?"
    let createGroupURL = Constants.testServerURL + "groups"
    var delegate: GroupsManagerDelegate?
    
    /// Fetch the groups a user belongs to
    func fetchGroups(userID: String){
        let url = "\(fetchGroupsURL)&userID=\(userID)"
        performRequest(with: url, requestType: "fetch")
    }
    
    /// Create a group
    func createGroup(groupName: String, ownerID: String){
        let url = "\(createGroupURL)&ownerID=\(ownerID)&groupName=\(groupName)"
        performRequest(with: url, requestType: "create")
    }
    
    // TO-DO: can performRequest and performPOSTRequest be consolidated??
    
    /// This is currently used to fetch groups (GET request)
    func performRequest(with urlString: String, requestType: String) {
//        if let url = URL(string: urlString) {
//            let session = URLSession(configuration: .default)
//            print("Sent request URL: \(url)")
//            let task = session.dataTask(with: url) { (data, response, error) in
//                if error != nil {
//                    self.delegate?.didFailWithError(error: error!)
//                    return
//                }
//                if let safeData = data {
//                    if (requestType == "fetch"){
//                        print("Request returned: groups fetched")
//                        if let groups = self.parseJSON(safeData) {
//                            self.delegate?.didUpdateGroups(self, groups: groups)
//                            print("Request returned and processed \(groups.count) groups")
//                            print(groups)
//                        }
//                    } else if (requestType == "create"){
//                        print(safeData)
////                        if let data = safeData {
////                            print(safeData)
////                        }
////                        if let groupID = self.parseJSON(safeData) {
////                            self.delegate?.didCreateGroup(groupID: groupID)
////                            print("Request returned and processed group with ID: \(groupID)")
////                        }
//                    }
//                }
//            }
//            task.resume()
//        }
        
        
        if let url = URL(string: urlString) {
            let session = URLSession(configuration: .default)
            print("Sent request URL: \(url)")
            let task = session.dataTask(with: url) { (data, response, error) in
                if error != nil {
                    self.delegate?.didFailWithError(error: error!)
                    return
                }
                if let safeData = data {
                    if let groups = self.parseJSON(safeData) {
                        self.delegate?.didUpdateGroups(self, groups: groups)
                        print("Request returned and processed \(groups) posts")
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
                self.delegate?.didCreateGroup(groupID: "hghhh")
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
