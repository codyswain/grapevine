import Foundation
import CoreLocation

protocol PostsManagerDelegate {
    func didUpdatePosts(_ postManager: PostsManager, posts: [Post])
    func didFailWithError(error: Error)
}

/// An object that handles the retrieval of post data from the database.
struct PostsManager {
    
    /// Hits the /posts endpoint
    let getPostsURL = Constants.serverURL + "posts/?"
    let getBannedPostsURL = Constants.serverURL + "banChamber/?"
    let createPostURL = Constants.serverURL + "posts"
    
    var delegate: PostsManagerDelegate?
        
    /**
    Fetches posts from the database.
     
    - Parameters:
        - latitude: Latitude of the client requesting posts
        - longitude: Longitude of the client requesting posts
    */
    func fetchPosts(latitude: CLLocationDegrees, longitude: CLLocationDegrees, range: Int) {
        let urlString = "\(getPostsURL)&lat=\(latitude)&lon=\(longitude)&user=\(Constants.userID)&range=\(range)"
        performRequest(with: urlString)
    }
    
    func fetchBannedPosts(latitude: CLLocationDegrees, longitude: CLLocationDegrees, range: Int) {
        let urlString = "\(getBannedPostsURL)&lat=\(latitude)&lon=\(longitude)&user=\(Constants.userID)&range=\(range)"
        performRequest(with: urlString)
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
                    if let posts = self.parseJSON(safeData) {
                        self.delegate?.didUpdatePosts(self, posts: posts)
                        print("Request returned and processed \(posts.count) posts")
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
    func parseJSON(_ data: Data) -> [Post]? {
        let decoder = JSONDecoder()
        var posts:[Post] = []
        do {
            posts = try decoder.decode(Array<Post>.self, from: data)
        } catch {
            delegate?.didFailWithError(error: error)
        }
        return posts
    }
    
}
