import Foundation
import CoreLocation
import UIKit

protocol PostsManagerDelegate {
    func didUpdatePosts(_ postManager: PostsManager, posts: [Post], ref: String)
    func didGetMorePosts(_ postManager: PostsManager, posts: [Post], ref: String)
    func didFailWithError(error: Error)
    func didCreatePost()
}

/// An object that handles the retrieval of post data from the database.
struct PostsManager {
    
    /// Hits the /posts endpoint
    let fetchPostsURL = Constants.serverURL + "posts/?"
    let fetchMorePostsURL = Constants.serverURL + "posts/more/?"
    let fetchGroupPostsURL = Constants.serverURL + "groups/posts/?"
    let fetchMoreGroupPostsURL = Constants.serverURL + "groups/posts/more/?"
    let fetchMyPostsURL = Constants.serverURL + "myPosts/?"
    let fetchMoreMyPostsURL = Constants.serverURL + "myPosts/more/?"
    let fetchBannedPostsURL = Constants.serverURL + "banChamber/?"
    let fetchShoutablePostsURL = Constants.serverURL + "shoutChamber/?"
    let createPostURL = Constants.serverURL + "posts"
    let createGroupsPostURL = Constants.serverURL + "groups/posts"
    let fetchMyCommentsURL = Constants.serverURL + "myComments/?"
    let fetchMoreMyCommentsURL = Constants.serverURL + "myComments/more/?"
    var delegate: PostsManagerDelegate?
        
    /** Fetches posts from the database.
    - Parameters:
        - latitude: Latitude of the client requesting posts
        - longitude: Longitude of the client requesting posts
        - range: Distance around the user to retrieve posts from */
    func fetchPosts(latitude: CLLocationDegrees, longitude: CLLocationDegrees, range: Double, activityFilter: String, typeFilter: String, groupID: String = "Grapevine") {
        var fetchURL = fetchPostsURL
        if groupID != "Grapevine" {
            fetchURL = fetchGroupPostsURL
        }
        let urlString = "\(fetchURL)&lat=\(latitude)&lon=\(longitude)&user=\(Constants.userID)&range=\(range)&activityFilter=\(activityFilter)&typeFilter=\(typeFilter)&groupID=\(groupID)"
        performRequest(with: urlString)
    }
    
    func deletePost(postID: String, groupID: String = "Grapevine"){
        let json: [String: Any] = ["postId": postID, "groupID": groupID]
        print("postid: ", postID)
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        // Create delete request
        var url = URL(string: Constants.serverURL + "posts")!
        if groupID != "Grapevine" {
            url = URL(string: Constants.serverURL + "groups/posts")!
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        // insert json data to the request
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if error != nil {
                self.delegate?.didFailWithError(error: error!)
                print("DELETE req error")
                return
            }
            if let safeData = data {
                print("DELETE req returned: \(safeData)")
            }
        }
        task.resume()
    }
    
    /** Fetches posts that can be banned from the database.
     - Parameters:
        - latitude: Latitude of the client requesting posts
        - longitude: Longtitude of the client requesting posts
        - range: Distance around the user to retrieve posts from
     */
    func fetchBannedPosts(latitude: CLLocationDegrees, longitude: CLLocationDegrees, range: Double, groupID: String = "Grapevine") {
        let urlString = "\(fetchBannedPostsURL)&lat=\(latitude)&lon=\(longitude)&user=\(Constants.userID)&range=\(range)&groupID=\(groupID)"
        performRequest(with: urlString)
    }
    
    func fetchShoutablePosts(latitude: CLLocationDegrees, longitude: CLLocationDegrees, range: Double, groupID: String = "Grapevine") {
        let urlString = "\(fetchShoutablePostsURL)&lat=\(latitude)&lon=\(longitude)&user=\(Constants.userID)&range=\(range)&groupID=\(groupID)"
        performRequest(with: urlString)
    }
    
    /** Fetches more posts from the database for infinite scrolling. */
    func fetchMorePosts(latitude: CLLocationDegrees, longitude: CLLocationDegrees, range: Double, ref: String, activityFilter: String, typeFilter: String, groupID: String = "Grapevine") {
        var fetchMoreURL = fetchMorePostsURL
        if groupID != "Grapevine" {
            fetchMoreURL = fetchMoreGroupPostsURL
        }
        let urlString = "\(fetchMoreURL)&lat=\(latitude)&lon=\(longitude)&user=\(Constants.userID)&range=\(range)&ref=\(ref)&activityFilter=\(activityFilter)&typeFilter=\(typeFilter)&groupID=\(groupID)"
        performMoreRequest(with: urlString)
    }
    
