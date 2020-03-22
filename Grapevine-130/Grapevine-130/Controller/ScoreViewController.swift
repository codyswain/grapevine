import Foundation
import FirebaseFirestore
import UIKit
import CoreLocation

/// Manages control flow of the score screen.
class ScoreViewController: UIViewController {
    var score = 0
    var emoji: String?
    var strikesLeftMessage:String?
    @IBOutlet weak var emojiLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var strikesLeftLabel: UILabel!
    
    /**
     Allows or disallows the usage of a user's acquired points based on the amount they have.
     
     - Parameter sender: Segue initiator
     */
    @IBAction func usePointsButton(_ sender: Any) {
        score = 100
        if score >= 20 {
            alertPurchaseBanPower()
        } else {
            alertMessageNotEnoughPoints()
        }
    }
    
    /**
     Transitions to the information page that describes how user score can be used.
     
     - Parameter sender: Segue intiator
     */
    @IBAction func infoButton(_ sender: Any) {
        self.performSegue(withIdentifier: "scoreToInfo", sender: self)
    }
        
    /// Intializes the score screen.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emojiLabel.text = emoji
        scoreLabel.text = String(score)
        strikesLeftLabel.text = strikesLeftMessage
    }
    
    /**
     Prepares the score screen prior to transitioning.
     
     - Parameter sender: Segue initiator
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "scoreToInfo" {
            let destinationVC = segue.destination as! InfoScreenViewController
            destinationVC.score = score
            destinationVC.emoji = emoji
            destinationVC.strikesLeftMessage = strikesLeftMessage
        }
    }
    
    /// Displays a popup that let's the user know that they do not have enough points to ban other users.
    func alertMessageNotEnoughPoints(){
        let alert = UIAlertController(title: "Not enough points!", message: "You need \(20 - score) more point(s) to unlock banning powers. Tap the information button at the bottom of the screen for more.", preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        alert.view.tintColor = Constants.Colors.darkPurple
        self.present(alert, animated: true)
    }

    /// Displays a popup that let's the user know that they have enough points to ban others and direct them to the ban chamber.
    func alertPurchaseBanPower(){
        let alert = UIAlertController(title: "Spend Points", message: "Use your points for the ability to ban someone who has negatively contributed to the community.", preferredStyle: .alert)
                
        let action1 = UIAlertAction(title: "Enter Ban Chamber (20 Points)", style: .default) { (action:UIAlertAction) in
            self.performSegue(withIdentifier: "goToBanChamber", sender: self)
        }

        let action2 = UIAlertAction(title: "Cancel", style: .destructive) { (action:UIAlertAction) in
            print("You've pressed cancel");
        }

        alert.addAction(action1)
        alert.addAction(action2)
        alert.view.tintColor = Constants.Colors.darkPurple
        self.present(alert, animated: true, completion: nil)

    }
}
