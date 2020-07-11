import UIKit
import CoreLocation
import MaterialComponents.MaterialBottomNavigation
import MaterialComponents.MaterialButtons
import MaterialComponents.MaterialButtons_Theming

/// Manages the main workflow.
class ViewController: UIViewController {
    // UI variables
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var nearbyLabel: UILabel!
    @IBOutlet weak var rangeButton: UIButton!
    
    @IBOutlet weak var filterButton: UIButton!
    @IBOutlet weak var postTypeButton: UIButton!
    @IBOutlet weak var abilitiesBackgroundView: UIView!
    @IBOutlet weak var abilitiesStackView: UIStackView!
    
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
    
    // Globals
    let locationManager = CLLocationManager()
    var posts: [Post] = []
    var ref = ""
    var canGetMorePosts = true
    var range = 3.0
    var postsManager = PostsManager()
    var scrollPostsManager = PostsManager()
    var storyManager = StoryManager()
    var user: User?
    var userManager = UserManager()
    var scoreManager = ScoreManager()
    var postTableCell = PostTableViewCell()
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
    // Post clicked to view comments
    var selectedPost: Post?
    // We take a screenshot of each cell before opening the comment view of that cell because we need to find out roughly how 'tall' the text is. We use the screenshot height to do that
    var selectedPostScreenshot: UIImage?
    // Floating button
    var addButton = MDCFloatingButton()
    // Add the bottom nav bar, which is done in BottomNavBarMenu.swift
    var bottomNavBar = MDCBottomNavigationBar()
    /// Main control flow that manages the app once the first screen is entered.
    
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
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        //Changes colors of status bar so it will be visible in dark or light mode
        if Globals.ViewSettings.CurrentMode == .dark {
            return .lightContent
        }
        else{
            return .darkContent
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set dark/light mode from persistent storage
        let defaults = UserDefaults.standard
        if let curTheme = defaults.string(forKey: Globals.userDefaults.themeKey){
            if (curTheme == "dark") {
                super.overrideUserInterfaceStyle = .dark
                Globals.ViewSettings.BackgroundColor = Constants.Colors.extremelyDarkGrey
                Globals.ViewSettings.LabelColor = .white
            } else {
                super.overrideUserInterfaceStyle = .light
                Globals.ViewSettings.BackgroundColor = .white
                Globals.ViewSettings.LabelColor = .black
            }
        }
        
        // Set opacity of the background for abilities
        abilitiesBackgroundView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.98)
        
        // Show loading symbol
        activityIndicator()
        indicator.startAnimating()
        indicator.backgroundColor = .systemBackground

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
        
