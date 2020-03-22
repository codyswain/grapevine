import Foundation
import CommonCrypto.CommonHMAC

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
