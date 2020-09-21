import UIKit
import SwiftUI
import CoreLocation
import MaterialComponents.MaterialBottomNavigation
import MaterialComponents.MaterialButtons
import MaterialComponents.MaterialButtons_Theming

protocol ViewControllerDelegate {
    func setGroupView(groupName: String, groupID: String)
}

/// Manages the main workflow.
class ViewController: UIViewController {
    
    // MARK: Properties
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var nearbyLabel: UILabel!
    @IBOutlet weak var rangeButton: UIButton!
    @IBOutlet weak var groupsButton: UIButton!
    
    @IBOutlet weak var filterButton: UIButton!
    @IBOutlet weak var postTypeButton: UIButton!
    @IBOutlet weak var abilitiesBackgroundView: UIView!
    @IBOutlet weak var abilitiesStackView: UIStackView!
    
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var grapevineLogo: UIImageView!
    @IBOutlet weak var filterStackview: UIStackView!
    
    @IBOutlet weak var pushButton: UIImageView!
    @IBOutlet weak var burnButton: UIImageView!
    @IBOutlet weak var shoutButton: UIImageView!
    
    @IBOutlet weak var pushButtonView: UIView!
    @IBOutlet weak var burnButtonView: UIView!
    @IBOutlet weak var shoutButtonView: UIView!
    
    @IBOutlet weak var currentAbilityTitle: UILabel!
    @IBOutlet weak var currentAbilityDescription: UITextView!
    @IBOutlet weak var applyAbilityButton: UIImageView!
    
    @IBOutlet weak var burnAbilityIndicator: UIImageView!
    @IBOutlet weak var karmaAmountLabel: UITextField!
    