        // ViewController is used as the homepage but also the MyPosts page, so the appearance changes based on that
        changeAppearanceBasedOnMode()
    }
    
    //Display Enable Notification Message
    //https://stackoverflow.com/questions/48796561/how-to-ask-notifications-permissions-if-denied
    override func viewDidAppear(_ animated: Bool) {
        if Globals.ViewSettings.showNotificationAlert {
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
            makePopup(alert: alert, image: "bell.circle.fill")
            super.present(alert, animated: true)
        }
        if !isLocationAccessEnabled() {
            displayLocationAlert()
        }
        getLocationAndPosts()
    }
    
    func displayLocationAlert() {
        let alert = MDCAlertController(title: "Enable Location Services", message: "Grapevine needs your location to work. The only personal identifying we store is the cryptographic hash of a temporary iPhone ID Apple gives us.")
        alert.addAction(MDCAlertAction(title: "Enable Location Services") { (action) in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }

            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                    print("Settings opened: \(success)")
                })
            }
        })
        alert.addAction(MDCAlertAction(title: "Done") { (action) in })
        makePopup(alert: alert, image: "location.circle.fill")
        super.present(alert, animated: true)
    }
    
    func isLocationAccessEnabled() -> Bool {
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
                case .notDetermined, .restricted, .denied:
                    print("No Location Access")
                    return false
                case .authorizedAlways, .authorizedWhenInUse:
                    print("Location Access")
                    return true
            @unknown default:
                return false
            }
        }
        else {
            print("Location services not enabled")
            return false
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
            postsManager.fetchMyPosts(activityFilter:self.currentFilterState, typeFilter:self.curPostType)
        } else if currentMode == "myComments" {
            postsManager.fetchMyComments(activityFilter:self.currentFilterState, typeFilter:self.curPostType)
        }
    }
    
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
    
    func prepareTableView(){
        postsManager.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        tableView.refreshControl = refresher
        tableView.register(UINib(nibName: Constants.cellNibName, bundle: nil), forCellReuseIdentifier: Constants.cellIdentifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        tableView.backgroundColor = UIColor.systemBackground
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
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
            
    /// Scrolls to the top of the table
    @objc func scrollToTop()
    {
        let topOffest = CGPoint(x: 0, y: -(self.tableView?.contentInset.top ?? 0))
        self.tableView?.setContentOffset(topOffest, animated: true)
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
    
    /**
     Allows user to change the post request range
     
     - Parameter tapGestureRegnizer: Tap gesture that fires this function
     */
    @objc func changeRange(tapGestureRecognizer: UITapGestureRecognizer)
    {
        /// Displays the possible ranges users can request posts from
        let alert = MDCAlertController(title: "Change Range", message: "Find more posts around you!")
        let action1 = MDCAlertAction(title: "0.1 Miles") { (action) in
            self.rangeAction(range: 0.1, title: " 0.1 Miles")
        }
        
        let action2 = MDCAlertAction(title: "1 Mile") { (action) in
            self.rangeAction(range: 1.0, title: " 1 Mile")
        }
                
        let action3 = MDCAlertAction(title: "3 Miles") { (action) in
            self.rangeAction(range: 3.0, title: " 3 Miles")
        }
        
        let action4 = MDCAlertAction(title: "10 Miles") { (action) in
            self.rangeAction(range: 10.0, title: " 10 Miles")
        }
        
        let action5 = MDCAlertAction(title: "Cancel") { (action) in }
        
        alert.addAction(action5)
        alert.addAction(action4)
        alert.addAction(action3)
        alert.addAction(action2)
        alert.addAction(action1)
        
        makePopup(alert: alert, image: "location.circle.fill")
        self.present(alert, animated: true, completion: nil)
    }
    
    
    @objc func changePostType(tapGestureRecognizer: UITapGestureRecognizer){
        if (curPostType == "text"){
            postTypeButton.setTitle(" Art ", for: UIControl.State.normal)
            curPostType = "art"
            let newIcon = UIImage(systemName: "scribble")
            postTypeButton.setImage(newIcon, for: UIControl.State.normal)

            self.scrollToTop()
            self.tableView?.contentOffset = CGPoint(x: 0, y: -((self.tableView?.refreshControl?.frame.height)!))
            self.tableView.refreshControl?.beginRefreshing()
            self.refresh()
        } else if (curPostType == "art"){
            postTypeButton.setTitle(" All ", for: UIControl.State.normal)
            curPostType = "all"
            let newIcon = UIImage(systemName: "ellipses.bubble.fill")
            postTypeButton.setImage(newIcon, for: UIControl.State.normal)
            self.scrollToTop()
            self.tableView?.contentOffset = CGPoint(x: 0, y: -((self.tableView?.refreshControl?.frame.height)!))
            self.tableView.refreshControl?.beginRefreshing()
            self.refresh()
        } else if (curPostType == "all"){
            postTypeButton.setTitle(" Text", for: UIControl.State.normal)
            curPostType = "text"
            let newIcon = UIImage(systemName: "quote.bubble.fill")
            postTypeButton.setImage(newIcon, for: UIControl.State.normal)
            self.scrollToTop()
            self.tableView?.contentOffset = CGPoint(x: 0, y: -((self.tableView?.refreshControl?.frame.height)!))
            self.tableView.refreshControl?.beginRefreshing()
            self.refresh()
        }
    }
    
    /// Refresh the main posts view based on current user location.
    @objc func refresh(){
        if !isLocationAccessEnabled() {
            displayLocationAlert()
        }
        if currentMode == "default" {
            locationManager.requestLocation() // request new location, which will trigger new posts in the function locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
        } else if currentMode == "myPosts" {
            postsManager.fetchMyPosts(activityFilter:self.currentFilterState, typeFilter:self.curPostType)
        } else if currentMode == "myComments" {
            postsManager.fetchMyComments(activityFilter:self.currentFilterState, typeFilter:self.curPostType)
        }
    }
    
    /**
     Update user information when a user segues to a new screen.
     
     - Parameters:
        - segue: New screen to transition to
        - sender: Segue initiator
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToNewPosts" {
            let destinationVC = segue.destination as! NewPostViewController
            destinationVC.lat = self.lat
            destinationVC.lon = self.lon
        }
        if segue.identifier == "mainViewToScoreView" {
            let destinationVC = segue.destination as! ScoreViewController
            destinationVC.range = range
        }
        if segue.identifier == "goToComments" {
            let destinationVC = segue.destination as! CommentViewController
            if currentMode == "myComments" {
                selectedPost?.content = "Team Grapevine: Original post content unavailable here 😠"
            }
            destinationVC.mainPost = selectedPost
            destinationVC.mainPostScreenshot = selectedPostScreenshot
        }
    }
    
    
    
    @objc func pushButtonTapped (tapGestureRecognizer: UITapGestureRecognizer){
        pushButton.alpha = 1.0
        burnButton.alpha = 0.4
        shoutButton.alpha = 0.4
        currentAbilityTitle.text = "Push"
        applyAbilityButton.alpha = 1.0
        applyAbilityButton.isUserInteractionEnabled = true
        currentAbilityDescription.text = "Send a notification to everyone within 3 miles of you with the contents of this post. Costs 50 karma; you have \(self.user!.score)."
        applyAbilityButton.isHidden = false
        applyAbilityButton.image = UIImage(named: "push-button")
        currentAbility = "push"
    }
    @objc func burnButtonTapped (tapGestureRecognizer: UITapGestureRecognizer){
        burnButton.alpha = 1.0
        pushButton.alpha = 0.4
        shoutButton.alpha = 0.4
        currentAbilityTitle.text = "Burn"
        applyAbilityButton.image = UIImage(named: "burn-button")
        currentAbility = "burn"
        if (selectedPost!.votes < -3 && selectedPost!.poster != self.user!.user){
            currentAbilityDescription.text = "Delete this post and ban the creator for 12 hours. Only for posts with <= -3 votes. Costs 10 karma; you have \(self.user!.score)."
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
        currentAbilityDescription.text = "Make this post pop out amongst the rest with special golden styling for 6 hours. Costs 10 karma; you have \(self.user!.score)."
        applyAbilityButton.image = UIImage(named: "shout-button")
        currentAbility = "shout"
    }
    
    func exitAbilities(){
        // give haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // reset selected buttons
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
            if (self.user!.score >= burnCost){
                let creator = self.selectedPost!.poster
                let postToBeDeleted = self.selectedPost!.postId
                self.userManager.banUser(poster: creator, postID: postToBeDeleted)
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
            if (self.user!.score >= shoutCost){
                let creator = self.selectedPost!.poster
                let postToBeShoutOut = self.selectedPost!.postId
                self.userManager.shoutPost(poster: creator, postID: postToBeShoutOut)
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
            if (self.user!.score >= pushCost){
                let creator = self.selectedPost!.poster
                let postToBePushed = self.selectedPost!.postId
                self.userManager.pushPost(poster: creator, postID: postToBePushed, lat: self.lat, lon: self.lon)
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
        
    ///Displays the sharing popup, so users can share a post to Snapchat.
    func showSharePopup(_ cell: UITableViewCell, _ postType: String, _ content: UIImage){
        let heightInPoints = content.size.height
        let heightInPixels = heightInPoints * content.scale
        let alert = MDCAlertController(title: "Stories", message: "Share this post!")
        alert.backgroundColor = Globals.ViewSettings.BackgroundColor
        alert.titleColor = Globals.ViewSettings.LabelColor
        alert.messageColor = Globals.ViewSettings.LabelColor
        alert.addAction(MDCAlertAction(title: "Cancel") { (action) in })
        alert.addAction(MDCAlertAction(title: "Instagram"){ (action) in
            var backgroundImage: UIImage
            if self.range == -1 {
                backgroundImage = self.storyManager.createInstaBackgroundImage(postType, "NO_CITY", heightInPixels)!
            } else {
                backgroundImage = self.storyManager.createInstaBackgroundImage(postType, self.currentCity, heightInPixels)!
            }
            self.storyManager.shareToInstagram(backgroundImage, content)
        })
        alert.addAction(MDCAlertAction(title: "Snapchat"){ (action) in
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

    func showAbilitiesView(_ cell: UITableViewCell){
        // Give haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        burnButtonView.backgroundColor = UIColor.gray.withAlphaComponent(0.0)
        shoutButtonView.backgroundColor = UIColor.gray.withAlphaComponent(0.0)
        pushButtonView.backgroundColor = UIColor.gray.withAlphaComponent(0.0)
        
        abilitiesBackgroundView.isHidden = false
        abilitiesBackgroundView.isUserInteractionEnabled = true
        
        abilitiesStackView.isHidden = false
        abilitiesStackView.isUserInteractionEnabled = true
        
        applyAbilityButton.isHidden = false
        applyAbilityButton.isUserInteractionEnabled = true
        
        pushButton.alpha = 1.0
        burnButton.alpha = 0.4
        shoutButton.alpha = 0.4
        currentAbilityTitle.text = "Push"
        currentAbility = "push"
        currentAbilityDescription.text = "Send a notification to everyone within 3 miles of you with the contents of this post. Costs 50 karma, and you have \(self.user!.score) karma."
        
        let indexPath = self.tableView.indexPath(for: cell)!
        let row = indexPath.row
        selectedPost = posts[row]
    }
    
    func viewComments(_ cell: UITableViewCell, _ postScreenshot: UIImage){
        print("Segue to comment view occurs here")
        let indexPath = self.tableView.indexPath(for: cell)!
        let row = indexPath.row
        selectedPost = posts[row]
        selectedPostScreenshot = postScreenshot
        self.performSegue(withIdentifier: "goToComments", sender: self)
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
    
    @IBAction func filterPosts(_ sender: Any) {
        // Scroll to top
        self.scrollToTop()
        self.tableView?.contentOffset = CGPoint(x: 0, y: -((self.tableView?.refreshControl?.frame.height)!))
        self.tableView.refreshControl?.beginRefreshing()
        applyFilter(reset: false)
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
        self.refresh()
    }
    func filterToNewPosts(){
        self.currentFilterState = "new"
        filterButton.setTitle(" Newest", for: UIControl.State.normal)
        let newIcon = UIImage(systemName: "bolt.circle.fill")
        filterButton.setImage(newIcon, for: UIControl.State.normal)
        self.refresh()
    }
    
    // Popup when user flags post
    func showFlaggedAlertPopup(){
        let alert = MDCAlertController(title: "Post Flagged", message: "Sorry about that. Please email teamgrapevineofficial@gmail.com if this is urgently serious.")
        alert.addAction(MDCAlertAction(title: "Ok"){ (action) in })
        makePopup(alert: alert, image: "flag")
        self.present(alert, animated: true)
    }
    
    @IBAction func addButtonPressed(_ sender: UIButton){
        self.performSegue(withIdentifier: "goToNewPosts", sender: self)
    }
    
    func changeAppearanceBasedOnMode(){
        if currentMode == "default" {
            // Add menu navigation bar programatically
            bottomNavBar = prepareBottomNavBar(sender: self, bottomNavBar: bottomNavBar, tab: "Posts")
            self.view.addSubview(bottomNavBar)
        } else if currentMode == "myPosts" {
            self.nearbyLabel.text = "My Posts"
            self.rangeButton.isHidden = true
            self.filterButton.isHidden = true
            self.postTypeButton.isHidden = true
            // Add menu navigation bar programatically
            bottomNavBar = prepareBottomNavBar(sender: self, bottomNavBar: bottomNavBar, tab: "Me")
            self.view.addSubview(bottomNavBar)
        } else if currentMode == "myComments" {
            self.nearbyLabel.text = "My Comments"
            self.rangeButton.isHidden = true
            self.filterButton.isHidden = true
            self.postTypeButton.isHidden = true
            // Add menu navigation bar programatically
            bottomNavBar = prepareBottomNavBar(sender: self, bottomNavBar: bottomNavBar, tab: "Me")
            self.view.addSubview(bottomNavBar)
        }
    }
}

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
                postsManager.fetchMoreMyPosts(ref: self.ref)
            } else if currentMode == "myComments" {
                postsManager.fetchMoreMyComments(ref: self.ref)
            }

            let moreIndicator = UIActivityIndicatorView()
            moreIndicator.style = UIActivityIndicatorView.Style.medium
            moreIndicator.frame = CGRect(x: CGFloat(0), y: CGFloat(0), width: tableView.bounds.width, height: CGFloat(44))
            moreIndicator.startAnimating()
            self.tableView.tableFooterView = moreIndicator
            self.tableView.tableFooterView?.isHidden = false
        }
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

        // Hide the ban button, only for BanChamberViewController
        cell.banButtonVar.isHidden = true
        
        // Hide the shout button, only for ShoutChamberViewController
        cell.shoutButtonVar.isHidden = true
        
        // If the current user created this post, he/she can delete it
        if (Constants.userID == posts[indexPath.row].poster && currentMode != "myComments"){
            cell.enableDelete()
            cell.disableInteraction()
        } else {
            cell.disableDelete()
            cell.enableInteraction()
        }

        // The cell is shouted
        if let expiry = posts[indexPath.row].shoutExpiration {
            if expiry > Date().timeIntervalSince1970 {
                print("Showing shouted post!")
                cell.shoutActive = true
            } else {
                cell.shoutActive = false
            }
        } else {
            cell.shoutActive = false
        }
        
        // Ensure that the cell can communicate with this view controller, to keep things like vote statuses consistent across the app
        cell.delegate = self
        
        // Refresh the display of the cell, now that we've loaded in vote status
        cell.refreshView()
        
        return cell
    }
    
    /// Context menu (shown on long cell press)
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let configuration = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { actions -> UIMenu? in
            let report = UIAction(title: "Report", image: UIImage(systemName: "flag"), attributes: .destructive) { action in
                let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier, for: indexPath) as! PostTableViewCell
                self.postsManager.performInteractionRequest(interaction: 4, docID: cell.documentId)
                self.showFlaggedAlertPopup()
            }
            let bookmark = UIAction(title: "Bookmark [🔒] ", image: UIImage(systemName: "bookmark")) { action in
                print("Bookmarks was tapped")
            }
            return UIMenu(title: "", children: [report, bookmark])
        }
        return configuration
    }
    
    
    /// The following three scroll functions allow navbar to hide on scroll
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if (self.originalNavbarPosition == 0.0){
            self.originalNavbarPosition = self.bottomNavBar.frame.origin.y
        }
        self.notScrolling = false
        self.prevPos = tableView.contentOffset.y
        self.prevTime = DispatchTime.now()
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.handleScroll(curPos: tableView.contentOffset.y, curTime: DispatchTime.now())
    }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if (self.scrollVelocity > 0){
            if (abs(self.originalNavbarPosition-self.bottomNavBar.frame.origin.y) < 20){
                self.bottomNavBar.isHidden = false
                self.bottomNavBar.frame.origin.y = self.originalNavbarPosition
            } else {
                self.bottomNavBar.frame.origin.y = self.originalNavbarPosition
                self.bottomNavBar.isHidden = true
            }
        } else {
            self.bottomNavBar.isHidden = false
            self.bottomNavBar.frame.origin.y = self.originalNavbarPosition
        }
        self.notScrolling = true
    }

}

/// Updates the posts table once posts are sent by the server.
extension ViewController: PostsManagerDelegate {
    /** Reloads the table to reflect the newly retrieved posts.
     - Parameters:
        - postManager: `PostManager` object that fetched the psots
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
            postsManager.fetchPosts(latitude: lat, longitude: lon, range: self.range, activityFilter:self.currentFilterState, typeFilter:self.curPostType)
        }
    }
    
    /** Fires if location retrieval fails. */
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
    }
}

/// Update post data.
extension ViewController: PostTableViewCellDelegate {
    /// Fires when user selects an ability
    func userTappedAbility(_ cell: UITableViewCell, _ ability: String){
        switch ability {
        case "burn":
            let burnCost: Int = 10 // TO-DO: make this global variable
            var alertMessage: String = "My karma: \(self.user!.score) 💸\nBurn cost: \(burnCost) 💸"
            var confirmMessage: String = "Confirm "
            if (self.user!.score >= burnCost){
                
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
            if (self.user!.score >= burnCost){
                let action2 = MDCAlertAction(title: "Yes") { (action) in
                    let indexPath = self.tableView.indexPath(for: cell)!
                    let row = indexPath.row
                    let creatorToBeBanned = self.posts[row].poster
                    let postToBeDeleted = self.posts[row].postId
                    self.userManager.banUser(poster: creatorToBeBanned, postID: postToBeDeleted)
                }
                alert.addAction(action2)
            }
            makePopup(alert: alert, image: "flame.fill")
            self.present(alert, animated: true)
        case "shout":
            let shoutCost: Int = 10 // TO-DO: make this global variable
            var alertMessage: String = "My karma: \(self.user!.score) 💸\nShout cost: \(shoutCost) 💸"
            var confirmMessage: String = "Confirm "
            if (self.user!.score >= shoutCost){
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
            if (self.user!.score >= shoutCost){
                let action2 = MDCAlertAction(title: "Yes") { (action) in
                    let indexPath = self.tableView.indexPath(for: cell)!
                    let row = indexPath.row
                    let creator = self.posts[row].poster
                    let postToBeShoutOut = self.posts[row].postId
                    print("Post to be shouted: ")
                    print(postToBeShoutOut)
                    self.userManager.shoutPost(poster: creator, postID: postToBeShoutOut)
                }
                alert.addAction(action2)
            }
            
            makePopup(alert: alert, image: "waveform")
            self.present(alert, animated: true)
        case "push":
            let pushCost: Int = 10 // TO-DO: make this global variable
            var alertMessage: String = "My karma: \(self.user!.score) 💸\nPush cost: \(pushCost) 💸"
            var confirmMessage: String = "Confirm "
            if (self.user!.score >= pushCost){
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
            if (self.user!.score >= pushCost){
                let action2 = MDCAlertAction(title: "Yes") { (action) in
                    let indexPath = self.tableView.indexPath(for: cell)!
                    let row = indexPath.row
                    let creator = self.posts[row].poster
                    let postToBePushed = self.posts[row].postId
                    print("Post to be pushed ")
                    print(postToBePushed)
                    self.userManager.pushPost(poster: creator, postID: postToBePushed, lat: self.lat, lon: self.lon)
                }
                alert.addAction(action2)
            }
            
            makePopup(alert: alert, image: "waveform")
            self.present(alert, animated: true)
            
        default:
            print("Unknown ability: \(ability)...")
        }
    }
    
    func viewComments(_ cell: UITableViewCell) {}
    
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
            self.postsManager.deletePost(postID: docIDtoDelete)
            self.posts.remove(at: row)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
        })

        makePopup(alert: alert, image: "x.circle.fill")
        self.present(alert, animated: true)
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
        }
    }
    
    func didUpdateUser(_ userManager: UserManager) {}
    
    /** Fires if user retrieval fails. */
    func userDidFailWithError(error: Error){
        print(error)
    }
}

extension ViewController: CommentViewControllerDelegate {
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

extension ViewController: MDCBottomNavigationBarDelegate {
    func bottomNavigationBar(_ bottomNavigationBar: MDCBottomNavigationBar, didSelect item: UITabBarItem) {
        if item.tag == 0 {
            if currentMode == "default" {
                bottomNavBar.selectedItem = bottomNavBar.items[0]
                scrollToTop()
            } else { // myPosts or myComments
                bottomNavBar.selectedItem = bottomNavBar.items[0]
                let freshViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MainViewController")
                self.present(freshViewController, animated: true, completion: nil)
            }
        } else if item.tag == 1 {
            if currentMode == "default" {
                bottomNavBar.selectedItem = bottomNavBar.items[0]
            } else { // myPosts or myComments
                bottomNavBar.selectedItem = bottomNavBar.items[2]
            }
            self.performSegue(withIdentifier: "goToNewPosts", sender: self)
        } else if item.tag == 2 {
            bottomNavBar.selectedItem = bottomNavBar.items[1]
            self.performSegue(withIdentifier: "mainToProfile", sender: self)
        }
    }
}
