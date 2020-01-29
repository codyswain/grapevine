//
//  Post.swift
//  Grapevine
//
//  Created by Anthony Humay on 1/8/20.
//  Copyright © 2020 Grapevine. All rights reserved.
//

import Foundation
import CoreLocation

struct Post : Decodable {
    let content: String
    var votes: Int
    let date: Double
    var voteStatus: Int
    let postId: String
    let poster: String
    let type: String
    let lat: Double
    let lon: Double
}
