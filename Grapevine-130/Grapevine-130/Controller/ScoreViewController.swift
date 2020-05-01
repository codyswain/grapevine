import Foundation
import UIKit
import CoreLocation

/// Manages control flow of the score screen.
class ScoreViewController: UIViewController {
    var score = 0
    var emoji: String?
    var strikesLeftMessage:String?
    var range = 3
    var userManager = UserManager()
    var scoreManager = ScoreManager()
    var indicator = UIActivityIndicatorView()
    @IBOutlet weak var emojiLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var strikesLeftLabel: UILabel!
    
    /**
     Allows or disallows the usage of a user's acquired points based on the amount they have.
     
     - Parameter sender: Segue initiator
     */
    @IBAction func usePointsButton(_ sender: Any) {
        alertPurchaseBanPower()
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
        
        // Show loading symbol
        activityIndicator()
        indicator.startAnimating()
        indicator.backgroundColor = .white
        
        emojiLabel.isHidden = true
        scoreLabel.isHidden = true
        strikesLeftLabel.isHidden = true
        
        userManager.delegate = self
        userManager.fetchUser()
        
    }
    
    /// Displays a loading icon while posts load.
    func activityIndicator() {
        indicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        indicator.style = UIActivityIndicatorView.Style.medium
        indicator.center = self.view.center
        self.view.addSubview(indicator)
    }
    
    /**
     Prepares the score screen prior to transitioning.
     
     - Parameter sender: Segue initiator
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToBanChamber" {
            let destinationVC = segue.destination as! BanChamberViewController
            destinationVC.range = range
        }
    }
    
    /// Displays a popup that let's the user know that they do not have enough points to ban other users.
    func alertMessageNotEnoughPoints(){
        let alert = UIAlertController(title: "Not enough points!", message: "You need \(10 - score) more point(s) to unlock banning powers. Tap the information button at the bottom of the screen for more.", preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        alert.view.tintColor = Constants.Colors.darkPurple
        self.present(alert, animated: true)
    }

    /// Displays a popup that let's the user know that they have enough points to ban others and direct them to the ban chamber.
    func alertPurchaseBanPower(){
        let alert = UIAlertController(title: "Spend Karma", message: "Use your karma for extra abilities on Grapevine.", preferredStyle: .alert)
                
        let action1 = UIAlertAction(title: "[10] Ban Chamber: Ban Downvoted Posters", style: .default) { (action:UIAlertAction) in
            if self.score >= 10 {
                self.performSegue(withIdentifier: "goToBanChamber", sender: self)
            } else {
                self.alertMessageNotEnoughPoints()
            }
        }
        let action2 = UIAlertAction(title: "[🔒] Shout: Emphasize Post In Feed", style: .default) { (action:UIAlertAction) in
        }
        let action3 = UIAlertAction(title: "[🔒] Scream: Notify All In Radius", style: .default) { (action:UIAlertAction) in
        }
        let action4 = UIAlertAction(title: "[🔒] Creative Kit: Fonts & Colors", style: .default) { (action:UIAlertAction) in
        }
        let action5 = UIAlertAction(title: "[🔒] Juiced: Receive Double Karma", style: .default) { (action:UIAlertAction) in
        }
        let action6 = UIAlertAction(title: "[🔒] Invest: Share Karma Of Post", style: .default) { (action:UIAlertAction) in
        }
        let action7 = UIAlertAction(title: "[🔒] Defense: Karma Won't Decrease", style: .default) { (action:UIAlertAction) in
        }
        let action8
            = UIAlertAction(title: "Cancel", style: .destructive) { (action:UIAlertAction) in
            print("You've pressed cancel");
        }
        alert.addAction(action1)
        alert.addAction(action2)
        alert.addAction(action3)
        alert.addAction(action4)
        alert.addAction(action5)
        alert.addAction(action6)
        alert.addAction(action7)
        alert.addAction(action8)

        alert.view.tintColor = Constants.Colors.darkPurple
        self.present(alert, animated: true, completion: nil)

    }
}

extension ScoreViewController: UserManagerDelegate {
    func didGetUser(_ userManager: UserManager, user: User) {
        self.score = user.score
        self.emoji = scoreManager.getEmoji(score:self.score)
        self.strikesLeftMessage = scoreManager.getStrikeMessage(strikes:user.strikes)
        
        DispatchQueue.main.async {
            self.indicator.stopAnimating()
            self.emojiLabel.text = self.emoji
            self.scoreLabel.text = String(self.score)
            self.strikesLeftLabel.text = self.strikesLeftMessage
            self.emojiLabel.isHidden = false
            self.scoreLabel.isHidden = false
            self.strikesLeftLabel.isHidden = false
        }
        print("got user")
    }
    
    func didBanUser(_ userManager: UserManager) {}
    func userDidFailWithError(error: Error) {
        
    }
}
