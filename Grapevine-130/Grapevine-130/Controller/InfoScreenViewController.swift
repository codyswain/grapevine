import Foundation
import UIKit
import CoreLocation

/// Manages control flow of the score screen.
class InfoScreenViewController: UIViewController {
    var score = 0
    var emoji: String?
    var strikesLeftMessage:String?
    
    /**
     Loads the score screen prior to transitioning from the current screen.
     
     - Parameters:
        - sender: Current screen
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "infoToScore" {
            let destinationVC = segue.destination as! ScoreViewController
            destinationVC.score = score
            destinationVC.emoji = emoji
            destinationVC.strikesLeftMessage = strikesLeftMessage
        }
    }

    /// Intializes the score screen.
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
