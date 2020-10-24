//
//  Ban.swift
//  Grapevine-130
//
//  Created by Ning Hu on 2/18/20.
//  Copyright © 2020 Anthony Humay. All rights reserved.
//

import Foundation

/// An object that stores all information on a user based on their unique device id.
struct User : Decodable {
    
    /// Hashed unique device id.
    var user: String
    
    /// Number of strikes the user has before their device is banned.
    var strikes: Int
    
    /// Date of the device ban if applicable.
    var banDate: Double
    
    /// User's total upvotes from posts and comments.
    var score: Int
}
