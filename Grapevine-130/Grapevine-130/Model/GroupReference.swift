//
//  GroupReference.swift
//  Grapevine-130
//
//  Created by Cody Swain on 7/25/20.
//  Copyright © 2020 Cody Swain. All rights reserved.
//

import Foundation

/// The object that is returned by the server when requesting posts
struct GroupReference : Decodable {
    
    /// Posts sent by the server
    let groups: Array<Group>
}
