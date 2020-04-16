import Foundation
import UIKit

struct Constants {
    static let appName = "Grapevine"
    static let cellIdentifier = "ReusableCell"
    static let cellNibName = "PostTableViewCell"
    static let commentsCellNibName = "CommentTableViewCell"
    static let numberOfPostsPerBatch = 20
    static let numberOfCharactersPerPost = 280
    static let userID = SHA256(data:UIDevice.current.identifierForVendor!.uuidString)
    static let serverURL = "https://grapevineapp.herokuapp.com/"
    static let numStrikesToBeBanned = 3
    static let banLengthInHours = 86400.0 // 48 hours in seconds
    struct Colors {
        static let lightPurple = UIColor(red:0.86, green:0.69, blue:0.99, alpha:1.0)
        static let darkPurple = UIColor(red:0.62, green:0.27, blue:0.90, alpha:1.0)
        static let veryLightgrey = UIColor(red:0.97, green:0.96, blue:0.97, alpha:1.00)
        static let lightGrey = UIColor(red:0.79, green:0.79, blue:0.79, alpha:1.0)
        static let darkGrey = UIColor(red:0.91, green:0.91, blue:0.91, alpha:1.0)
        static let yellow = UIColor(red:0.96, green:0.82, blue:0.25, alpha:1.0)
        static let veryDarkGrey = UIColor(red:0.47, green:0.47, blue:0.47, alpha:1.0)
    }
    struct Firestore {
        static let collectionName = "posts"
        static let textField = "content"
        static let userIDField = "poster"
        static let votesField = "votes"
        static let voteStatusField = "voteStatus"
        static let dateField = "date"
        static let typeField = "type"
        static let latitudeField = "lat"
        static let longitudeField = "lon"
        static let numFlagsField = "numFlags"
        static let flagStatusField = "flagStatus"
    }
}

