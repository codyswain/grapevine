import Foundation
import UIKit
import CoreLocation
import MaterialComponents.MaterialBottomNavigation
import MaterialComponents.MaterialCards

/// Manages control flow of the score screen.
class ScoreViewController: UIViewController {
    var score = 0
    var emoji: String?
    var strikesLeftMessage:String?
    var range = 3.0
    var userManager = UserManager()
    var scoreManager = ScoreManager()
    var indicator = UIActivityIndicatorView()
    var bottomNavBar = MDCBottomNavigationBar()
    
    
    @IBOutlet weak var scoreContainer: UIView!
    
    // Create an instance of UserDefaults that will serve as local storage
    let userDefaults = UserDefaults.standard
    
    // Future options: [🔒] Creative Kit: Fonts & Colors"), [🔒] Juiced: Receive Double Karma"), [🔒] Invest: Share Karma Of Post"), [🔒] Defense: Karma Won't Decrease")
    
    @IBOutlet weak var emojiLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var strikesLeftLabel: UILabel!
    
    /**
     Allows or disallows the usage of a user's acquired points based on the amount they have.
     
     - Parameter sender: Segue initiator
     */
    
    /**
     Transitions to the information page that describes how user score can be used.
     
     - Parameter sender: Segue intiator
     */
    @IBAction func infoButton(_ sender: Any) {
        let alert = MDCAlertController(title: "Karma & Strikes", message: "Karma is the sum of your comments' & posts' votes. Unlike other platforms, your karma can be spent on abilities that make the platform more useful. \n\nTo prevent bullying, Grapevine institues a strike system. Each user starts off with 0 strikes. If a user reaches 3 strikes, they will be banned for 12 hours and have their strikes reset. \n\nThere are three ways to get strikes. (1) If a post is deemed bullying by our systems/staff, the creator will automatically get 3 strikes and be banned. (2) If a post is heavily downvoted and a different user uses their karma, the offender again gets 3 strikes and is banned. (3) If one upvotes a post that falls under one of the above, they will get a strike.")
        alert.addAction(MDCAlertAction(title: "Ok"))
        makePopup(alert: alert, image: "info.circle.fill")
        self.present(alert, animated: true)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return setStatusBarStyle()
    }
        
    /// Intializes the score screen.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set dark/light mode from persistent storage
        setTheme(curView: self)
        
        // Show user that data is loading
        self.scoreLabel.text = "..."
        self.emojiLabel.text = "⌛⌛⌛"
        self.strikesLeftLabel.text = "Loading karma details!"

        // Show loading symbol
        activityIndicator()
        indicator.startAnimating()
        indicator.backgroundColor = .systemBackground
                        
        userDefaults.removeObject(forKey: "karma")
        if (self.userDefaults.string(forKey: "karma") == nil) {
            self.userDefaults.set(self.score, forKey:"karma")
        }
        
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
    
    @IBAction func karmaAbilitiesViewButtonPressed(_ sender: Any) {
        self.performSegue(withIdentifier: "scoreToKarmaView", sender: self)
    }
    
}

extension ScoreViewController: UserManagerDelegate {
    func didGetUser(_ userManager: UserManager, user: User) {
        self.score = user.score
        /// saving the karma for the user in local storage under variable name: karma
        
        self.emoji = scoreManager.getEmoji(score:self.score)
        self.strikesLeftMessage = scoreManager.getStrikeMessage(strikes:user.strikes)
        
        DispatchQueue.main.async {
            self.indicator.stopAnimating()
            self.emojiLabel.text = self.emoji
            self.scoreLabel.fadeTransition(0.4)
            self.scoreLabel.text = String(self.score)
            self.userDefaults.set(self.score, forKey: "karma")
            
            
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
            self.performSegue(withIdentifier: "karmaToCreatePost", sender: self)
        } else {
            bottomNavBar.selectedItem = bottomNavBar.items[2]
            self.performSegue(withIdentifier: "scoreToProfile", sender: self)
        }
    }
}
