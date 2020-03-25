//
//  PostReference.swift
//  Grapevine-130
//
//  Created by Ning Hu on 3/23/20.
//  Copyright © 2020 Anthony Humay. All rights reserved.
//

import Foundation

/// The object that is returned by the server when requesting posts
struct PostReference : Decodable {
    
    /// Last document from the query. Needed to get the next set of posts.
    let reference: String
    
    /// Posts sent by the server
    let posts: Array<Post>
}
