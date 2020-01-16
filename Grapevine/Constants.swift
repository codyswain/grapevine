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
    struct Firestore {
        static let collectionName = "posts"
        static let textField = "content"
        static let userIDField = "poster"
        static let votesField = "votes"
        static let dateField = "date"
        static let userField = "user"
        static let voteFlagString = "user." + "zr42Im6A43mrGdO5w0Ja" + ".submittedVoteFlag"
//        static let voteFlagString = "users" + UIDevice.current.identifierForVendor!.uuidString + "submittedVoteFlag"
    }
    
}
