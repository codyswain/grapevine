//
//  PostsManager.swift
//  Grapevine
//
//  Created by Anthony Humay on 1/27/20.
//  Copyright © 2020 Grapevine. All rights reserved.
//

import Foundation
import CoreLocation

protocol PostsManagerDelegate {
    func didUpdatePosts(_ postManager: PostsManager, posts: [Post])
    func didFailWithError(error: Error)
}

struct PostsManager {
    let getPostsURL = Constants.serverURL + "posts/?"
    
    var delegate: PostsManagerDelegate?
        
    func fetchPosts(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        let urlString = "\(getPostsURL)&lat=\(latitude)&lon=\(longitude)&user=\(Constants.userID)"
        print("urlString: \(urlString)")
        performRequest(with: urlString)
    }
    
    func performRequest(with urlString: String) {
        if let url = URL(string: urlString) {
            let session = URLSession(configuration: .default)
            let task = session.dataTask(with: url) { (data, response, error) in
                if error != nil {
                    self.delegate?.didFailWithError(error: error!)
                    return
                }
                if let safeData = data {
                    if let posts = self.parseJSON(safeData) {
                        self.delegate?.didUpdatePosts(self, posts: posts)
                    }
                }
            }
            task.resume()
        }
    }
    
    func parseJSON(_ data: Data) -> [Post]? {
        let decoder = JSONDecoder()
        var posts:[Post] = []
        do {
            let JSONposts = try decoder.decode(Array<ServerMessage>.self, from: data)
            for post in JSONposts {
                let currentPost = Post(content:post.content, votes:post.votes, date:post.date, voteStatus:post.voteStatus, postId:post.postId)
                posts.append(currentPost)
            }
        } catch {
            delegate?.didFailWithError(error: error)
        }
        return posts
    }
    
}
