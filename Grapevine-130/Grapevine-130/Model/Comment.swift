//
//  Comment.swift
//  Grapevine-130
//
//  Created by Cody Swain on 3/27/20.
//  Copyright © 2020 Anthony Humay. All rights reserved.
//

import Foundation

struct Comment : Decodable {
    // Body of comment
    let content: String
    
    // Date post was created
    let date: Double
    
    // Parent post
    let postId: String
    
    // Hashed device ID of comment creator
    let poster: String
    
    // Number of likes a comment has
    var votes: Int
    
    // Comment ID
    let commentID: String
    
    // Whether a user has liked a comment
    var voteStatus: Int
}