    // MARK: Variable Definitions
    let locationManager = CLLocationManager()
    var posts: [Post] = []
    var ref = ""
    var canGetMorePosts = true
    var range = 3.0
    var groupName = Globals.ViewSettings.groupName
    var groupID = Globals.ViewSettings.groupID
    var groupsManager = GroupsManager()
    var postsManager = PostsManager()
    var scrollPostsManager = PostsManager()
    var storyManager = StoryManager()
    var user: User?
    var userManager = UserManager()
    var scoreManager = ScoreManager()
    var lat:CLLocationDegrees = 0.0
    var lon:CLLocationDegrees = 0.0
    var currentCity:String = "me" // "Anonymous said near me"
    var currentFilterState: String = "new" //Options: "new," "top"
    lazy var refresher: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = .label
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return refreshControl
    }()
    var indicator = UIActivityIndicatorView()
    
    //for reloading cell for abilities
    var selectedIndex: IndexPath?
    var overrideShout = false
    
    // Post clicked to view comments
    var selectedPost: Post?
    
    // We take a screenshot of each cell before opening the comment view of that
    // cell because we need to find out roughly how 'tall' the text is.
    // We use the screenshot height to do that
    var selectedPostScreenshot: UIImage?
    
    // Floating button
    var addButton = MDCFloatingButton()
    
    // Add the bottom nav bar, which is done in BottomNavBarMenu.swift
    lazy var bottomNavBar: UITabBar = {
          let tab = UITabBar()
          self.view.addSubview(tab)
          tab.translatesAutoresizingMaskIntoConstraints = false
          tab.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
          tab.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
          tab.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true //This line will change in second part of this post.
          return tab
      }()
    
    // Default feed only shows text posts
    var curPostType: String = "text"
    
    // Variables to track scroll motion
    var originalNavbarPosition: CGFloat = 0.0
    var prevPos: CGFloat = 0.0
    var prevTime: DispatchTime = DispatchTime.now()
    var scrollVelocity: CGFloat = 0.0
    var notScrolling: Bool = true;
    
    // Change the view of the current page
    var currentMode = "default" // options: default, myPosts, myComments
    
    // Variables for tracking current select ability
    var currentAbility: String = "push"
    

    //used for expanding a cell
    var expandAtIndex: IndexPath?
    var expandedCellHeight: CGFloat?
    var expandNextCell = false
    var shrinkNextCell = false

    //for reloading cell after comment
    var commentCellIndexPath: IndexPath?
    
    var goStraightToKarma = false

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return setStatusBarStyle()
    }
    
    // For observing when app enters foreground (for notifications)
    private var observer: NSObjectProtocol?
    
    // MARK: View Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Keep filter stack buttons from changing color when alert is presented
        filterButton.tintAdjustmentMode = .normal
        rangeButton.tintAdjustmentMode = .normal
        postTypeButton.tintAdjustmentMode = .normal
        
        // Disable Groups until Better Developed
        groupsButton.isUserInteractionEnabled = false
        groupsButton.isHidden = true
        
        // Set dark/light mode from persistent storage
        setTheme(curView: self)
        
        // Set opacity of the background for abilities
        abilitiesBackgroundView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.98)
        
        // Show loading symbol
        activityIndicator()
        indicator.startAnimating()
        
        var layer = getGradient(color1: #colorLiteral(red: 0.963324368, green: 0.4132775664, blue: 0.9391091466, alpha: 1), color2: UIColor(named: "GrapevinePurple")!)
        
        if let curTheme = UserDefaults.standard.string(forKey: Globals.userDefaults.themeKey){
            if (curTheme == "dark") {
                indicator.backgroundColor = .black
                //bufferView.backgroundColor = .black
                //self.view.backgroundColor = .black
                layer = getGradient(color1: .purple, color2: UIColor(named: "GrapevinePurple")!)
            }
            else {
                indicator.backgroundColor = .systemGray6
                //bufferView.backgroundColor = .systemGray6
                //self.view.backgroundColor = .systemGray6
                layer = getGradient(color1: #colorLiteral(red: 0.963324368, green: 0.4132775664, blue: 0.9391091466, alpha: 1), color2: UIColor(named: "GrapevinePurple")!)
            }
        }
//        layer.cornerRadius = 5
//        headerView.layer.insertSublayer(layer, at: 0)
        
        //Animated Gradient
//        let childView = UIHostingController(rootView: GradientView())
//        addChild(childView)
//        childView.view.frame = CGRect(x: -50, y: -400, width: headerView.frame.width + 100, height: view.frame.height)
//        headerView.insertSubview(childView.view, at: 0)
//        childView.didMove(toParent: self)
        
        
        //view colors
        // Karma label
//        self.view.backgroundColor = UIColor(named: "GrapevinePurple")
//        self.karmaAmountLabel.layer.borderColor = UIColor.white.cgColor
//        self.karmaAmountLabel.layer.borderWidth = 1
//        self.karmaAmountLabel.layer.cornerRadius = 5
        
//        headerView.layer.cornerRadius = 5

//        self.nearbyLabel.textColor = .purple
//        self.groupsButton.tintColor = .purple
//        self.groupsButton.setTitleColor(.purple, for: .normal)
//        self.filterButton.tintColor = .purple
//        self.filterButton.setTitleColor(.purple, for: .normal)
//        self.rangeButton.tintColor = .purple
//        self.rangeButton.setTitleColor(.purple, for: .normal)
//        self.postTypeButton.tintColor = .purple
//        self.postTypeButton.setTitleColor(.purple, for: .normal)
        
        // Load user defaults into post filters
        setInitialPostFilters()

        // Prepare table
        prepareTableView()

        // Get the location of the user and posts based on that (if they are not banned)
        getLocationAndPosts()
        
        // Add scroll-to-top button
        let tapGestureRecognizer1 = UITapGestureRecognizer(target: self, action: #selector(scrollToTop))
        nearbyLabel.addGestureRecognizer(tapGestureRecognizer1)
        
        let tapGestureRecognizer2 = UITapGestureRecognizer(target: self, action: #selector(changeRange(tapGestureRecognizer:)))
        rangeButton.addGestureRecognizer(tapGestureRecognizer2)
        
        let tapGestureRecognizer3 = UITapGestureRecognizer(target: self, action: #selector(changePostType(tapGestureRecognizer:)))
        postTypeButton.addGestureRecognizer(tapGestureRecognizer3)
                
        let tapGestureRecognizerPush = UITapGestureRecognizer(target: self, action: #selector(pushButtonTapped(tapGestureRecognizer:)))
        pushButton.addGestureRecognizer(tapGestureRecognizerPush)
        
        let tapGestureRecognizerBurn = UITapGestureRecognizer(target: self, action: #selector(burnButtonTapped(tapGestureRecognizer:)))
        burnButton.addGestureRecognizer(tapGestureRecognizerBurn)
        
        let tapGestureRecognizerShout = UITapGestureRecognizer(target: self, action: #selector(shoutButtonTapped(tapGestureRecognizer:)))
        shoutButton.addGestureRecognizer(tapGestureRecognizerShout)
        
        let tapGestureRecognizerExitAbility = UITapGestureRecognizer(target: self, action: #selector(abilitiesViewTapped(tapGestureRecognizer:)))
        abilitiesBackgroundView.addGestureRecognizer(tapGestureRecognizerExitAbility)
        
        let tapGestureRecognizerApplyAbility = UITapGestureRecognizer(target: self, action: #selector(applyAbilityTapped(tapGestureRecognizer:)))
        applyAbilityButton.addGestureRecognizer(tapGestureRecognizerApplyAbility)
        
        let tapGestureRecognizerKarmaLabel = UITapGestureRecognizer(target: self, action: #selector(karmaLabelTapped(tapGestureRecognizer:)))
        karmaAmountLabel.addGestureRecognizer(tapGestureRecognizerKarmaLabel)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPressGesture.minimumPressDuration = 0.3
        self.tableView.addGestureRecognizer(longPressGesture)
        
        // ViewController is used as the homepage but also the MyPosts page, so the appearance changes based on that
        changeAppearanceBasedOnMode()
        
//        // If user launches app via notification, open comment view controller
//        let defaults = UserDefaults.standard
//
//        if let notificationPostID = defaults.string(forKey: "notificationPostID") {
//            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier) as! PostTableViewCell
//            let cellImage = cell.createTableCellImage()
//            self.selectedPostScreenshot = cellImage
//            defaults.removeObject(forKey: "notificationPostID")
//            self.postsManager.fetchSinglePost(postID: notificationPostID, groupID: "Grapevine")
//        }
        openNotificationPost()
        
        observer = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [unowned self] notification in
                openNotificationPost()
        }
    }
    
    // If user launches app via notification, open comment view controller
    func openNotificationPost(){
        let defaults = UserDefaults.standard
        if let notificationPostID = defaults.string(forKey: "notificationPostID") {
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier) as! PostTableViewCell
            let cellImage = cell.createTableCellImage()
            self.selectedPostScreenshot = cellImage
            defaults.removeObject(forKey: "notificationPostID")
            self.postsManager.fetchSinglePost(postID: notificationPostID, groupID: "Grapevine")
        }
    }
    
    @objc func karmaLabelTapped(tapGestureRecognizer: UITapGestureRecognizer){
        goStraightToKarma = true
        performSegue(withIdentifier: "mainViewToScoreView", sender: self)
        
    }
    
    // Display notification alert. Location alert is handled by location manager callback function
    // https://stackoverflow.com/questions/48796561/how-to-ask-notifications-permissions-if-denied
    override func viewDidAppear(_ animated: Bool) {
        if Globals.ViewSettings.showNotificationAlert {
            displayNotificationAlert()
            Globals.ViewSettings.showNotificationAlert = false
            return
        }
    }
    
    // MARK: View Utilities
    func displayNotificationAlert() {
        let alert = MDCAlertController(title: "Enable Notification Services", message: "Notifications are a critical part of the usefulness of Grapevine so that you know what people are saying around you. The app itself will never give you notifications for spam or promotions, only when actual people communicate to you through the app. Please hit this button to go to settings to turn them on.")
        alert.addAction(MDCAlertAction(title: "Enable Push Notifications") { (action) in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }

            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                    print("Settings opened: \(success)")
                    Globals.ViewSettings.showNotificationAlert = false
                })
            }
        })
        alert.addAction(MDCAlertAction(title: "Done"))
        makePopup(alert: alert, image: "info.circle.fill")
        self.present(alert, animated: true)

    }
    
    func displayLocationAlert() {
        let alert = MDCAlertController(title: "Enable Location Services", message: "Grapevine needs your location to work. The only personal identifying we store is the cryptographic hash of a temporary iPhone ID Apple gives us.")
        alert.addAction(MDCAlertAction(title: "Enable Location Services") { (action) in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }

            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                    print("Settings opened: \(success)")
                    self.getLocationAndPosts()
                    self.dismiss(animated: true, completion: {
                        if Globals.ViewSettings.showNotificationAlert {
                            self.displayNotificationAlert()
                        }
                    })
                })
            }
        })
        alert.addAction(MDCAlertAction(title: "Done") { (action) in
            self.refresh()
        })
        makePopup(alert: alert, image: "location.circle.fill")
        super.present(alert, animated: true)
    }
    
    func isLocationAccessEnabled() -> Bool {
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
                case .notDetermined:
                    print("Location Access Not Yet determined")
                    return false
                case .restricted, .denied:
                    print("No Location Access")
                    return false
                case .authorizedAlways, .authorizedWhenInUse:
                    print("Location Access")
                    return true
                @unknown default:
                    print("Location Access Authorization Status Error")
                    return false
            }
        }
        else {
            print("Location services not enabled")
            return false
        }
    }
    
    // Called if request for location fails
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
    }
    
    // Called if location status changed, and when location manager initiated
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if !isLocationAccessEnabled() && CLLocationManager.authorizationStatus() != .notDetermined {
            displayLocationAlert()
        } else if CLLocationManager.authorizationStatus() != .notDetermined{
            //  If location access is enabled, this will make the call to show notification alert if not already enabled. Otherwise, if location is not enabled, show notification alert is called by completion handler of show location alert because two alets cannot be shown at the same time
            if Globals.ViewSettings.showNotificationAlert {
                displayNotificationAlert()
                Globals.ViewSettings.showNotificationAlert = false
            }
            self.refresh()
        }
    }
    
    func getLocationAndPosts(){
        if currentMode == "default" {
            // Check ban status
            userManager.delegate = self
            userManager.fetchUser()
            
            // Get location
            locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization()
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.requestLocation()
        } else if currentMode == "myPosts" {
            postsManager.fetchMyPosts(activityFilter:self.currentFilterState, typeFilter:self.curPostType, groupID: Globals.ViewSettings.groupID)
        } else if currentMode == "myComments" {
            postsManager.fetchMyComments(activityFilter:self.currentFilterState, typeFilter:self.curPostType)
        }
    }
    
    // MARK: Hide navbar on scoll
    /*
     func handleScroll(curPos: CGFloat, curTime: DispatchTime){
         let posDiff = curPos - prevPos
         prevPos = curPos
         let nanoTime = curTime.uptimeNanoseconds - prevTime.uptimeNanoseconds
         let timeDiff = CGFloat(nanoTime) / 1_000_000_000
         prevTime = curTime
         scrollVelocity = posDiff / timeDiff
         // print(scrollVelocity)

         if (self.originalNavbarPosition == 0){
             /// do nothing
         } else if (self.bottomNavBar.frame.origin.y == self.originalNavbarPosition && notScrolling){
             /// do nothing
         } else if (self.bottomNavBar.frame.origin.y <= self.originalNavbarPosition && scrollVelocity < 0){
             /// UNCOMMENT THIS TO HIDE NAVBAR ON SCROLL
             // self.bottomNavBar.frame.origin.y = self.originalNavbarPosition
         } else {
             /// UNCOMMENT THIS TO HIDE NAVBAR ON SCROLL
             // self.bottomNavBar.frame.origin.y += posDiff
         }
     }
     */
    
    func prepareTableView(){
        if let curTheme = UserDefaults.standard.string(forKey: Globals.userDefaults.themeKey){
            if (curTheme == "dark") {
                tableView.backgroundColor = .systemBackground
//                view.backgroundColor = .systemGray6
            }
            else {
//                tableView.backgroundColor = .systemGray6
//                view.backgroundColor = .systemBackground
            }
        }
        postsManager.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        tableView.refreshControl = refresher
        tableView.register(UINib(nibName: Constants.cellNibName, bundle: nil), forCellReuseIdentifier: Constants.cellIdentifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 50, right: 0)
        tableView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
    }
        
    func prepareFloatingAddButton(){
        addButton.accessibilityLabel = "Create"
        addButton.setImage(UIImage(systemName: "plus"), for: .normal)
        addButton.setImageTintColor(.label, for: .normal)
        addButton.enableRippleBehavior = true
        addButton.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
        addButton.frame = CGRect(x: view.frame.width - 55 - 20, y: view.frame.height - 80 - 60 - 20, width: 60, height: 60)
        self.addButton.addTarget(self, action: #selector(addButtonPressed(_:)), for: UIControl.Event.touchUpInside)
        self.view.addSubview(addButton)
    }
    
    /// Displays a loading icon while posts load.
    func activityIndicator() {
        indicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        indicator.style = UIActivityIndicatorView.Style.medium
        indicator.center = self.view.center
        self.view.addSubview(indicator)
    }
    
    func setInitialPostFilters() {
        let defaults = UserDefaults.standard //Save range for next load
        if let rangeType = defaults.string(forKey: Globals.userDefaults.rangeKey) {
            switch rangeType {
            case " 1 Mile":
                self.range = 1.0
                self.rangeButton.setTitle(rangeType, for: .normal)
            case " 10 Miles":
                self.range = 10.0
                self.rangeButton.setTitle(rangeType, for: .normal)
            default: //3 miles
                self.range = 3.0
                self.rangeButton.setTitle(rangeType, for: .normal)
            }
        }
        if let postType = defaults.string(forKey: Globals.userDefaults.postTypeKey) {
            switch postType {
            case "image":
                postTypeButton.setTitle(" Art", for: UIControl.State.normal)
                curPostType = "image"
                let newIcon = UIImage(systemName: "scribble")
                postTypeButton.setImage(newIcon, for: UIControl.State.normal)
            case "all":
                postTypeButton.setTitle(" All", for: UIControl.State.normal)
                curPostType = "all"
                let newIcon = UIImage(systemName: "ellipses.bubble.fill")
                postTypeButton.setImage(newIcon, for: UIControl.State.normal)
            default : //text
                postTypeButton.setTitle(" Text", for: UIControl.State.normal)
                curPostType = "text"
                let newIcon = UIImage(systemName: "quote.bubble.fill")
                postTypeButton.setImage(newIcon, for: UIControl.State.normal)
            }
        }
        if let filterType = defaults.string(forKey: Globals.userDefaults.filterKey) {
            switch filterType {
                case "top":
                    self.currentFilterState = "top"
                    filterButton.setTitle(" Best", for: UIControl.State.normal)
                    let newIcon = UIImage(systemName: "star.circle.fill")
                    filterButton.setImage(newIcon, for: UIControl.State.normal)
                default : //new
                    self.currentFilterState = "new"
                    filterButton.setTitle(" New", for: UIControl.State.normal)
                    let newIcon = UIImage(systemName: "bolt.circle.fill")
                    filterButton.setImage(newIcon, for: UIControl.State.normal)
            }
        }
        
    }
    
    func rangeAction(range: Double, title: String) {
        self.range = range
        self.rangeButton.setTitle(title, for: .normal)
        
        // Scroll to top
        self.scrollToTop()
        self.tableView?.contentOffset = CGPoint(x: 0, y: -((self.tableView?.refreshControl?.frame.height)!))
        
        // Refresh posts in the table
        self.tableView.refreshControl?.beginRefreshing()
        self.applyFilter(reset: true)
    }
    
    /** Update user information when a user segues to a new screen.
     - Parameters:
        - segue: New screen to transition to
        - sender: Segue initiator */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToNewPosts" {
            let destinationVC = segue.destination as! NewPostViewController
            destinationVC.lat = self.lat
            destinationVC.lon = self.lon
            destinationVC.groupName = self.groupName
            destinationVC.groupID = self.groupID
            destinationVC.delegate = self
        }
        if segue.identifier == "mainViewToScoreView" {
            let destinationVC = segue.destination as! ScoreViewController
            destinationVC.range = range
        }
        if segue.identifier == "goToComments" {
            let destinationVC = segue.destination as! CommentViewController
            destinationVC.expandedCellHeight = self.expandedCellHeight
            destinationVC.mainPost = self.selectedPost
            destinationVC.mainPostScreenshot = self.selectedPostScreenshot
            destinationVC.delegate = self
        }
        if segue.identifier == "goToGroups" {
            let destinationVC = segue.destination as! GroupsViewController
            destinationVC.delegate = self
            destinationVC.selectedGroup = self.groupName
            destinationVC.selectedGroupID = self.groupID
        }
    }
    
    /// Refresh the main posts view based on current user location.
    @objc func refresh(){
        userManager.fetchUser()
        if currentMode == "default" {
            if !isLocationAccessEnabled() {
                displayLocationAlert()
            }
            locationManager.requestLocation() // request new location, which will trigger new posts in the function locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
        } else if currentMode == "myPosts" {
            postsManager.fetchMyPosts(activityFilter:self.currentFilterState, typeFilter:self.curPostType, groupID: Globals.ViewSettings.groupID)
        } else if currentMode == "myComments" {
            postsManager.fetchMyComments(activityFilter:self.currentFilterState, typeFilter:self.curPostType)
        } else if currentMode == "groups" {
            postsManager.fetchPosts(latitude: self.lat, longitude: self.lon, range: self.range, activityFilter: self.currentFilterState, typeFilter: self.curPostType, groupID: self.groupID)
        }
        print(currentMode)
    }
    
    func exitAbilities(){
        // Vibrate for haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Reset selected buttons
        burnButton.image = #imageLiteral(resourceName: "burn-square-icon")
        applyAbilityButton.image = UIImage(named: "push-button")
        applyAbilityButton.alpha = 1.0
        
        abilitiesBackgroundView.isHidden = true
        abilitiesBackgroundView.isUserInteractionEnabled = false
        
        abilitiesStackView.isHidden = true
        abilitiesStackView.isUserInteractionEnabled = false
        
        applyAbilityButton.isHidden = true
        applyAbilityButton.isUserInteractionEnabled = false
    }
        
    /// Displays the sharing popup, so users can share a post to Snapchat.
    func showSharePopup(_ cell: PostTableViewCell, _ postType: String, _ content: UIImage){
        let heightInPoints = content.size.height
        let heightInPixels = heightInPoints * content.scale
        let alert = MDCAlertController(title: "Stories", message: "Share this post!")
        alert.backgroundColor = Globals.ViewSettings.backgroundColor
        alert.titleColor = Globals.ViewSettings.labelColor
        alert.messageColor = Globals.ViewSettings.labelColor
        alert.addAction(MDCAlertAction(title: "Cancel") { (action) in
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseIn, animations: {
                    cell.shareButtonVar.transform = .identity
                    cell.shareButtonVar.tintColor = .systemGray2
                    cell.shareButtonVar.setTitleColor(.systemGray2, for: .normal)
                }, completion: nil)
            }
        })
        alert.addAction(MDCAlertAction(title: "Instagram"){ (action) in
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseIn, animations: {
                    cell.shareButtonVar.transform = .identity
                    cell.shareButtonVar.tintColor = .systemGray2
                    cell.shareButtonVar.setTitleColor(.systemGray2, for: .normal)
                }, completion: nil)
            }
            var backgroundImage: UIImage
            if self.range == -1 {
                backgroundImage = self.storyManager.createInstaBackgroundImage(postType, "NO_CITY", heightInPixels)!
            } else {
                backgroundImage = self.storyManager.createInstaBackgroundImage(postType, self.currentCity, heightInPixels)!
            }
            self.storyManager.shareToInstagram(backgroundImage, content)
        })

        alert.addAction(MDCAlertAction(title: "Snapchat"){ (action) in
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseIn, animations: {
                    cell.shareButtonVar.transform = .identity
                    cell.shareButtonVar.tintColor = .systemGray2
                    cell.shareButtonVar.setTitleColor(.systemGray2, for: .normal)
                }, completion: nil)
            }
            var backgroundImage: UIImage
            if self.range == -1 {
                backgroundImage = self.storyManager.createBackgroundImage(postType, "NO_CITY", heightInPixels)!
            } else {
                backgroundImage = self.storyManager.createBackgroundImage(postType, self.currentCity, heightInPixels)!
            }
            self.storyManager.shareToSnap(backgroundImage, content)
        })

        makePopup(alert: alert, image: "arrow.uturn.right.circle.fill")
        self.present(alert, animated: true)
    }

    func showAbilitiesView(_ cell: PostTableViewCell){
        // Vibrate for haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        burnButtonView.backgroundColor = UIColor.gray.withAlphaComponent(0.0)
        shoutButtonView.backgroundColor = UIColor.gray.withAlphaComponent(0.0)
        pushButtonView.backgroundColor = UIColor.gray.withAlphaComponent(0.0)
        
//        abilitiesBackgroundView.transform = CGAffineTransform(translationX: 1000, y: 0) //Shove off screen so we can animate it sliding onto screen
//        abilitiesStackView.transform = CGAffineTransform(translationX: 1000, y: 0)
//        applyAbilityButton.transform = CGAffineTransform(translationX: 1000, y: 0)
        abilitiesBackgroundView.transform = CGAffineTransform(scaleX: 0, y: 0) //Shove off screen so we can animate it sliding onto screen
        abilitiesStackView.transform = CGAffineTransform(scaleX: 0, y: 0)
        applyAbilityButton.transform = CGAffineTransform(scaleX: 0, y: 0)
        pushButton.transform = CGAffineTransform(scaleX: 0, y: 0)
        burnButton.transform = CGAffineTransform(scaleX: 0, y: 0)
        shoutButton.transform = CGAffineTransform(scaleX: 0, y: 0)
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseIn, animations: {
                self.abilitiesBackgroundView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0) //Shove off screen so we can animate it sliding onto screen
                self.abilitiesStackView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                self.applyAbilityButton.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                self.pushButton.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                self.burnButton.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                self.shoutButton.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            }, completion: {_ in
                UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
                    self.abilitiesBackgroundView.transform = .identity
                    self.abilitiesStackView.transform = .identity
                    self.applyAbilityButton.transform = .identity
                    self.pushButton.transform = .identity
                    self.burnButton.transform = .identity
                    self.shoutButton.transform = .identity
                }, completion: nil)
            })
        }
        
        abilitiesBackgroundView.isHidden = false //this is is also being used to determine behavior of navbar in abilities view
        abilitiesBackgroundView.isUserInteractionEnabled = true
        
        abilitiesStackView.isHidden = false
        abilitiesStackView.isUserInteractionEnabled = true
        
        applyAbilityButton.isHidden = false
        applyAbilityButton.isUserInteractionEnabled = true
        
        if currentMode == "groups" {
            pushButton.alpha = 0.4
            burnButton.alpha = 0.4
            shoutButton.alpha = 1.0
            currentAbilityTitle.text = "Shout"
            currentAbility = "shout"
            currentAbilityDescription.text = "Make this post pop out amongst the rest with special golden styling for 6 hours. Costs 10 karma; you have \(self.user?.score ?? 0)."
        } else {
            pushButton.alpha = 1.0
            burnButton.alpha = 0.4
            shoutButton.alpha = 0.4
            currentAbilityTitle.text = "Push"
            currentAbility = "push"
            currentAbilityDescription.text = "Send a notification to everyone within 3 miles of you with the contents of this post. Costs 50 karma, and you have \(self.user?.score ??  0)."
        }
        
        let indexPath = self.tableView.indexPath(for: cell)!
        let row = indexPath.row
        selectedPost = posts[row]
        selectedIndex = indexPath
    }
    
    func viewComments(_ cell: PostTableViewCell, _ postScreenshot: UIImage, cellHeight: CGFloat = 0){
        print("Segue to comment view occurs here")
        self.expandedCellHeight = cellHeight
        let indexPath = self.tableView.indexPath(for: cell) ?? IndexPath(row: 0, section: 0)
        self.commentCellIndexPath = indexPath
        let row = indexPath.row
        selectedPost = posts[row]
        selectedPostScreenshot = postScreenshot
        if currentMode == "myComments" {
            selectedPost?.content = "Team Grapevine: Original post content unavailable here 😠"
            self.postsManager.fetchSinglePost(postID: self.selectedPost?.postId ?? "", groupID: self.selectedPost?.groupID ?? "Grapevine")
        } else {
                self.performSegue(withIdentifier: "goToComments", sender: self)
        }
    }
    
    // For sharing to stories
    func updateCity() {
        let geoCoder = CLGeocoder()
        let location = CLLocation(latitude: lat, longitude: lon)
        geoCoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
            // Place details
            var placeMark: CLPlacemark!
            placeMark = placemarks?[0]
            if placeMark?.subLocality != nil {
                self.currentCity = (placeMark?.subLocality)!
            } else if placeMark?.locality != nil {
                self.currentCity = (placeMark?.locality)!
            } else {
                self.currentCity = "me"
            }
        })
    }
    
    func applyFilter(reset: Bool){
        if reset {
            if (currentFilterState == "new"){ // was showing new, change to top
                filterToNewPosts()
            } else if (currentFilterState == "top"){ // was showing top, change to new
                 filterToTopPosts()
            }
        } else {
            if (currentFilterState == "new"){ // was showing new, change to top
                filterToTopPosts()
            } else if (currentFilterState == "top"){ // was showing top, change to new
                filterToNewPosts()
            }
        }
    }
    
    func filterToTopPosts(){
        self.currentFilterState = "top"
        filterButton.setTitle(" Best", for: UIControl.State.normal)
        let newIcon = UIImage(systemName: "star.circle.fill")
        filterButton.setImage(newIcon, for: UIControl.State.normal)
        let defaults = UserDefaults.standard //Save filter for next load
        defaults.set("top", forKey: Globals.userDefaults.filterKey)
        self.refresh()
    }
    func filterToNewPosts(){
        self.currentFilterState = "new"
        filterButton.setTitle(" New", for: UIControl.State.normal)
        let newIcon = UIImage(systemName: "bolt.circle.fill")
        filterButton.setImage(newIcon, for: UIControl.State.normal)
        let defaults = UserDefaults.standard //Save filter for next load
        defaults.set("new", forKey: Globals.userDefaults.filterKey)
        self.refresh()
    }
    
    // Popup when user flags post
    func showFlaggedAlertPopup(){
        let alert = MDCAlertController(title: "Post Flagged", message: "Sorry about that. Please email teamgrapevineofficial@gmail.com if this is urgently serious.")
        alert.addAction(MDCAlertAction(title: "Ok"){ (action) in })
        makePopup(alert: alert, image: "flag")
        self.present(alert, animated: true)
    }
    
    // MARK: View Modes
    func changeAppearanceBasedOnMode(){
        self.karmaAmountLabel.text = String(self.user?.score ?? 0)
        //Prepare view for groups mode
        if Globals.ViewSettings.groupID != "Grapevine"  && currentMode == "default" {
            // Should only switch between default and groups because we don't want to set currentmode to groups in mycomments view or myposts view
            currentMode = "groups"
        }
        switch currentMode {
        case "default":
            // Add menu navigation bar programatically
            bottomNavBar = prepareBottomNavBar(sender: self, bottomNavBar: bottomNavBar, tab: "Posts")
            self.view.addSubview(bottomNavBar)
        case "myPosts":
            self.nearbyLabel.text = "My Posts"
            self.rangeButton.isHidden = true
            self.filterButton.isHidden = true
            self.postTypeButton.isHidden = true
            self.groupsButton.isHidden = true
            self.karmaAmountLabel.isHidden = true
            // Add menu navigation bar programatically
            bottomNavBar = prepareBottomNavBar(sender: self, bottomNavBar: bottomNavBar, tab: "Me")
            self.view.addSubview(bottomNavBar)
        case "myComments":
            self.nearbyLabel.text = "My Comments"
            self.rangeButton.isHidden = true
            self.filterButton.isHidden = true
            self.postTypeButton.isHidden = true
            self.groupsButton.isHidden = true
            self.karmaAmountLabel.isHidden = true
            // Add menu navigation bar programatically
            bottomNavBar = prepareBottomNavBar(sender: self, bottomNavBar: bottomNavBar, tab: "Me")
            self.view.addSubview(bottomNavBar)
        case "groups":
            print("DEBUG: \(self.view.frame.height)")
            self.nearbyLabel.text = self.groupName
            self.rangeButton.isHidden = true
            self.bottomNavBar = prepareBottomNavBar(sender: self, bottomNavBar: self.bottomNavBar, tab: "Posts")
            self.view.addSubview(self.bottomNavBar)
        default:
            print("currentMode doesn't exist. Check view controller. ")
        }
    }
    
    // MARK: View Interaction Methods
    @objc func scrollToTop() {
        print("DEBUG: \(self.view.frame.height)")
        let topOffest = CGPoint(x: 0, y: -(self.tableView?.contentInset.top ?? 0))
        self.tableView?.setContentOffset(topOffest, animated: true)
    }
    
    /// Called when a user taps the groups button
    @IBAction func groupsButtonPressed(_ sender: Any) {
        // self.originalNavbarPosition = self.bottomNavBar.frame.origin.y
        self.performSegue(withIdentifier: "goToGroups", sender: self)
    }
    
    /** Allows user to change the post request range
     - Parameter tapGestureRegnizer: Tap gesture that fires this function */
    @objc func changeRange(tapGestureRecognizer: UITapGestureRecognizer)
    {
        /// Displays the possible ranges users can request posts from
        let defaults = UserDefaults.standard //Save range for next load
        let alert = MDCAlertController(title: "Change Range", message: "Find more posts around you!")
        
        let action2 = MDCAlertAction(title: "1 Mile") { (action) in
            self.rangeAction(range: 1.0, title: " 1 Mile")
            defaults.set(" 1 Mile", forKey: Globals.userDefaults.rangeKey)
        }
                
        let action3 = MDCAlertAction(title: "3 Miles") { (action) in
            self.rangeAction(range: 3.0, title: " 3 Miles")
            defaults.set(" 3 Miles", forKey: Globals.userDefaults.rangeKey)
        }
        
        let action4 = MDCAlertAction(title: "10 Miles") { (action) in
            self.rangeAction(range: 10.0, title: " 10 Miles")
            defaults.set(" 10 Miles", forKey: Globals.userDefaults.rangeKey)
        }
        
        let action5 = MDCAlertAction(title: "Cancel") { (action) in }
        
        alert.addAction(action5)
        alert.addAction(action4)
        alert.addAction(action3)
        alert.addAction(action2)
        
        if let notificationPostIDTitle = defaults.string(forKey: "notificationPostID") {
            let action6 = MDCAlertAction(title: notificationPostIDTitle) { (action) in }
            alert.addAction(action6)
        }
        makePopup(alert: alert, image: "location.circle.fill")
        self.present(alert, animated: true, completion: nil)
    }
    
    
    @objc func changePostType(tapGestureRecognizer: UITapGestureRecognizer){
        let defaults = UserDefaults.standard //Save post typle for next load
        if (curPostType == "text"){
            postTypeButton.setTitle(" Art", for: UIControl.State.normal)
            curPostType = "image"
            let newIcon = UIImage(systemName: "scribble")
            postTypeButton.setImage(newIcon, for: UIControl.State.normal)
            defaults.set("image", forKey: Globals.userDefaults.postTypeKey)

            self.scrollToTop()
            self.tableView?.contentOffset = CGPoint(x: 0, y: -((self.tableView?.refreshControl?.frame.height)!))
            self.tableView.refreshControl?.beginRefreshing()
            self.refresh()
        } else if (curPostType == "image"){
            postTypeButton.setTitle(" All", for: UIControl.State.normal)
            curPostType = "all"
            let newIcon = UIImage(systemName: "ellipses.bubble.fill")
            postTypeButton.setImage(newIcon, for: UIControl.State.normal)
            defaults.set("all", forKey: Globals.userDefaults.postTypeKey)
            
            self.scrollToTop()
            self.tableView?.contentOffset = CGPoint(x: 0, y: -((self.tableView?.refreshControl?.frame.height)!))
            self.tableView.refreshControl?.beginRefreshing()
            self.refresh()
        } else if (curPostType == "all"){
            postTypeButton.setTitle(" Text", for: UIControl.State.normal)
            curPostType = "text"
            let newIcon = UIImage(systemName: "quote.bubble.fill")
            postTypeButton.setImage(newIcon, for: UIControl.State.normal)
            defaults.set("text", forKey: Globals.userDefaults.postTypeKey)
            
            self.scrollToTop()
            self.tableView?.contentOffset = CGPoint(x: 0, y: -((self.tableView?.refreshControl?.frame.height)!))
            self.tableView.refreshControl?.beginRefreshing()
            self.refresh()
        }
    }
    
    // MARK: Abilities
    @objc func pushButtonTapped (tapGestureRecognizer: UITapGestureRecognizer){
        pushButton.alpha = 1.0
        burnButton.alpha = 0.4
        shoutButton.alpha = 0.4
        currentAbilityTitle.text = "Push"
        applyAbilityButton.alpha = 1.0
        applyAbilityButton.isUserInteractionEnabled = true
        applyAbilityButton.image = UIImage(named: "push-button")
        currentAbility = "push"
        if currentMode != "groups" {
            currentAbilityDescription.text = "Send a notification to everyone within 3 miles of you with the contents of this post. Costs 50 karma; you have \(self.user?.score ?? 0)."
            applyAbilityButton.isHidden = false
        } else {
            currentAbilityDescription.text = "Pushing a post isn't allowed in private groups yet. Go ahead and try it in Grapevine!"
            applyAbilityButton.isHidden = true
        }
    }
    @objc func burnButtonTapped (tapGestureRecognizer: UITapGestureRecognizer){
        burnButton.alpha = 1.0
        pushButton.alpha = 0.4
        shoutButton.alpha = 0.4
        currentAbilityTitle.text = "Burn"
        applyAbilityButton.image = UIImage(named: "burn-button")
        currentAbility = "burn"
        if (selectedPost!.votes < -3 && selectedPost!.poster != self.user!.user){
            currentAbilityDescription.text = "Delete this post and ban the creator for 12 hours. Only for posts with <= -3 votes. Costs 10 karma; you have \(self.user?.score ?? 0)."
            applyAbilityButton.isHidden = false
            burnButton.image = #imageLiteral(resourceName: "burn-square-icon")
        } else {
            currentAbilityDescription.text = "This post needs to have <= -3 votes to be burnt. Burning deletes the post and bans the creator for 12 hours."
            applyAbilityButton.isHidden = true
            burnButton.image = #imageLiteral(resourceName: "burn-disabled-square-icon")
        }
    }
    @objc func shoutButtonTapped (tapGestureRecognizer: UITapGestureRecognizer){
        shoutButton.alpha = 1.0
        burnButton.alpha = 0.4
        pushButton.alpha = 0.4
        applyAbilityButton.alpha = 1.0
        applyAbilityButton.isHidden = false
        applyAbilityButton.isUserInteractionEnabled = true
        currentAbilityTitle.text = "Shout"
        currentAbilityDescription.text = "Make this post pop out amongst the rest with special golden styling for 6 hours. Costs 10 karma; you have \(self.user?.score ?? 0)."
        applyAbilityButton.image = UIImage(named: "shout-button")
        currentAbility = "shout"
    }

    // For detecting when user wants to exit
    @objc func abilitiesViewTapped(tapGestureRecognizer: UITapGestureRecognizer){
        exitAbilities()
    }
    
    @objc func applyAbilityTapped(tapGestureRecognizer: UITapGestureRecognizer){
        print("Apply: \(currentAbility)")
        var alertMessage: String = ""
        var confirmMessage: String = ""
        switch currentAbility {
        case "burn":
            let burnCost: Int = 10 // TO-DO: make this global variable
            if ((self.user?.score ?? 0) >= burnCost){
                let creator = self.selectedPost!.poster
                let postToBeDeleted = self.selectedPost!.postId
                self.userManager.banUser(poster: creator, postID: postToBeDeleted, groupID: Globals.ViewSettings.groupID)
                tableView.reloadRows(at: [selectedIndex!], with: .automatic)
            } else {
                confirmMessage = "Unable to burn..."
                alertMessage = "Not enough karma!"
                let alert = MDCAlertController(title: confirmMessage, message: alertMessage)
                alert.addAction(MDCAlertAction(title: "Ok"))
                makePopup(alert: alert, image: "x.circle.fill")
                self.present(alert, animated: true)
            }
        case "shout":
            let shoutCost: Int = 10 // TO-DO: make this global variable
            if ((self.user?.score ?? 0) >= shoutCost){
                let creator = self.selectedPost!.poster
                let postToBeShoutOut = self.selectedPost!.postId
                self.userManager.shoutPost(poster: creator, postID: postToBeShoutOut, groupID: Globals.ViewSettings.groupID)
                overrideShout = true
                postsManager.fetchSinglePost(postID: self.selectedPost!.postId)
            } else {
                confirmMessage = "Unable to shout..."
                alertMessage = "Not enough karma!"
                let alert = MDCAlertController(title: confirmMessage, message: alertMessage)
                alert.addAction(MDCAlertAction(title: "Ok"))
                makePopup(alert: alert, image: "x.circle.fill")
                self.present(alert, animated: true)
            }
        case "push":
            let pushCost: Int = 50 // TO-DO: make this global variable
            if ((self.user?.score ?? 0) >= pushCost){
                let creator = self.selectedPost!.poster
                let postToBePushed = self.selectedPost!.postId
                self.userManager.pushPost(poster: creator, postID: postToBePushed, lat: self.lat, lon: self.lon, groupID: Globals.ViewSettings.groupID)
                tableView.reloadRows(at: [selectedIndex!], with: .automatic)
            } else {
                confirmMessage = "Unable to push..."
                alertMessage = "Not enough karma!"
                let alert = MDCAlertController(title: confirmMessage, message: alertMessage)
                alert.addAction(MDCAlertAction(title: "Ok"))
                makePopup(alert: alert, image: "x.circle.fill")
                self.present(alert, animated: true)
            }
            
        default:
            print("Unknown ability: \(currentAbility)...")
        }
        exitAbilities()
    }
    
    @IBAction func filterPosts(_ sender: Any) {
        // Scroll to top
        self.scrollToTop()
        self.tableView?.contentOffset = CGPoint(x: 0, y: -((self.tableView?.refreshControl?.frame.height)!))
        self.tableView.refreshControl?.beginRefreshing()
        applyFilter(reset: false)
    }
    
    @IBAction func addButtonPressed(_ sender: UIButton){
        self.performSegue(withIdentifier: "goToNewPosts", sender: self)
    }
}