    func fetchMoreMyPosts(ref: String) {
        let urlString = "\(fetchMoreMyPostsURL)&user=\(Constants.userID)&ref=\(ref)"
        performMoreRequest(with: urlString)
    }
    
    func fetchMoreMyComments(ref: String) {
        let urlString = "\(fetchMoreMyCommentsURL)&user=\(Constants.userID)&ref=\(ref)"
        performMoreRequest(with: urlString)
    }

    /**
    Handles a request for posts' information. Modifies `PostManagerDelegate` based on the retrieved data.

    - Parameter urlString: The server endpoint with parameters.
    */
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
                    if let ref = self.parseJSON(safeData) {
                        self.delegate?.didUpdatePosts(self, posts: ref.posts, ref: ref.reference)
                        print("Request returned and processed \(ref.posts.count) posts")
                    }
                }
            }
            task.resume()
        }
    }
    
    /**
    Handles a request for posts' information. Modifies `PostManagerDelegate` based on the retrieved data.

    - Parameter urlString: The server endpoint with parameters.
    */
    func performMoreRequest(with urlString: String) {
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
                    if let ref = self.parseJSON(safeData) {
                        self.delegate?.didGetMorePosts(self, posts: ref.posts, ref: ref.reference)
                        print("Request returned and processed \(ref.posts.count) posts")
                    }
                }
            }
            task.resume()
        }
    }
    
    /**
    Handles the sending of a newly created post to the server.
     
     - Parameters:
        - contentText: Body of the post
        - latitude: Latitude of the post creator
        - longitude: Longitude of the post creator
        - postType: The type of post that is being sent
    */
    func performPOSTRequest(contentText: String, latitude: CLLocationDegrees, longitude: CLLocationDegrees, postType: String, groupID: String = "Grapevine") {
        // Get most up to date notification token
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let pushNotificationToken = appDelegate.pushNotificationToken
        
        let json: [String: Any] = [
            "text": contentText,
            "userID": Constants.userID,
            "pushNotificationToken": pushNotificationToken,
            "date": Date().timeIntervalSince1970,
            "type": postType,
            "latitude": latitude,
            "longitude": longitude,
            "groupID": groupID,
        ]

        let jsonData = try? JSONSerialization.data(withJSONObject: json)

        // create post request
        var url =  URL(string:createPostURL)!
        if groupID != "Grapevine" {
            url = URL(string: createGroupsPostURL)!
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // insert json data to the request
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let session = URLSession(configuration: .default)

        let task = session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                self.delegate?.didFailWithError(error: error!)
                print("Post req error")
                return
            }
            if let response = response {
                let httpResponse = response as! HTTPURLResponse
                self.delegate?.didCreatePost()
            }
        }
        task.resume()
    }

    /**
    Sends interaction request to server.
     
    - Parameter interaction: The interaction value to be sent
        - 1: upvote
        - 2: downvote
        - 4: flag
     */
    func performInteractionRequest(interaction: Int, docID: String, groupID: String = "Grapevine") {
        let endpoint = Constants.serverURL + "interactions/?"
        let urlString = "\(endpoint)&user=\(Constants.userID)&post=\(docID)&action=\(interaction)&groupID=\(groupID)"
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

    /**
    Decodes the JSON data returned from the server and verifies that it is a valid array of posts.

    - Parameter data: The response data from the server in JSON format.
     
    - Returns: A an array of posts or modifies `PostManagerDelegate` upon failure.
    */
    func parseJSON(_ data: Data) -> PostReference? {
        let decoder = JSONDecoder()
        var ref = PostReference(reference: "", posts: [])
        do {
            ref = try decoder.decode(PostReference.self, from: data)
        } catch {
            delegate?.didFailWithError(error: error)
        }
        return ref
    }
    
    // Fetch the user's own posts
    func fetchMyPosts(activityFilter: String, typeFilter: String) {
        let urlString = "\(fetchMyPostsURL)&user=\(Constants.userID)"
        performRequest(with: urlString)
    }
    
    // Fetch the user's own comments
    func fetchMyComments(activityFilter: String, typeFilter: String) {
        let urlString = "\(fetchMyCommentsURL)&user=\(Constants.userID)"
        performRequest(with: urlString)
    }

}
