import Foundation
import UIKit

struct Constants {
    static let appName = "Grapevine"
    static let cellIdentifier = "ReusableCell"
    static let cellNibName = "PostTableViewCell"
    static let commentsCellNibName = "CommentTableViewCell"
    static let deviceType = UIDevice.current.deviceType
    static let numberOfPostsPerBatch = 20
    static let numberOfCharactersPerPost = 280
    static let userID = SHA256(data:UIDevice.current.identifierForVendor!.uuidString)
    static let serverURL = "https://grapevineapp.herokuapp.com/"
    static let numStrikesToBeBanned = 3
    static let banLengthInSeconds = 43200.0 // 12 hours in seconds
    static let spamLength = 30.0 // 30 seconds
    struct Colors {
        static let lightPurple = UIColor(red:0.86, green:0.69, blue:0.99, alpha:1.0)
        static let darkPurple = UIColor(red:0.62, green:0.27, blue:0.90, alpha:1.0)
        static let veryLightgrey = UIColor(red:0.97, green:0.96, blue:0.97, alpha:1.00)
        static let lightGrey = UIColor(red:0.79, green:0.79, blue:0.79, alpha:1.0)
        static let darkGrey = UIColor(red:0.91, green:0.91, blue:0.91, alpha:1.0)
        static let yellow = UIColor(red:0.96, green:0.82, blue:0.25, alpha:1.0)
        static let veryDarkGrey = UIColor(red:0.47, green:0.47, blue:0.47, alpha:1.0)
        static let extremelyDarkGrey = UIColor(red:0.1, green:0.1, blue:0.1, alpha:1.0)
        static let mediumPink = UIColor(red:0.77, green:0.28, blue:0.79, alpha:1.0)
        static let darkPink = UIColor(red: 1.00, green: 0.32, blue: 0.51, alpha: 1.00)
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

extension UIDevice {
    enum DeviceType: String {
        case iPhone4_4S = "iPhone 4 or iPhone 4S"
        case iPhones_5_5s_5c_SE = "iPhone 5, iPhone 5s, iPhone 5c or iPhone SE"
        case iPhones_6_6s_7_8 = "iPhone 6, iPhone 6S, iPhone 7 or iPhone 8"
        case iPhones_6Plus_6sPlus_7Plus_8Plus = "iPhone 6 Plus, iPhone 6S Plus, iPhone 7 Plus or iPhone 8 Plus"
        case iPhoneX = "iPhone X"
        case iPhone11 = "iPhone 11"
        case iPhone11ProMax = "iPhone 11 Pro Max"
        case unknown = "iPadOrUnknown"
    }

    var deviceType: DeviceType {
        print("Height: \(UIScreen.main.nativeBounds.height)")
        switch UIScreen.main.nativeBounds.height {
            case 960:
                return .iPhone4_4S
            case 1136:
                return .iPhones_5_5s_5c_SE
            case 1334:
                return .iPhones_6_6s_7_8
            case 1920, 2208:
                return .iPhones_6Plus_6sPlus_7Plus_8Plus
            case 2436:
                return .iPhoneX
            case 1792:
                return .iPhone11
            case 2688:
                return .iPhone11ProMax
            default:
                return .unknown
            }
    }
}