//MARK: Table View Control

/// Manages the posts table.
extension ViewController: UITableViewDataSource, UITableViewDelegate {
    /**
     Tells the table how many cells are needed.
     
     - Parameters:
        - tableView: Table to be updated
        - section: Number of rows in the section
     
     - Returns: The number of posts in the table
     */
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (posts.count != 0){
            indicator.stopAnimating()
            indicator.hidesWhenStopped = true
        }
        return posts.count
    }
    
    /**
     Triggers auto-loading of more posts when the user scrolls down far enough.
     
     - Parameters:
        - tableView: Table to be updated
        - cell: Table cell about to be created
        - indexPath: Row that the table cell will be generated in
     */
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Latitude, longitude, and range should be the same as the initial posts request
        if (self.posts.count - indexPath.row) == 5 && self.canGetMorePosts {
            if currentMode == "default" {
                postsManager.fetchMorePosts(latitude: self.lat, longitude: self.lon, range: self.range, ref: self.ref, activityFilter:currentFilterState, typeFilter:self.curPostType)
            } else if currentMode == "myPosts" {
                postsManager.fetchMoreMyPosts(ref: self.ref, groupID: Globals.ViewSettings.groupID)
            } else if currentMode == "myComments" {
                postsManager.fetchMoreMyComments(ref: self.ref)
            } else if currentMode == "groups" {
                // Fetch posts from current group from database
                postsManager.fetchMorePosts(latitude: self.lat, longitude: self.lon, range: self.range, ref: self.ref, activityFilter:currentFilterState, typeFilter:self.curPostType, groupID: self.groupID)
            }

            let moreIndicator = UIActivityIndicatorView()
            moreIndicator.style = UIActivityIndicatorView.Style.medium
            moreIndicator.frame = CGRect(x: CGFloat(0), y: CGFloat(0), width: tableView.bounds.width, height: CGFloat(44))
            moreIndicator.startAnimating()
            self.tableView.tableFooterView = moreIndicator
            self.tableView.tableFooterView?.isHidden = false
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if self.shrinkNextCell || self.expandNextCell {
            if let indexToExpand = expandAtIndex{
                if indexToExpand == indexPath {
                    return self.expandedCellHeight ?? UITableView.automaticDimension
                }
            }
        }
        return UITableView.automaticDimension
    }
    
    /**
     Describes how to display a cell for each post.
     
     - Parameters:
        - tableView: Table being displayed
        - indexPath: Indicates which post to create a cell for.
     
     - Returns: Updated table cell
     */
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier, for: indexPath) as! PostTableViewCell
        cell.abilitiesView.isHidden = true
        cell.abilitiesBackgroundView.isHidden = true
        cell.user = self.user
        
        cell.makeBasicCell(post: posts[indexPath.row])
        
        //set the time ago timestamp for post
        cell.setTimeSincePost()
        
        //Expand or collapse cells
        if cell.expandButton.isUserInteractionEnabled {
            if self.expandNextCell == true {
                self.expandNextCell = false
                cell.expandCell()
                cell.ExpandLabel.text = "Tap and hold to collapse"
            } else if self.shrinkNextCell == true {
                self.shrinkNextCell = false
                cell.shrinkCell()
                cell.ExpandLabel.text = "Tap and hold to expand"

            } else {
                cell.shrinkCell()
                cell.ExpandLabel.text = "Tap and hold to expand"

            }
            cell.layoutSubviews()
        }
        
        //Jeremy is the poster, make green to show he is special
        let JeremysID = "d50e7215c74246f24de41fbd3ae99dd033d5cd3ceee04418c2bddc47e67583bf"
        let JeremysLastAnonymousPostDate = 1595486441.830924 //This was the date of his most recent post at the time of adding this feature so that all his previous posts remain normal colors
        if posts[indexPath.row].poster == JeremysID && posts[indexPath.row].date > JeremysLastAnonymousPostDate {
            cell.commentAreaView.backgroundColor = .green
        }
        
        // Ensure that the cell can communicate with this view controller, to keep things like vote statuses consistent across the app
        cell.delegate = self
        
        // Refresh the display of the cell, now that we've loaded in vote status
        cell.refreshView()
        
        ///TO-DO fix refreshview so it is only refreshing what is necessary (post colors, not certain user interactions, etc)
        
        // If the current user created this post, he/she can delete it
        if (Constants.userID == posts[indexPath.row].poster && currentMode != "myComments"){
            cell.isDeleteable = true
            cell.disableInteraction()
        } else {
            cell.isDeleteable = false
        }
        
        // If currentmode is my comments then should just show cell with comment
        // In the future we should use a different cell for this (dequeueReusableCellWithIdentifier"commentcell")
        if currentMode == "myComments" {
            cell.disableInteraction()
            cell.voteCountLabel.isHidden = true
            cell.commentButton.isHidden = true
            cell.moreOptionsButton.isHidden = true
            cell.commentButton.setTitle("Tap to view post", for: .normal)
            cell.shareButtonVar.isHidden = true
        }
        
        // Don't let users use abilities on their own posts
        if Constants.userID == posts[indexPath.row].poster {
            cell.disableAbilities()
        } else {
            cell.enableAbilities()
        }
        
        // The cell is shouted
        if let expiry = posts[indexPath.row].shoutExpiration {
            if expiry > Date().timeIntervalSince1970 {
                print("Showing shouted post!")
                cell.shoutActive = true
                //Comment out to remove gradient vvv
                //let layer = getGradient(color1: #colorLiteral(red: 1, green: 0.9592501521, blue: 0.5572303534, alpha: 1), color2: #colorLiteral(red: 0.7254902124, green: 0.4784313738, blue: 0.09803921729, alpha: 1))
//                let layer = getGradient(color1: .yellow, color2: #colorLiteral(red: 0.7254902124, green: 0.4784313738, blue: 0.09803921729, alpha: 1))
                var layer = getGradient(color1: .white, color2: .yellow)
                if let curTheme = UserDefaults.standard.string(forKey: Globals.userDefaults.themeKey){
                    if (curTheme == "dark") {
                        layer = getGradient(color1: .yellow, color2: #colorLiteral(red: 0.7254902124, green: 0.4784313738, blue: 0.09803921729, alpha: 1))
                    }
                }
//                let layer = getGradient(color1: .white, color2: .yellow)
                
                if cell.postType == "text" {
                    layer.frame = CGRect(x: 0.0, y: 0.0, width: cell.frame.width, height: expandedCellHeight ?? CGFloat(cell.maxLines) * cell.label.font.lineHeight + 96)
                } else {
                    //Hacky fix for image height
                    layer.frame = CGRect(x: 0.0, y: 0.0, width: cell.frame.width, height: 400)
                }
                cell.gradient = layer
                cell.commentAreaView.layer.insertSublayer(cell.gradient!, at: 0)
                cell.voteCountLabel.textColor = .black
                cell.label.textColor = .black
                cell.layoutSubviews()
                // ^^^
                // Uncomment for border instead
//                cell.BoundingView.layer.borderWidth = 2
//                cell.BoundingView.layer.borderColor = #colorLiteral(red: 0.5951293111, green: 0.4168574512, blue: 0.8163670897, alpha: 1)
            } else {
                cell.shoutActive = false
            }
        } else {
            cell.shoutActive = false
        }
        
        return cell
    }
    
    /// Context menu (shown on long cell press)
    @objc func handleLongPress(longPressGesture: UILongPressGestureRecognizer) {
        let p = longPressGesture.location(in: self.tableView)
        if let indexPath = self.tableView.indexPathForRow(at: p) {
            let cell = tableView.cellForRow(at: indexPath) as! PostTableViewCell
            if cell.label.totalNumberOfLines() <= cell.maxLines {
                return
            }
            if longPressGesture.state == UIGestureRecognizer.State.began {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                print("Long press on row, at \(indexPath.row)")
                let cell = tableView.cellForRow(at: indexPath) as! PostTableViewCell
                if cell.isExpanded == false {
                    //UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut, animations: {
                    self.expandAtIndex = indexPath
                    cell.delegate?.expandCell(cell, cellHeight: CGFloat(cell.label.totalNumberOfLines()) * cell.label.font.lineHeight + 96)
                    cell.expandButton.tintColor = .systemGray3
                    //}, completion: nil )
                    
                } else {
                    //UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut, animations: {
                    self.expandAtIndex = indexPath
                    cell.delegate?.expandCell(cell, cellHeight: CGFloat(cell.maxLines) * cell.label.font.lineHeight + 96)
                    cell.expandButton.tintColor = .systemGray3
                    //}, completion: nil)
                }
            }
        }
    }
