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
    func userDidFailWithError(error: Error)
}

/// An object that handles the retrieval of user data from the database.
struct UserManager {
    
    /// Hits the /users endpoint.
    let getUserURL = Constants.serverURL + "users/?"
    let banUserURL = Constants.serverURL + "banChamber/banPoster/?"

    var delegate: UserManagerDelegate?
    
    func isBanned(strikes:Int, banTime: Double) -> Bool {
        let timeDiff = Date().timeIntervalSince1970 - banTime
        if strikes >= Constants.numStrikesToBeBanned && timeDiff < Constants.banLengthInHours {
            // reset strikes
            return true
        }
        return false
    }
    
    /**
    Fetches a user's information based on the operating device's unique device id.
    */
    func fetchUser() {
        let urlString = "\(getUserURL)&user=\(Constants.userID)"
        print ("UserID: ", Constants.userID)
        performRequest(with: urlString, handleResponse: true)
    }
    
    func banUser(poster: String) {
        let urlString = "\(banUserURL)&poster=\(poster)&time=\(Date().timeIntervalSince1970)"
        print ("Banning userID: ", poster)
        performRequest(with: urlString, handleResponse: false)
    }

    /**
    Handles a request for a user's information. Modifies `UserManagerDelegate` based on the retrieved data.

    - Parameter urlString: The server endpoint with parameters.
    */
    func performRequest(with urlString: String, handleResponse: Bool) {
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
                    if error != nil {
                        print("Error banning user: \(String(describing: error))")
                    }
                    if data != nil {
                        print("Banned user success")
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
