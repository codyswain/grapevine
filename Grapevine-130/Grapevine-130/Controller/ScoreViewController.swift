import Foundation
import UIKit
import CoreLocation
import MaterialComponents.MaterialBottomNavigation

/// Manages control flow of the score screen.
class ScoreViewController: UIViewController {
    var score = 0
    var emoji: String?
    var strikesLeftMessage:String?
    var range = 3
    var userManager = UserManager()
    var scoreManager = ScoreManager()
    var indicator = UIActivityIndicatorView()
    var bottomNavBar = MDCBottomNavigationBar()
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
        
        // Add menu navigation bar programatically
        bottomNavBar = prepareBottomNavBar(sender: self, bottomNavBar: bottomNavBar, tab: "Karma")
        self.view.addSubview(bottomNavBar)
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
        let alert = MDCAlertController(title: "Not enough points!", message: "You need \(10 - score) more point(s) to unlock banning powers. Tap the information button at the bottom of the screen for more.")

        alert.addAction(MDCAlertAction(title: "Ok"))
        alert.titleIcon = UIImage(systemName: "x.circle.fill")
        alert.titleIconTintColor = .black
        alert.titleFont = UIFont.boldSystemFont(ofSize: 20)
        alert.messageFont = UIFont.systemFont(ofSize: 17)
        alert.buttonFont = UIFont.boldSystemFont(ofSize: 13)
        alert.buttonTitleColor = Constants.Colors.extremelyDarkGrey
        alert.cornerRadius = 10
        self.present(alert, animated: true)
    }

    /// Displays a popup that let's the user know that they have enough points to ban others and direct them to the ban chamber.
    func alertPurchaseBanPower(){
        let alert = MDCAlertController(title: "Spend Karma", message: "Use your karma for extra abilities on Grapevine.")
                
        let action1 = MDCAlertAction(title: "[10] Ban Chamber: Ban Downvoted Posters") { (action) in
            if self.score >= 10 {
                self.performSegue(withIdentifier: "goToBanChamber", sender: self)
            } else {
                self.alertMessageNotEnoughPoints()
            }
        }
        let action2 = MDCAlertAction(title: "[🔒] Shout: Emphasize Post In Feed") { (action) in
        }
        let action3 = MDCAlertAction(title: "[🔒] Scream: Notify All In Radius") { (action) in
        }
        let action4 = MDCAlertAction(title: "[🔒] Creative Kit: Fonts & Colors") { (action) in
        }
        let action5 = MDCAlertAction(title: "[🔒] Juiced: Receive Double Karma") { (action) in
        }
        let action6 = MDCAlertAction(title: "[🔒] Invest: Share Karma Of Post") { (action) in
        }
        let action7 = MDCAlertAction(title: "[🔒] Defense: Karma Won't Decrease") { (action) in
        }
        let action8
            = MDCAlertAction(title: "Cancel") { (action) in
            print("You've pressed cancel");
        }
        // MCD shows the actions backwards
        alert.addAction(action8)
        alert.addAction(action7)
        alert.addAction(action6)
        alert.addAction(action5)
        alert.addAction(action4)
        alert.addAction(action3)
        alert.addAction(action2)
        alert.addAction(action1)

        alert.titleIcon = UIImage(systemName: "checkmark.circle.fill")
        alert.titleIconTintColor = .black
        alert.titleFont = UIFont.boldSystemFont(ofSize: 20)
        alert.messageFont = UIFont.systemFont(ofSize: 17)
        alert.buttonFont = UIFont.boldSystemFont(ofSize: 13)
        alert.buttonTitleColor = Constants.Colors.extremelyDarkGrey
        alert.cornerRadius = 10
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

extension ScoreViewController: MDCBottomNavigationBarDelegate {
    func bottomNavigationBar(_ bottomNavigationBar: MDCBottomNavigationBar, didSelect item: UITabBarItem) {
        if item.title! == "Posts" {
            self.performSegue(withIdentifier: "scoreToMain", sender: self)
        } else if item.title! == "Karma" {

        } else if item.title! == "Me" {
            self.performSegue(withIdentifier: "scoreToProfile", sender: self)
        }
    }
}