//    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
//        let configuration = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { actions -> UIMenu? in
//            let report = UIAction(title: "Report", image: UIImage(systemName: "flag"), attributes: .destructive) { action in
//                let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier, for: indexPath) as! PostTableViewCell
//                self.postsManager.performInteractionRequest(interaction: 4, docID: cell.documentId, groupID: Globals.ViewSettings.groupID)
//                self.showFlaggedAlertPopup()
//            }
//            let bookmark = UIAction(title: "Bookmark [🔒] ", image: UIImage(systemName: "bookmark")) { action in
//                print("Bookmarks was tapped")
//            }
//            return UIMenu(title: "", children: [report, bookmark])
//        }
//        return configuration
//    }
    
    
    /// The following three scroll functions allow navbar to hide on scroll
//    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
//        if (self.originalNavbarPosition == 0.0){
//            self.originalNavbarPosition = self.bottomNavBar.frame.origin.y
//        }
//        self.notScrolling = false
//        self.prevPos = tableView.contentOffset.y
//        self.prevTime = DispatchTime.now()
//    }
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        self.handleScroll(curPos: tableView.contentOffset.y, curTime: DispatchTime.now())
//    }
//    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
//        if (self.scrollVelocity > 0){
//            if (abs(self.originalNavbarPosition-self.bottomNavBar.frame.origin.y) < 20){
//                self.bottomNavBar.isHidden = false
//                self.bottomNavBar.frame.origin.y = self.originalNavbarPosition
//            } else {
//                self.bottomNavBar.frame.origin.y = self.originalNavbarPosition
//                self.bottomNavBar.isHidden = true
//            }
//        } else {
//            self.bottomNavBar.isHidden = false
//            self.bottomNavBar.frame.origin.y = self.originalNavbarPosition
//        }
//        self.notScrolling = true
//    }

}

