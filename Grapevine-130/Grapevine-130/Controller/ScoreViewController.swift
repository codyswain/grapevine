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
        self.performSegue(withIdentifier: "scoreToKarmaOptions", sender: self)
    }
    
    /**
     Transitions to the information page that describes how user score can be used.
     
     - Parameter sender: Segue intiator
     */
    @IBAction func infoButton(_ sender: Any) {
        let alert = MDCAlertController(title: "More Information", message: "On Grapevine, karma is the sum of your comments' & posts' votes. Unlike other platforms, your karma can be spent on powers that make the platform more useful. \n\nTo prevent bullying, Grapevine institues a strike system. Each user starts off with 0 strikes. If a user reaches 3 strikes, they will be banned for 24 hours and have their strikes reset. \n\nThere are three ways to get strikes. (1) If a post is deemed bullying by our systems/staff, the creator will automatically get 3 strikes and be banned. (2) If a post is heavily downvoted and a different user uses their karma, the offender again gets 3 strikes and is banned. (3) If one upvotes a post that falls under one of the above, they will get a strike.")
        alert.addAction(MDCAlertAction(title: "Ok"))
        alert.titleIcon = UIImage(systemName: "info.circle.fill")
        alert.titleIconTintColor = .black
        alert.titleFont = UIFont.boldSystemFont(ofSize: 20)
        alert.messageFont = UIFont.systemFont(ofSize: 17)
        alert.buttonFont = UIFont.boldSystemFont(ofSize: 13)
        alert.buttonTitleColor = Constants.Colors.extremelyDarkGrey
        alert.cornerRadius = 10
        self.present(alert, animated: true)
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
        if segue.identifier == "scoreToKarmaOptions" {
            let destinationVC = segue.destination as! KarmaOptionsViewController
            destinationVC.score = self.score
        }
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
    
    func didUpdateUser(_ userManager: UserManager) {}
    func userDidFailWithError(error: Error) {
        
    }
}

extension ScoreViewController: MDCBottomNavigationBarDelegate {
    func bottomNavigationBar(_ bottomNavigationBar: MDCBottomNavigationBar, didSelect item: UITabBarItem) {
        if item.tag == 0  {
            bottomNavBar.selectedItem = bottomNavBar.items[0]
            self.performSegue(withIdentifier: "scoreToMain", sender: self)
        } else if item.tag == 1 {
            bottomNavBar.selectedItem = bottomNavBar.items[1]
        } else if item.tag == 2 {
            bottomNavBar.selectedItem = bottomNavBar.items[1]
            self.performSegue(withIdentifier: "karmaToCreatePost", sender: self)
        } else if item.tag == 3 {
            bottomNavBar.selectedItem = bottomNavBar.items[3]
            self.performSegue(withIdentifier: "karmaToChat", sender: self)
        } else if item.tag == 4 {
            bottomNavBar.selectedItem = bottomNavBar.items[4]
            self.performSegue(withIdentifier: "scoreToProfile", sender: self)
        }
    }
}
