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
}

struct CommentsManager {
    
    let getCommentsURL = Constants.serverURL + "comments/?"
    let createCommentURL = Constants.serverURL + "comments"
    var delegate: CommentsManagerDelegate?
    
    func fetchComments(postID: String){
        
        let urlString = "\(getCommentsURL)&postID=\(postID)"
        performRequest(with: urlString)
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