//MARK: Delegate Extensions

/// Updates the posts table once posts are sent by the server.
extension ViewController: PostsManagerDelegate {
    func handleToxicityStatus(toxicScore: Double) {
        //Implemented in newPostViewController
    }
    
    func contentNotPermitted() {
        //Implemented in newPostViewController
    }
    
    func didGetSinglePost(_ postManager: PostsManager, post: Post) {
        if self.overrideShout {
            self.overrideShout = false
            DispatchQueue.main.async {
                for index in self.posts.indices {
                    if self.posts[index].postId == post.postId {
                        self.posts[index].shoutExpiration  = Date().timeIntervalSince1970 + 6*60*60
                        self.tableView.reloadRows(at: [self.selectedIndex!], with: .automatic)
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                if post.poster == "" {
                    self.performSegue(withIdentifier: "goToComments", sender: self)
                }
                if post.type == "image" {
                    let cell = PostTableViewCell()
                    let cellImage = cell.createTableCellImage()
                    self.selectedPostScreenshot = cellImage
                    self.selectedPost = post
                } else {
                    self.selectedPost = post
                    
                }
                self.performSegue(withIdentifier: "goToComments", sender: self)
            }
        }
    }
    
    /** Reloads the table to reflect the newly retrieved posts.
     - Parameters:
        - postManager: `PostManager` object that fetched the posts
        - posts: Array of posts returned by the server
        - ref: Document id of the last post retrieved from this call */
    func didUpdatePosts(_ postManager: PostsManager, posts: [Post], ref: String) {
        DispatchQueue.main.async {
            if ref == "" {
                self.canGetMorePosts = false
            } else {
                self.canGetMorePosts = true
            }
            self.posts = posts
            self.ref = ref
            if self.posts.count == 0 {
                self.alertNoPosts()
                let noPostsLabel = UILabel()
                noPostsLabel.frame = CGRect(x: CGFloat(0), y: CGFloat(0), width: self.tableView.bounds.width, height: CGFloat(44))
                noPostsLabel.textAlignment = .center
                noPostsLabel.text = "Nothing to show or bad Internet 🙁"
                self.tableView.tableHeaderView = noPostsLabel
                self.tableView.tableHeaderView?.isHidden = false
            } else {
                self.tableView.tableHeaderView = nil
            }
            self.tableView.reloadData()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            self.refresher.endRefreshing()
        }
    }
    
    /** Adds auto-retrieved posts to the current list of posts.
     - Parameters:
        - postManager: `PostManager` object that fetched the posts
        - posts: Array of posts returned by the server
        - ref: Document if of the last post retrieved from this call */
    func didGetMorePosts(_ postManager: PostsManager, posts: [Post], ref: String) {
        DispatchQueue.main.async {
            if ref == "" {
                self.canGetMorePosts = false /// Cannot retrieve more
            }
            self.tableView.tableFooterView = nil
            self.posts.append(contentsOf: posts)
            self.ref = ref
            self.tableView.reloadData()
        }
    }
    
    /** Fires if post fetching fails.
     - Parameter error: Error returned when trying to fetch posts */
    func didFailWithError(error: Error){
        print(error)
    }
    
    func didCreatePost() {
        ///Never Called
        //self.refresh()
        return
    }
    
    func alertNoPosts(){
        let alert = MDCAlertController(title: "No posts.", message: "No posts in the current range. \n\nIf you believe this is an error, please contact teamgrapevine on Instagram or email teamgrapevineofficial@gmail.com")
        alert.addAction(MDCAlertAction(title: "Ok"))
        makePopup(alert: alert, image: "x.circle.fill")
        self.present(alert, animated: true)
    }
}

/// Retrieves user location data and fetches posts.
extension ViewController: CLLocationManagerDelegate {
    /** Fetches posts based on current user location. */
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            self.lat = location.coordinate.latitude
            self.lon = location.coordinate.longitude
            updateCity()
            print("Location request success")
            postsManager.fetchPosts(latitude: lat, longitude: lon, range: self.range, activityFilter:self.currentFilterState, typeFilter:self.curPostType, groupID: self.groupID)
        }
    }
}

