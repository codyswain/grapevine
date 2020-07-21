//
//  Group.swift
//  Grapevine-130
//
//  Created by Cody Swain, Kelsey Lieberman on 7/20/20.
//  Copyright © 2020 Cody Swain, Kelsey Lieberman. All rights reserved.
//

import Foundation

struct Group : Decodable {
    // Unique identifier for a group
    let groupID: String
    
    // User defined name for the group
    let groupName: String
    
    // Hashed device ID of group owner
    let ownerID: String
}
