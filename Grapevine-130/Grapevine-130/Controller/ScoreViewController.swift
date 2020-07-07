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
    fileprivate let pictures = [#imageLiteral(resourceName: "Grapevine Store Card 1"),#imageLiteral(resourceName: "Grapevine Store Card 2"), #imageLiteral(resourceName: "Grapevine Store Card 3")]
    
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
        let alert = MDCAlertController(title: "Karma & Strikes", message: "Karma is the sum of your comments' & posts' votes. Unlike other platforms, your karma can be spent on powers that make the platform more useful. \n\nTo prevent bullying, Grapevine institues a strike system. Each user starts off with 0 strikes. If a user reaches 3 strikes, they will be banned for 24 hours and have their strikes reset. \n\nThere are three ways to get strikes. (1) If a post is deemed bullying by our systems/staff, the creator will automatically get 3 strikes and be banned. (2) If a post is heavily downvoted and a different user uses their karma, the offender again gets 3 strikes and is banned. (3) If one upvotes a post that falls under one of the above, they will get a strike.")
        alert.backgroundColor = .systemBackground
        alert.addAction(MDCAlertAction(title: "Ok"))
        alert.titleColor = .label
        alert.messageColor = .label
        alert.buttonTitleColor = .label
        makePopup(alert: alert, image: "info.circle.fill")
        self.present(alert, animated: true)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        //Changes colors of status bar so it will be visible in dark or light mode
        if Globals.ViewSettings.CurrentMode == .dark {
            return .lightContent
        }
        else{
            return .darkContent
        }
    }
        
    /// Intializes the score screen.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set dark/light mode
        if Globals.ViewSettings.CurrentMode == .dark {
            super.overrideUserInterfaceStyle = .dark
        }
        else if Globals.ViewSettings.CurrentMode == .light {
            super.overrideUserInterfaceStyle = .light
        }
        
        // Show user that data is loading
        self.scoreLabel.text = "⌛..."
        self.emojiLabel.text = ""
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
        
        view.addSubview(collectionView)
        collectionView.backgroundColor = UIColor(red:1, green:1, blue:1, alpha:0)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.topAnchor.constraint(equalTo: scoreContainer.bottomAnchor, constant:20).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
//        collectionView.bottomAnchor.constraint(equalTo: bottomNavBar.topAnchor, constant:-20).isActive = true
        collectionView.heightAnchor.constraint(lessThanOrEqualToConstant: view.frame.height*0.5).isActive = true
        collectionView.showsHorizontalScrollIndicator = false
    }
    
    class MyCollectionViewFlowLayout : UICollectionViewFlowLayout{
        override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
            var offsetAdjustment = CGFloat.greatestFiniteMagnitude
            let horizontalOffset = proposedContentOffset.x
            let targetRect = CGRect(origin: CGPoint(x: proposedContentOffset.x, y: 0), size: self.collectionView!.bounds.size)

            for layoutAttributes in super.layoutAttributesForElements(in: targetRect)! {
                let itemOffset = layoutAttributes.frame.origin.x
                if (abs(itemOffset - horizontalOffset) < abs(offsetAdjustment)) {
                    offsetAdjustment = itemOffset - horizontalOffset
                }
            }

            return CGPoint(x: proposedContentOffset.x + offsetAdjustment - self.collectionView!.bounds.width * 0.055, y: proposedContentOffset.y)
        }
    }
    
    fileprivate let collectionView:UICollectionView = {
            let layout = MyCollectionViewFlowLayout()
            layout.scrollDirection = .horizontal
            let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
            collectionView.translatesAutoresizingMaskIntoConstraints = false
            collectionView.register(CustomCell.self, forCellWithReuseIdentifier: "Cell")
            collectionView.isPagingEnabled = false // must be disabled for our custom paging
            collectionView.decelerationRate = UIScrollView.DecelerationRate.fast
            return collectionView
        }()
    
    /// Displays a loading icon while posts load.
    func activityIndicator() {
        indicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        indicator.style = UIActivityIndicatorView.Style.medium
        indicator.center = self.view.center
        self.view.addSubview(indicator)
    }
    
    /// Displays a popup that let's the user know that they do not have enough points to ban other users.
    func alertMessageNotEnoughPoints(){
        let alert = MDCAlertController(title: "Not enough points!", message: "You need \(10 - score) more point(s) to unlock banning powers. Tap the information button at the bottom of the screen for more.")
        
        alert.backgroundColor = .systemBackground
        alert.titleColor = .label
        alert.messageColor = .label
        alert.addAction(MDCAlertAction(title: "Ok"))
        makePopup(alert: alert, image: "x.circle.fill")
        self.present(alert, animated: true)
    }
}

extension UIView {
    func fadeTransition(_ duration:CFTimeInterval) {
        let animation = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name:
            CAMediaTimingFunctionName.easeInEaseOut)
        animation.type = CATransitionType.fade
        animation.duration = duration
        layer.add(animation, forKey: CATransitionType.fade.rawValue)
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



extension ScoreViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width*0.8, height: view.frame.height * 0.5)
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell",
                                                    for: indexPath) as! CustomCell
        cell.isSelectable = false
        cell.cornerRadius = 10
        cell.setShadowElevation(ShadowElevation(rawValue: 0), for: .normal)
        cell.image = self.pictures[indexPath.item]

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // do something when item was selected
        let selectedCell = indexPath.row
        if selectedCell == 0 {
            if self.score >= 10 {
                self.performSegue(withIdentifier: "scoreToBanChamber", sender: self)
            } else {
                self.alertMessageNotEnoughPoints(pointsNeeded: 10)
            }
        } else if selectedCell == 1 {
            if self.score >= 10 {
                self.performSegue(withIdentifier: "scoreToShoutChamber", sender: self)
            } else {
                self.alertMessageNotEnoughPoints(pointsNeeded: 10)
            }
        } else if selectedCell == 2 {
            
        }
    }
    
    /// Displays a popup that let's the user know that they do not have enough points to ban other users.
    func alertMessageNotEnoughPoints(pointsNeeded: Int){
        let alert = MDCAlertController(title: "Not enough points!", message: "You need \(pointsNeeded - score) more point(s).")

        alert.addAction(MDCAlertAction(title: "Ok"))
        alert.backgroundColor = .systemBackground
        alert.titleColor = .label
        alert.messageColor = .label
        alert.titleIcon = UIImage(systemName: "x.circle.fill")
        alert.titleIconTintColor = .label
        alert.titleFont = UIFont.boldSystemFont(ofSize: 20)
        alert.messageFont = UIFont.systemFont(ofSize: 17)
        alert.buttonFont = UIFont.boldSystemFont(ofSize: 13)
        alert.buttonTitleColor = UIColor.label
        alert.cornerRadius = 10
        self.present(alert, animated: true)
    }

}


class CustomCell: MDCCardCollectionCell {
    var image: UIImage? {
        didSet {
            guard let im = image else { return }
            bg.image = im
        }
    }
    
    fileprivate let bg: UIImageView = {
       let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 10
        return iv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        contentView.addSubview(bg)
        bg.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        bg.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
        bg.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
        bg.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
    }
    
    // Xcode required me to have this
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
