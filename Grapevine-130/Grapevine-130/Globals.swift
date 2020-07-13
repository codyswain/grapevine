//
//  Globals.swift
//  Grapevine-130
//
//  Created by Kelsey Lieberman on 7/6/20.
//  Copyright © 2020 Anthony Humay. All rights reserved.
//

import Foundation
import UIKit

struct Globals {
    struct ViewSettings {
        // Until we figure out a better solution, default mode is light mode
        // static var CurrentMode = UITraitCollection.init().userInterfaceStyle
        static var currentMode = UIUserInterfaceStyle.light
        static var backgroundColor = UIColor.white
        static var labelColor = UIColor.black
        static var showNotificationAlert = false
    }
    
    struct userDefaults {
        static let themeKey = "someStringKey1" // string value
        static let rangeKey = "rangeKey"  // string
        static let filterKey = "filterKey"  // string
        static let postTypeKey = "postTypeKey"  // string
    }

}
