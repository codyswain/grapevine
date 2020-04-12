//
//  SnapManager.swift
//  Grapevine-130
//
//  Created by Anthony Humay on 4/12/20.
//  Copyright © 2020 Anthony Humay. All rights reserved.
//

import Foundation

import SCSDKCreativeKit

struct StoryManager {
    var snapAPI = {
        return SCSDKSnapAPI()
    }()
    
    func createImage(_ content: String, _ centerX: CGFloat, _ centerY: CGFloat) -> UIImage? {
        let frame = CGRect(x: 0, y: 0, width: UIScreen.main.nativeBounds.width, height: UIScreen.main.nativeBounds.height)
        let textLabel = UILabel(frame: frame)
        textLabel.backgroundColor = Constants.Colors.darkPurple
        textLabel.numberOfLines = 0
        textLabel.textAlignment = .center
        textLabel.textColor = .white
        textLabel.font = UIFont.boldSystemFont(ofSize: 35)
        textLabel.text = "Heard on Grapevine: \"" + content + "\""
        UIGraphicsBeginImageContext(frame.size)
        
        if let currentContext = UIGraphicsGetCurrentContext() {
            textLabel.layer.render(in: currentContext)
            let nameImage = UIGraphicsGetImageFromCurrentImageContext()
            return nameImage
        }
        return nil
    }

    func shareImageToSnap(_ image: UIImage) {
        let snapPhoto = SCSDKSnapPhoto(image: image)
        let snapContent = SCSDKPhotoSnapContent(snapPhoto: snapPhoto)
        snapContent.attachmentUrl = "https://www.instagram.com/teamgrapevine/"
        // Send it over to Snapchat
        snapAPI.startSending(snapContent)
    }
}
