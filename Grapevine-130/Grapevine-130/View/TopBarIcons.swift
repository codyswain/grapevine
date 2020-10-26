//
//  TopBarIcons.swift
//  Grapevine-130
//
//  Created by Tristan Chung on 10/24/20.
//  Copyright © 2020 Anthony Humay. All rights reserved.
//

import Foundation
import UIKit

extension UIImageView {
  func setImageColor(color: UIColor) {
    let templateImage = self.image?.withRenderingMode(.alwaysTemplate)
    self.image = templateImage
    self.tintColor = color
  }
}