/// Update post data.
extension ViewController: PostTableViewCellDelegate {
    func moreOptionsTapped(_ cell: PostTableViewCell, alert: UIAlertController) {
        setTheme(curView: alert)
        self.present(alert, animated: true)
    }
    
    /// Fires when user selects an ability
    func userTappedAbility(_ cell: UITableViewCell, _ ability: String){
        switch ability {
        case "burn":
            let burnCost: Int = 10 // TO-DO: make this global variable
            var alertMessage: String = "My karma: \(self.user?.score ?? 0) 💸\nBurn cost: \(burnCost) 💸"
            var confirmMessage: String = "Confirm "
            if ((self.user?.score ?? 0) >= burnCost){
                
            } else {
                confirmMessage = "❌"
                alertMessage = "\n\nInsufficient karma 🙁"
            }
            let alert = MDCAlertController(title: confirmMessage, message: alertMessage)
            let action1 = MDCAlertAction(title: "Cancel") { (action) in
                print("You've pressed cancel");
            }
            alert.addAction(action1)
            
            // Check if user can ban
            if ((self.user?.score ?? 0) >= burnCost){
                let action2 = MDCAlertAction(title: "Yes") { (action) in
                    let indexPath = self.tableView.indexPath(for: cell)!
                    let row = indexPath.row
                    let creatorToBeBanned = self.posts[row].poster
                    let postToBeDeleted = self.posts[row].postId
                    self.userManager.banUser(poster: creatorToBeBanned, postID: postToBeDeleted, groupID: Globals.ViewSettings.groupID)
                }
                alert.addAction(action2)
            }
            makePopup(alert: alert, image: "flame.fill")
            self.present(alert, animated: true)
        case "shout":
            let shoutCost: Int = 10 // TO-DO: make this global variable
            var alertMessage: String = "My karma: \(self.user?.score ?? 0) 💸\nShout cost: \(shoutCost) 💸"
            var confirmMessage: String = "Confirm "
            if ((self.user?.score ?? 0) >= shoutCost){
                confirmMessage += "✅"
                alertMessage += "\n\nAre you sure you want give a shout out to this post?"
            } else {
                confirmMessage += "❌"
                alertMessage += "\n\nInsufficient karma 🙁"
            }
            let alert = MDCAlertController(title: confirmMessage, message: alertMessage)
            let action1 = MDCAlertAction(title: "Cancel") { (action) in
                print("You've pressed cancel");
            }
            alert.addAction(action1)
            
            // Check if user can shout
            if ((self.user?.score ?? 0) >= shoutCost){
                let action2 = MDCAlertAction(title: "Yes") { (action) in
                    let indexPath = self.tableView.indexPath(for: cell)!
                    let row = indexPath.row
                    let creator = self.posts[row].poster
                    let postToBeShoutOut = self.posts[row].postId
                    print("Post to be shouted: ")
                    print(postToBeShoutOut)
                    self.userManager.shoutPost(poster: creator, postID: postToBeShoutOut, groupID: Globals.ViewSettings.groupID)
                }
                alert.addAction(action2)
            }
            
            makePopup(alert: alert, image: "waveform")
            self.present(alert, animated: true)
        case "push":
            let pushCost: Int = 10 // TO-DO: make this global variable
            var alertMessage: String = "My karma: \(self.user?.score ?? 0) 💸\nPush cost: \(pushCost) 💸"
            var confirmMessage: String = "Confirm "
            if ((self.user?.score ?? 0) >= pushCost){
                confirmMessage += "✅"
                alertMessage += "\n\nAre you sure you want to notify everyone in the surrounding area about this post?"
            } else {
                confirmMessage += "❌"
                alertMessage += "\n\nInsufficient karma 🙁"
            }
            let alert = MDCAlertController(title: confirmMessage, message: alertMessage)
            let action1 = MDCAlertAction(title: "Cancel") { (action) in
                print("You've pressed cancel");
            }
            alert.addAction(action1)
            
            // Check if user can shout
            if ((self.user?.score ?? 0) >= pushCost){
                let action2 = MDCAlertAction(title: "Yes") { (action) in
                    let indexPath = self.tableView.indexPath(for: cell)!
                    let row = indexPath.row
                    let creator = self.posts[row].poster
                    let postToBePushed = self.posts[row].postId
                    print("Post to be pushed ")
                    print(postToBePushed)
                    self.userManager.pushPost(poster: creator, postID: postToBePushed, lat: self.lat, lon: self.lon, groupID: Globals.ViewSettings.groupID)
                }
                alert.addAction(action2)
            }
            
            makePopup(alert: alert, image: "waveform")
            self.present(alert, animated: true)
            
        default:
            print("Unknown ability: \(ability)...")
        }
    }
    
