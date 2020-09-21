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
        
        let labelFrame = CGRect(x: (UIScreen.main.nativeBounds.width/2) - 500, y: UIScreen.main.nativeBounds.height*(1/2) - (height/2) - 200, width: 1000, height: 100)
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
    
    func createInstaBackgroundImage(_ postType: String, _ city: String, _ height: CGFloat) -> UIImage? {
        let frame = CGRect(x: 0, y: 0, width: UIScreen.main.nativeBounds.width, height: UIScreen.main.nativeBounds.height)
        let mainView = UIView(frame: frame)
        mainView.backgroundColor = .white
        
        let labelFrame = CGRect(x: (UIScreen.main.nativeBounds.width/2) - 500, y: UIScreen.main.nativeBounds.height*(1/2) - (height/2) - 40, width: 1000, height: 100)
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
        
        let labelFrameBottom = CGRect(x: (UIScreen.main.nativeBounds.width/2) - 500, y: UIScreen.main.nativeBounds.height*(5/6), width: 1000, height: 100)
        let textLabelBottom = UILabel(frame:labelFrameBottom)
        textLabelBottom.numberOfLines = 0
        textLabelBottom.textAlignment = .center
        textLabelBottom.textColor = .black
        textLabelBottom.font = UIFont.systemFont(ofSize: 25)
        textLabelBottom.text = "Download Grapevine on the App Store for more ⚡"
        mainView.addSubview(textLabelBottom)

        UIGraphicsBeginImageContext(frame.size)
        
        if let currentContext = UIGraphicsGetCurrentContext() {
            mainView.layer.render(in: currentContext)
            let nameImage = UIGraphicsGetImageFromCurrentImageContext()
            return nameImage
        }
        return nil
    }
    
    func shareToSnap(_ backgroundImage: UIImage, _ stickerImage: UIImage) {
        let snapPhoto = SCSDKSnapPhoto(image: backgroundImage)
        let snapContent = SCSDKPhotoSnapContent(snapPhoto: snapPhoto)
        snapContent.attachmentUrl = "https://www.instagram.com/teamgrapevine/"
        let sticker = SCSDKSnapSticker(stickerImage: stickerImage)
        snapContent.sticker = sticker
        snapAPI.startSending(snapContent)
    }
    
    func shareCommentsToSnap(_ backgroundImage: UIImage) {
        let snapPhoto = SCSDKSnapPhoto(image: backgroundImage)
        let snapContent = SCSDKPhotoSnapContent(snapPhoto: snapPhoto)
        snapContent.attachmentUrl = "https://www.instagram.com/teamgrapevine/"
        snapAPI.startSending(snapContent)
    }
    
    func shareToInstagram(_ backgroundImage: UIImage, _ stickerImage: UIImage){
        let url = URL(string: "instagram-stories://share")!
        if UIApplication.shared.canOpenURL(url){
            let backgroundData = backgroundImage
            let stickerData = stickerImage.pngData()!
            let pasteBoardItems = [
                ["com.instagram.sharedSticker.backgroundImage" : backgroundData,
                "com.instagram.sharedSticker.stickerImage" : stickerData]
            ]
            
            if #available(iOS 10.0, *) {
                UIPasteboard.general.setItems(pasteBoardItems, options: [.expirationDate: Date().addingTimeInterval(60 * 5)])
            } else {
                UIPasteboard.general.items = pasteBoardItems
            }
            UIApplication.shared.open(url)
        }
    }
    
    func shareCommentsToInstagram(_ backgroundImage: UIImage){
        let url = URL(string: "instagram-stories://share")!
        if UIApplication.shared.canOpenURL(url){
            let backgroundData = backgroundImage
            let pasteBoardItems = [["com.instagram.sharedSticker.backgroundImage" : backgroundData,]]
            
            if #available(iOS 10.0, *) {
                UIPasteboard.general.setItems(pasteBoardItems, options: [.expirationDate: Date().addingTimeInterval(60 * 5)])
            } else {
                UIPasteboard.general.items = pasteBoardItems
            }
            UIApplication.shared.open(url)
        }
    }
}
