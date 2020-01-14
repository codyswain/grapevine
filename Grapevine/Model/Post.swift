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
    let votes: Int
    let postID: String? = nil
    let poster: User? = nil
    let comments: [Comment]? = nil
    let voteStatus: Int
}
