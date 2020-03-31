//
//  CommentsManager.swift
//  Grapevine-130
//
//  Created by Cody Swain on 3/27/20.
//  Copyright © 2020 Anthony Humay. All rights reserved.
//

import Foundation

protocol CommentsManagerDelegate {
    func didUpdateComments(_ commentManager: CommentsManager, comments: [Comment])
    func didFailWithError(error: Error)
    func didCreateComment()
}

struct CommentsManager {
    
    let getCommentsURL = Constants.serverURL + "comments/?"
    let createCommentURL = Constants.serverURL + "comments"
    var delegate: CommentsManagerDelegate?
    
    func fetchComments(postID: String){
        let urlString = "\(getCommentsURL)&postID=\(postID)"
        performRequest(with: urlString)
    }
    
    // interaction 1 will be to like a comment
    // interaction 2 will be to unlike a comment
    func performUpvoteRequest(interaction: Int, commentID: String){
        let endpoint = Constants.serverURL + "commentinteractions/?"
        let urlString = "\(endpoint)&user=\(Constants.userID)&commentID=\(commentID)&action=\(interaction)"
        print ("Sending interaction: ", interaction)
        
        if let url = URL(string: urlString) {
            let session = URLSession(configuration: .default)
            let task = session.dataTask(with: url) { (data, response, error) in
                if error != nil {
                    print ("Interaction request failed")
                    return
                }
                print("Interaction request success")
            }
            task.resume()
        }
    }
    
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
                    print("Request returned")
                    if let comments = self.parseJSON(safeData) {
                        self.delegate?.didUpdateComments(self, comments: comments)
                        print("Request returned and processed \(comments.count) comments")
                    }
                }
            }
            task.resume()
        }
    }
    
    func performPOSTRequest(text: String, postID: String){
        let json: [String: Any] = [
            "text":text,
            "userID": Constants.userID,
            "date": Date().timeIntervalSince1970,
            "postID":postID
        ]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        let url = URL(string:createCommentURL)!
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
                self.delegate?.didCreateComment()
                return
            }
        }
        task.resume()
    }
    
    func parseJSON(_ data: Data) -> [Comment]? {
        let decoder = JSONDecoder()
        var comments : [Comment] = []
        do {
            comments = try decoder.decode(Array<Comment>.self, from: data)
        } catch {
            delegate?.didFailWithError(error: error)
        }
        return comments
    }
    
    
}
