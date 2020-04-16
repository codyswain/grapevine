//
//  SnapManager.swift
//  Grapevine-130
//
//  Created by Anthony Humay on 4/12/20.
//  Copyright © 2020 Anthony Humay. All rights reserved.
//

import Foundation
import CoreLocation
import SCSDKCreativeKit

struct StoryManager {
    var snapAPI = {
        return SCSDKSnapAPI()
    }()
        
    func createBackgroundImage(_ postType: String, _ city: String, _ height: CGFloat) -> UIImage? {
        let frame = CGRect(x: 0, y: 0, width: UIScreen.main.nativeBounds.width, height: UIScreen.main.nativeBounds.height)
        let mainView = UIView(frame: frame)
        mainView.backgroundColor = .white
        
        let labelFrame = CGRect(x: (UIScreen.main.nativeBounds.width/2) - 500, y: UIScreen.main.nativeBounds.height*(1/2) - (height/2) - 100, width: 1000, height: 100)
        let textLabelX = UILabel(frame:labelFrame)
        textLabelX.numberOfLines = 0
        textLabelX.textAlignment = .center
        textLabelX.textColor = .black
        textLabelX.font = UIFont.boldSystemFont(ofSize: 35)
        if city != "NO_CITY" {
            textLabelX.text = "Anonymously said near " + city
        } else {
            textLabelX.text = "Heard on Grapevine"
        }
        
        mainView.addSubview(textLabelX)
        
        UIGraphicsBeginImageContext(frame.size)
        
        if let currentContext = UIGraphicsGetCurrentContext() {
            mainView.layer.render(in: currentContext)
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
    
    func shareImageToSnapNoSticker(_ backgroundImage: UIImage) {
        let snapPhoto = SCSDKSnapPhoto(image: backgroundImage)
        let snapContent = SCSDKPhotoSnapContent(snapPhoto: snapPhoto)
        snapContent.attachmentUrl = "https://www.instagram.com/teamgrapevine/"
        snapAPI.startSending(snapContent)
    }
}
