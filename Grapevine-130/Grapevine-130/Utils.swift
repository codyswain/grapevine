import Foundation
import UIKit
import CommonCrypto.CommonHMAC
import MaterialComponents.MaterialDialogs

/**
Hashes strings with SHA256.
 
- Parameter data: Value to be hashed in string format.

- Returns: Hashed version of `data`.
*/
func SHA256(data: String) -> String {
    var sha256String = ""
    if let strData = data.data(using: String.Encoding.utf8) {
        var digest = [UInt8](repeating: 0, count:Int(CC_SHA256_DIGEST_LENGTH))
        strData.withUnsafeBytes {
            CC_SHA256($0.baseAddress, UInt32(strData.count), &digest)
        }
        
        for byte in digest {
            sha256String += String(format:"%02x", UInt8(byte))
        }
    }
    return sha256String
}

func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage {
    let scale = newWidth / image.size.width
    let newHeight = image.size.height * scale
    UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
    image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return newImage!
}

func makePopup(alert: MDCAlertController, image: String) {
    alert.titleIcon = UIImage(systemName: image)
    alert.titleIconTintColor = .black
    alert.titleFont = UIFont.boldSystemFont(ofSize: 20)
    alert.messageFont = UIFont.systemFont(ofSize: 17)
    alert.buttonFont = UIFont.boldSystemFont(ofSize: 13)
    alert.buttonTitleColor = Constants.Colors.extremelyDarkGrey
    alert.cornerRadius = 10
}

func decodeImage(imageData: Data, width: CGFloat, height: CGFloat) -> UIImage {
    let image = UIImage(data: imageData)!
    let scale: CGFloat
    
    // Scale the image to fit the post cell
    if image.size.width > image.size.height {
        scale = width / image.size.width
    } else {
        scale = height / image.size.height
    }
    
    let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
    let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
    
    UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
    image.draw(in: rect)
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return newImage!
}
