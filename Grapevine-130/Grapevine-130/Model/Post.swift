import Foundation
import CoreLocation

/// An object that stores information about a post based on the current user.
struct Post : Decodable {
    
    /// Body of the post
    let content: String
    
    /// Total number of votes on the post
    var votes: Int
    
    /// Date that the post was created
    let date: Double
    
    /**
    The current user's interaction with the post
    - Values: -1, 0, 1
    */
    var voteStatus: Int
    
    /// Unique identifier
    let postId: String
    
    /// Hashed device ID of the post creator
    let poster: String
    
    /**
    Describes the type of post
    - Values:
        - "text"
        - "image"
    */
    let type: String
    
    /// Location of the poster when creating this post
    let lat: Double
    let lon: Double
    
    /// Number of report flags by other users
    var numFlags: Int
    
    /**
    Records how the current user flagged the post
    - Values: 0, 1
    */
    var flagStatus: Int
    
    /**
     Number of comments
     */
    var comments: Int
}
