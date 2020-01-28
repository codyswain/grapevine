//
//  Constants.swift
//  Grapevine
//
//  Created by Anthony Humay on 1/8/20.
//  Copyright © 2020 Grapevine. All rights reserved.
//

import Foundation
import UIKit

struct Constants {
    static let appName = "Grapevine"
    static let cellIdentifier = "ReusableCell"
    static let cellNibName = "PostTableViewCell"
    static let numberOfPostsPerBatch = 20
    static let numberOfCharactersPerPost = 280
    static let userID = SHA256(data:UIDevice.current.identifierForVendor!.uuidString)
    static let serverURL = "https://grapevineapp.herokuapp.com/"
    struct Colors {
        static let lightPurple = UIColor(red:0.86, green:0.69, blue:0.99, alpha:1.0)
        static let darkPurple = UIColor(red:0.62, green:0.27, blue:0.90, alpha:1.0)
        static let lightGrey = UIColor(red:0.79, green:0.79, blue:0.79, alpha:1.0)
        static let darkGrey = UIColor(red:0.91, green:0.91, blue:0.91, alpha:1.0)
    }
    struct Firestore {
        static let collectionName = "posts"
        static let textField = "content"
        static let userIDField = "poster"
        static let votesField = "votes"
        static let dateField = "date"
        static let userField = "user"
        static let voteFlagString = "user." + "zr42Im6A43mrGdO5w0Ja" + ".submittedVoteFlag"
//        static let voteFlagString = "users" + Constants.userID + "submittedVoteFlag"
    }
}