    func viewComments(_ cell: PostTableViewCell, cellHeight: CGFloat) {}
    
    /** Updates votes view on a post.
     - Parameters:
        - newVote: Vote added to post's current number of votes
        - newVoteStatus: How the user interacted with the post */
    func updateTableViewVotes(_ cell: UITableViewCell, _ newVote: Int, _ newVoteStatus: Int) {
        let indexPath = self.tableView.indexPath(for: cell)!
        let row = indexPath.row
        posts[row].votes = posts[row].votes + newVote
        posts[row].voteStatus = newVoteStatus
    }
    
    /** Updates flag status on a post.
     - Parameters:
        - cell: Post cell to be updated
        - newFlagStatus: New flag status of a post */
    func updateTableViewFlags(_ cell: UITableViewCell, newFlagStatus: Int) {
        let indexPath = self.tableView.indexPath(for: cell)!
        let row = indexPath.row
        if (newFlagStatus == 1){
            posts[row].flagStatus = newFlagStatus
            posts[row].numFlags = posts[row].numFlags + newFlagStatus
            self.showFlaggedAlertPopup()
        } else {
            posts[row].flagStatus = newFlagStatus
            posts[row].numFlags = posts[row].numFlags + newFlagStatus
        }
    }

    /** Deletes a post.
     - Parameters:
        - cell: Post to be deleted. */
    func deleteCell(_ cell: UITableViewCell) {
        let alert = MDCAlertController(title: "Are you sure?", message: "Deleting a post is permanent. The post's score will still count towards your karma.")

        alert.addAction(MDCAlertAction(title: "Cancel"))
        alert.addAction(MDCAlertAction(title: "I'm Sure, Delete"){ (action) in
            let indexPath = self.tableView.indexPath(for: cell)!
            let row = indexPath.row
            let docIDtoDelete = self.posts[row].postId
            self.postsManager.deletePost(postID: docIDtoDelete, groupID: self.groupID)
            self.posts.remove(at: row)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
        })

        makePopup(alert: alert, image: "x.circle.fill")
        self.present(alert, animated: true)
    }
    
