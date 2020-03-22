import Foundation

import UIKit

/// An object that manages the scores of posts.
struct ScoreManager {
    
    // ⚡🔥👑🥶
    /**
    Describes the user's score.
     
    - Parameter score: The current score earned by a user.
     
    - Returns: An emoji string.
    */
    func getEmoji(score:Int) -> String {
        if (score <= -10){
            return "😭"
        } else if (score <= -5){
            return "😢"
        } else if (score <= 0){
            return "🥱"
        } else if (score <= 1){
            return "😮"
        } else if (score <= 5){
            return "😤"
        } else if (score <= 10){
            return "🤩"
        } else if (score <= 25){
            return "😱"
        } else if (score <= 50){
            return "🤯"
        } else {
            return "👑"
        }
    }
    
    /**
    Describes the number of times as user can make a mistake without getting banned from the platform.
     
    - Parameter strikes: The current number of times the user violated harassment or post policies.
     
    - Returns: A string describing the user's remaining chances.
    */
    func getStrikeMessage(strikes:Int) -> String {
        if strikes <= 0 {
            return "Strikes Left: 3/3"
        } else if strikes == 1 {
            return "Strikes Left: 2/3"
        } else if strikes == 2 {
            return "Strikes Left: 1/3"
        } else {
            return "Strikes Left: 0/3"
        }
    }
}
