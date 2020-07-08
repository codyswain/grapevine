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
        //Until we figure out a better solution, default mode is light mode
//        static var CurrentMode = UITraitCollection.init().userInterfaceStyle
        static var CurrentMode = UIUserInterfaceStyle.light
        static var BackgroundColor = UIColor.systemGray5
        static var LabelColor = UIColor.black
    }
}
