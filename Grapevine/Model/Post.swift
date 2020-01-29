//
//  Post.swift
//  Grapevine
//
//  Created by Anthony Humay on 1/8/20.
//  Copyright © 2020 Grapevine. All rights reserved.
//

import Foundation

struct Post {
    let content: String
    var votes: Int
    let date: Double
    var voteStatus: Int
    let postId: String
    let poster: User? = nil
    var comments: [Comment]? = nil
}
