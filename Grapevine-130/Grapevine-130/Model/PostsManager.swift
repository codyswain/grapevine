import Foundation
import CoreLocation

protocol PostsManagerDelegate {
    func didUpdatePosts(_ postManager: PostsManager, posts: [Post], ref: String)
    func didGetMorePosts(_ postManager: PostsManager, posts: [Post], ref: String)
    func didFailWithError(error: Error)
}

/// An object that handles the retrieval of post data from the database.
struct PostsManager {
    
    /// Hits the /posts endpoint
    let fetchPostsURL = Constants.serverURL + "posts/?"
    let fetchBannedPostsURL = Constants.serverURL + "banChamber/?"
    let createPostURL = Constants.serverURL + "posts"
    let fetchMorePostsURL = Constants.serverURL + "posts/more/?"
    
    var delegate: PostsManagerDelegate?
        
    /**
    Fetches posts from the database.
     
    - Parameters:
        - latitude: Latitude of the client requesting posts
        - longitude: Longitude of the client requesting posts
        - range: Distance around the user to retrieve posts from
    */
    func fetchPosts(latitude: CLLocationDegrees, longitude: CLLocationDegrees, range: Int) {
        let urlString = "\(fetchPostsURL)&lat=\(latitude)&lon=\(longitude)&user=\(Constants.userID)&range=\(range)"
        performRequest(with: urlString)
    }
    
    func deletePost(postID: String){
        let json: [String: Any] = ["postId": postID]
        print("postid: ", postID)
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        // Create delete request
        let url = URL(string: Constants.serverURL + "posts")!
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
    
    /**
     Fetches posts that can be banned from the database.
     
     - Parameters:
        - latitude: Latitude of the client requesting posts
        - longitude: Longtitude of the client requesting posts
        - range: Distance around the user to retrieve posts from
     */
    func fetchBannedPosts(latitude: CLLocationDegrees, longitude: CLLocationDegrees, range: Int) {
        let urlString = "\(fetchBannedPostsURL)&lat=\(latitude)&lon=\(longitude)&user=\(Constants.userID)&range=\(range)"
        performRequest(with: urlString)
    }
    
    /**
     Fetches more posts from the database for infinite scrolling.
     
     - Parameters:
        - latitude: Latitude of the client requesting posts
        - longitude: Longitude of the client requesting posts
        - range: Distance around the user to retrieve posts from
        - ref: Document id of the last post retrieved from the database in the previous request
     */
    func fetchMorePosts(latitude: CLLocationDegrees, longitude: CLLocationDegrees, range: Int, ref: String) {
        let urlString = "\(fetchMorePostsURL)&lat=\(latitude)&lon=\(longitude)&user=\(Constants.userID)&range=\(range)&ref=\(ref)"
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
    func performPOSTRequest(contentText: String, latitude: CLLocationDegrees, longitude: CLLocationDegrees, postType: String) {
        let json: [String: Any] = ["text": contentText, "userID": Constants.userID, "date": Date().timeIntervalSince1970, "type": postType, "latitude": latitude, "longitude": longitude]

        let jsonData = try? JSONSerialization.data(withJSONObject: json)

        // create post request
        let url = URL(string:createPostURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // insert json data to the request
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if error != nil {
                self.delegate?.didFailWithError(error: error!)
                print("Post req error")
                return
            }
            if let safeData = data {
                print("Post req returned: \(safeData)")
            }
        }
        task.resume()
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
    
}
