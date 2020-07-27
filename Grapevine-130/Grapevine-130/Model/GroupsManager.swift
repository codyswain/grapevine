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
    
    func didJoinGroup()
    func didCreateKey(key: String)
}

struct GroupsManager {
    let fetchGroupsURL = Constants.serverURL + "groups/?"
    let createGroupURL = Constants.serverURL + "groups"
    let joinGroupURL = Constants.serverURL + "groups/key/?"
    let createGroupKeyURL = Constants.serverURL + "groups/keygen/?"
    var delegate: GroupsManagerDelegate?
    
    /// Fetch the groups a user belongs to
    func fetchGroups(userID: String){
        let url = "\(fetchGroupsURL)&userID=\(userID)"
        performRequest(with: url, requestType: "fetch")
    }
    
    /// Create a group
    func createGroup(groupName: String, ownerID: String){
        performPOSTRequest(groupName: groupName, ownerID: ownerID)
    }
    
    func joinGroup(key: String, userID: String){
        let url = "\(joinGroupURL)&userID=\(userID)&key=\(key)"
        performRequestJoinGroup(with: url, requestType: "join")
    }
    
    func createInviteKey(groupID: String){
        let url = "\(createGroupKeyURL)&groupID=\(groupID)"
        performRequestGenerateKey(with: url, requestType: "key")
    }
    
    // TO-DO: can performRequest and performPOSTRequest be consolidated??
    
    /// This is currently used to fetch groups (GET request)
    func performRequest(with urlString: String, requestType: String) {
        if let url = URL(string: urlString) {
            let session = URLSession(configuration: .default)
            print("Sent request URL: \(url)")
            let task = session.dataTask(with: url) { (data, response, error) in
                if error != nil {
                    self.delegate?.didFailWithError(error: error!)
                    return
                }
                if let safeData = data {
                    print(response as Any)
                    if let ref = self.parseJSON(safeData) {
                        print("Request returned and processed \(ref.groups) groups")
                        self.delegate?.didUpdateGroups(self, groups: ref.groups)
                    }
                }
            }
            task.resume()
        }
    }
    
    func performRequestJoinGroup(with urlString: String, requestType: String) {
        if let url = URL(string: urlString) {
            let session = URLSession(configuration: .default)
            print("Sent request URL: \(url)")
            let task = session.dataTask(with: url) { (data, response, error) in
                if error != nil {
                    self.delegate?.didFailWithError(error: error!)
                    return
                }
                if let safeData = data {
                    print("Request returned and processed \(safeData)")
                    self.delegate?.didJoinGroup()
                }
            }
            task.resume()
        }
    }
    
    func performRequestGenerateKey(with urlString: String, requestType: String) {
        if let url = URL(string: urlString) {
            let session = URLSession(configuration: .default)
            print("Sent request URL: \(url)")
            let task = session.dataTask(with: url) { (data, response, error) in
                if error != nil {
                    self.delegate?.didFailWithError(error: error!)
                    return
                }
                if let safeData = data {
                    do {
                        let json = try JSONSerialization.jsonObject(with: safeData, options: []) as? [String : Any]
                        let key = json?["key"] as? String
                        print("Request returned and processed \(key ?? "ERROR")")
                        self.delegate?.didCreateKey(key: key ?? "ERROR")
                    } catch {
                        self.delegate?.didCreateKey(key: "ERROR")
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
    
    func parseJSON(_ data: Data) -> GroupReference? {
        let decoder = JSONDecoder()
        var ref = GroupReference(groups: [])
        do {
            ref = try decoder.decode(GroupReference.self, from: data)
        } catch {
            delegate?.didFailWithError(error: error)
        }
        return ref
    }
}