    //Reloads cell at which expand button was pressed. Sets flag that indicates whether the cell should be collapsed or expanded upon reload
    func expandCell(_ cell: PostTableViewCell, cellHeight: CGFloat) {
        self.expandAtIndex = self.tableView.indexPath(for: cell) ?? self.expandAtIndex
        self.expandedCellHeight = cellHeight
        if !cell.isExpanded {
            self.expandNextCell = true
        } else {
            self.shrinkNextCell = true
        }
        if let indexToExpand = expandAtIndex {
            self.tableView.reloadRows(at: [indexToExpand], with: .automatic)
            cell.layoutSubviews()

        }
    }
}

/// Manages the `user` object returned by the server.
extension ViewController: UserManagerDelegate {
    /** Checks if the user is banned
     - Parameters:
        - userManager: `UserManager` object that fetched the user
        - user: `User` object returned by the server */
    func didGetUser(_ userManager: UserManager, user: User){
        DispatchQueue.main.async {
            if userManager.isBanned(strikes: user.strikes, banTime:user.banDate){
                self.performSegue(withIdentifier: "banScreen", sender: self)
            }
            self.user = user
            self.karmaAmountLabel.text = String((self.user?.score ?? 0))
        }
    }
    
    func didUpdateUser(_ userManager: UserManager) {}
    
    /** Fires if user retrieval fails. */
    func userDidFailWithError(error: Error){
        print(error)
    }
}

extension ViewController: CommentViewControllerDelegate {
    func updateTableViewComments(_ post: Post, numComments: Int) {
        if let commentIndexPath = self.commentCellIndexPath {
            var row = 0
            if let i = posts.firstIndex(where: { $0.postId == post.postId }) {
                row = i
            }
            posts[row].comments = numComments
            DispatchQueue.main.async {
                self.tableView.reloadRows(at: [commentIndexPath], with: .automatic)
            }
        }
    }
    
    func showSharePopup(_ postType: String, _ content: UIImage) {
        
    }
    
    func updateTableViewVotes(_ post: Post, _ newVote: Int, _ newVoteStatus: Int) {
        var row = 0
        if let i = posts.firstIndex(where: { $0.postId == post.postId }) {
            row = i
        }
        posts[row].votes = posts[row].votes + newVote
        posts[row].voteStatus = newVoteStatus
    }
    
    func updateTableViewFlags(_ post: Post, newFlagStatus: Int) {
        var row = 0
        if let i = posts.firstIndex(where: { $0.postId == post.postId }) {
            row = i
        }
        if (newFlagStatus == 1){
            posts[row].flagStatus = newFlagStatus
            posts[row].numFlags = posts[row].numFlags + newFlagStatus
        } else {
            posts[row].flagStatus = newFlagStatus
            posts[row].numFlags = posts[row].numFlags + newFlagStatus
        }
    }
}

extension ViewController: UITabBarDelegate {
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if item.tag == 0 {
            if currentMode == "default" || currentMode == "groups" {
                bottomNavBar.selectedItem = bottomNavBar.items?[0]
                if abilitiesBackgroundView.isHidden == false {
                    exitAbilities()
                } else {
                    scrollToTop()
                }
            } else { // myPosts or myComments
                bottomNavBar.selectedItem = bottomNavBar.items?[0]
                let freshViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MainViewController")
                self.present(freshViewController, animated: true, completion: nil)
            }
        } else if item.tag == 1 {
            if currentMode == "default" {
                bottomNavBar.selectedItem = bottomNavBar.items?[0]
            } else { // myPosts or myComments
                bottomNavBar.selectedItem = bottomNavBar.items?[2]
            }
            self.performSegue(withIdentifier: "goToNewPosts", sender: self)
        } else if item.tag == 2 {
            bottomNavBar.selectedItem = bottomNavBar.items?[1]
            self.performSegue(withIdentifier: "mainToProfile", sender: self)
        }
    }
}

extension ViewController: GroupsViewControllerDelegate {
    func setGroupsView(groupName: String, groupID: String) {
        if groupName == "Grapevine" {
            self.currentMode = "default"
            self.groupName = groupName
            self.groupID = groupID
            Globals.ViewSettings.groupID = self.groupID
            Globals.ViewSettings.groupName = self.groupName
            self.nearbyLabel.text = groupName
            self.rangeButton.isHidden = false
            changeAppearanceBasedOnMode()
            self.refresh()
            return
        }
        else {
            self.currentMode = "groups"
            self.groupName = groupName
            self.groupID = groupID
            Globals.ViewSettings.groupID = self.groupID
            Globals.ViewSettings.groupName = self.groupName
            changeAppearanceBasedOnMode()
            self.refresh()
            return
        }
    }
}

extension ViewController: NewPostViewControllerDelegate {
    func postCreated() { //Only called if addPost tapped from ViewController
        self.refresh()
    }
}
