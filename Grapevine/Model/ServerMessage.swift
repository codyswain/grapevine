//
//  JSONFormat.swift
//  Grapevine
//
//  Created by Anthony Humay on 1/27/20.
//  Copyright © 2020 Grapevine. All rights reserved.
//

import Foundation

// This should mock the incoming JSON message structure from the server so we can decode it
struct ServerMessage: Decodable {
    let content: String
    let votes: Int
    let date: Double
    let poster: String
    let voteStatus: Int
    let postId: String
}
