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
        _ = strData.withUnsafeBytes{
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
    alert.titleIconTintColor = Globals.ViewSettings.labelColor
    alert.titleFont = UIFont.boldSystemFont(ofSize: 20)
    alert.messageFont = UIFont.systemFont(ofSize: 17)
    for action in alert.actions {
        alert.button(for: action)?.setTitleFont(UIFont.boldSystemFont(ofSize: 13), for: .normal)
    }
    alert.cornerRadius = 10
    
    alert.backgroundColor = Globals.ViewSettings.backgroundColor
    alert.titleColor = Globals.ViewSettings.labelColor
    alert.messageColor = Globals.ViewSettings.labelColor
    alert.buttonTitleColor = Globals.ViewSettings.labelColor
}

/*
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
*/

func getGradient(color1: UIColor, color2: UIColor) -> CAGradientLayer {
    let gradient = CAGradientLayer()
    gradient.type = .axial
    gradient.colors = [
        color1.cgColor,
        color2.cgColor,
    ]
    gradient.startPoint = CGPoint(x: 0, y: 0)
    gradient.endPoint = CGPoint(x: 1, y: 1)
    return gradient
}

func styleButton(button: UIButton, view: UIView, color1: UIColor, color2: UIColor) -> UIView {
    button.layer.cornerRadius = 10
    button.clipsToBounds = true
    button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    button.setTitleColor(.white, for: .normal)
    button.setTitleColor(.gray, for: .highlighted)
    button.tintColor = .white
    
    let g1: CAGradientLayer = getGradient(color1: color1, color2: color2)
    g1.frame = button.frame
    g1.masksToBounds = true
    g1.cornerRadius = 10
    view.layer.insertSublayer(g1, at: 0)
    return view
}

//set light or dark theme according to presets
func setTheme(curView: UIViewController){
    let defaults = UserDefaults.standard
    if let curTheme = defaults.string(forKey: Globals.userDefaults.themeKey) {
        if (curTheme == "dark") {
            curView.overrideUserInterfaceStyle = .dark
            Globals.ViewSettings.backgroundColor = Constants.Colors.extremelyDarkGrey
            Globals.ViewSettings.labelColor = .white
        } else {
            curView.overrideUserInterfaceStyle = .light
            Globals.ViewSettings.backgroundColor = .white
            Globals.ViewSettings.labelColor = .black
        }
    }
    else {
        curView.overrideUserInterfaceStyle = .light
        Globals.ViewSettings.backgroundColor = .white
        Globals.ViewSettings.labelColor = .black
    }
}

func setStatusBarStyle() -> UIStatusBarStyle {
    let defaults = UserDefaults.standard
    if let curTheme = defaults.string(forKey: Globals.userDefaults.themeKey) {
        if (curTheme == "dark") {
            return .lightContent
        }
        else {
            return .darkContent
        }
    }
    else {
        return .darkContent
    }
}
