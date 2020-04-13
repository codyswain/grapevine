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
    
    func createImage() -> UIImage? {
        let frame = CGRect(x: 0, y: 0, width: UIScreen.main.nativeBounds.width, height: UIScreen.main.nativeBounds.height)
        let textLabel = UILabel(frame: frame)
        textLabel.backgroundColor = Constants.Colors.darkPurple
        UIGraphicsBeginImageContext(frame.size)
        
        if let currentContext = UIGraphicsGetCurrentContext() {
            textLabel.layer.render(in: currentContext)
            let nameImage = UIGraphicsGetImageFromCurrentImageContext()
            return nameImage
        }
        return nil
    }
    
    func createSticker(_ content: String, _ centerX: CGFloat, _ centerY: CGFloat) -> UIImage? {
        let frame = CGRect(x: 0, y: 0, width: UIScreen.main.nativeBounds.width * (2/3), height: UIScreen.main.nativeBounds.height * (1/3))
        let textLabel = UILabel(frame: frame)
        textLabel.numberOfLines = 0
        textLabel.textAlignment = .center
        textLabel.textColor = .black
        textLabel.font = UIFont.boldSystemFont(ofSize: 40)
        textLabel.text = "Overheard near me:\n\"" + content + "\""
        textLabel.layer.masksToBounds = true
        textLabel.layer.cornerRadius = 40
        textLabel.clipsToBounds = true
        
        UIGraphicsBeginImageContext(frame.size)
        
        if let currentContext = UIGraphicsGetCurrentContext() {
            textLabel.layer.render(in: currentContext)
            let nameImage = UIGraphicsGetImageFromCurrentImageContext()
            return nameImage
        }
        return nil
    }

    func shareImageToSnap(_ backgroundImage: UIImage, _ stickerImage: UIImage) {
        let snapPhoto = SCSDKSnapPhoto(image: backgroundImage)
        let snapContent = SCSDKPhotoSnapContent(snapPhoto: snapPhoto)
        snapContent.attachmentUrl = "https://www.instagram.com/teamgrapevine/"
        let sticker = SCSDKSnapSticker(stickerImage: stickerImage)
        snapContent.sticker = sticker
        snapAPI.startSending(snapContent)
    }
}
