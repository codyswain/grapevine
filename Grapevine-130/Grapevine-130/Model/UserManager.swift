//
//  File.swift
//  Grapevine-130
//
//  Created by Ning Hu on 2/18/20.
//  Copyright © 2020 Anthony Humay. All rights reserved.
//

import Foundation

protocol UserManagerDelegate {
    func didGetUser(_ userManager: UserManager, user: User)
    func didUpdateUser(_ userManager: UserManager)
    func userDidFailWithError(error: Error)
}

/// An object that handles the retrieval of user data from the database.
struct UserManager {
    
    /// Hits the /users endpoint.
    let getUserURL = Constants.serverURL + "users/?"
    let banUserURL = Constants.serverURL + "banChamber/banPoster/?"
    let shoutUserURL = Constants.serverURL + "shoutChamber/shoutPost/?"
    let pushUserURL = Constants.serverURL + "users/push/?"
    let freeUserURL = Constants.serverURL + "users/freeUser/?"
    
    var delegate: UserManagerDelegate?
    
    func isBanned(strikes:Int, banTime: Double) -> Bool {
        let timeDiff = Date().timeIntervalSince1970 - banTime
        if strikes >= Constants.numStrikesToBeBanned && timeDiff < Constants.banLengthInSeconds {
            // reset strikes
            return true
        } else if strikes >= Constants.numStrikesToBeBanned {
            freeUser()
        }
        return false
    }
    
    /** Fetches a user's information based on the operating device's unique device id.  */
    func fetchUser() {
        let urlString = "\(getUserURL)&user=\(Constants.userID)"
        print ("UserID: ", Constants.userID)
        performRequest(with: urlString, handleResponse: true)
    }
    
    func banUser(poster: String, postID: String, groupID: String = "Grapevine") {
        let urlString = "\(banUserURL)&poster=\(poster)&time=\(Date().timeIntervalSince1970)&postID=\(postID)&user=\(Constants.userID)&groupID=\(groupID)"
        print ("Banning userID: ", poster)
        performRequest(with: urlString, handleResponse: false)
    }
    
    func shoutPost(poster: String, postID: String, groupID: String = "Grapevine") {
        // Shout outs expire in 3 hours
        let shoutExpiration = Date().timeIntervalSince1970 + 6*60*60
        let urlString = "\(shoutUserURL)&poster=\(poster)&time=\(shoutExpiration)&postID=\(postID)&user=\(Constants.userID)&groupID=\(groupID)"
        print ("Shouted post: ", postID, "in groupID: ", groupID)
        performRequest(with: urlString, handleResponse: false)
    }
    
    func pushPost(poster: String, postID: String, lat: Double, lon: Double, groupID: String = "Grapevine") {
        print("Pushed post of poster \(poster) in group \(groupID)")
        let urlString = "\(pushUserURL)&postID=\(postID)&groupID=\(groupID)&user=\(Constants.userID)&lat=\(lat)&lon=\(lon)&range=3"
        print ("Pushed post: ", postID)
        performRequest(with: urlString, handleResponse: false)
    }
    
    func freeUser(){
        let urlString = "\(freeUserURL)&user=\(Constants.userID)"
        print ("Freeing userID: ", Constants.userID)
        performRequest(with: urlString, handleResponse: false)
    }

    /** Handles a request for a user's information. Modifies `UserManagerDelegate` based on the retrieved data.
     - Parameter urlString: The server endpoint with parameters. */
    func performRequest(with urlString: String, handleResponse: Bool) {
        print ("Sending request urlString: ", urlString)
        if let url = URL(string: urlString) {
            let session = URLSession(configuration: .default)
            let task = session.dataTask(with: url) { (data, response, error) in
                // fetchUser() response
                if handleResponse {
                    if error != nil {
                        self.delegate?.userDidFailWithError(error: error!)
                        return
                    }
                    if let safeData = data {
                        print("Request success")
                        if let user = self.parseJSON(safeData) {
                            self.delegate?.didGetUser(self, user: user)
                        }
                    }
                // banUser() response
                } else {
                    if let httpResponse = response as? HTTPURLResponse {
                        if httpResponse.statusCode != 200 {
                            print("Error banning OR freeing user: \(String(describing: error))")
                            self.delegate?.userDidFailWithError(error: NSError(domain:"", code:httpResponse.statusCode, userInfo:nil))
                            return
                        } else {
                            print("Banned/free user success")
                            self.delegate?.didUpdateUser(self)
                        }
                    }
                }
            }
            task.resume()
        }
    }
    
    /**
    Decodes the JSON data returned from the server and verifies that it is a valid `user`.

    - Parameter data: The response data from the server in JSON format.
     
    - Returns: A `user` or modifies `UserManagerDelegate` upon failure.
    */
    func parseJSON(_ data: Data) -> User? {
        let decoder = JSONDecoder()
        var user:User?
        do {
            user = try decoder.decode(User.self, from: data)
        } catch {
            delegate?.userDidFailWithError(error: error)
        }
        return user
    }
    
}
