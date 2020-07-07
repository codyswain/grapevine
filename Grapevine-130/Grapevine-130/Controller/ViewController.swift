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
    
    // Globals
    let locationManager = CLLocationManager()
    var posts: [Post] = []
    var ref = ""
    var canGetMorePosts = true
    var range = 3
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
        
        //set dark/light mode
        if Globals.ViewSettings.CurrentMode == .dark {
            super.overrideUserInterfaceStyle = .dark
        }
        else {
            super.overrideUserInterfaceStyle = .light
        }
        
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
                
        // ViewController is used as the homepage but also the MyPosts page, so the appearance changes based on that
        changeAppearanceBasedOnMode()
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
//        print(scrollVelocity)
        
        if (self.originalNavbarPosition == 0){
            // do nothing
        } else if (self.bottomNavBar.frame.origin.y == self.originalNavbarPosition && notScrolling){
            // do nothing
        } else if (self.bottomNavBar.frame.origin.y <= self.originalNavbarPosition && scrollVelocity < 0){
            self.bottomNavBar.frame.origin.y = self.originalNavbarPosition
        } else {
            self.bottomNavBar.frame.origin.y += posDiff
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
    
    /**
     Allows user to change the post request range
     
     - Parameter tapGestureRegnizer: Tap gesture that fires this function
     */
    @objc func changeRange(tapGestureRecognizer: UITapGestureRecognizer)
    {
        /// Displays the possible ranges users can request posts from
        let alert = MDCAlertController(title: "Change Range", message: "Find more posts around you!")
        alert.backgroundColor = .systemBackground
        alert.titleColor = .label
        alert.messageColor = .label
                
        let action1 = MDCAlertAction(title: "3 miles") { (action) in
            self.range = 3
            self.rangeButton.setTitle( " 3 miles" , for: .normal )
            self.nearbyLabel.text = "Grapevine"
            
            // Scroll to top
            self.scrollToTop()
            self.tableView?.contentOffset = CGPoint(x: 0, y: -((self.tableView?.refreshControl?.frame.height)!))
            
            // Refresh posts in the table
            self.tableView.refreshControl?.beginRefreshing()
//            self.refresh()
            self.applyFilter(reset: true)
        }
        
        let action2 = MDCAlertAction(title: "Global") { (action) in
            self.range = -1
            self.rangeButton.setTitle( " Global" , for: .normal )
            self.nearbyLabel.text = "Global Grapevine"

            // Scroll to top
            self.scrollToTop()
            self.tableView?.contentOffset = CGPoint(x: 0, y: -((self.tableView?.refreshControl?.frame.height)!))
            
            // Refresh posts in the table
            self.tableView.refreshControl?.beginRefreshing()
//            self.refresh()
            self.applyFilter(reset: true)
        }
        
        let action3 = MDCAlertAction(title: "Cancel") { (action) in }
        
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
            self.scrollToTop()
            self.tableView?.contentOffset = CGPoint(x: 0, y: -((self.tableView?.refreshControl?.frame.height)!))
            self.tableView.refreshControl?.beginRefreshing()
            self.refresh()
        } else if (curPostType == "art"){
            postTypeButton.setTitle(" All ", for: UIControl.State.normal)
            curPostType = "all"
            self.scrollToTop()
            self.tableView?.contentOffset = CGPoint(x: 0, y: -((self.tableView?.refreshControl?.frame.height)!))
            self.tableView.refreshControl?.beginRefreshing()
            self.refresh()
        } else if (curPostType == "all"){
            postTypeButton.setTitle(" Text", for: UIControl.State.normal)
            curPostType = "text"
            self.scrollToTop()
            self.tableView?.contentOffset = CGPoint(x: 0, y: -((self.tableView?.refreshControl?.frame.height)!))
            self.tableView.refreshControl?.beginRefreshing()
            self.refresh()
        }
    }
    
    /// Refresh the main posts view based on current user location.
    @objc func refresh(){
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
            destinationVC.mainPost = selectedPost
            destinationVC.mainPostScreenshot = selectedPostScreenshot
        }
    }
        
    ///Displays the sharing popup, so users can share a post to Snapchat.
    func showSharePopup(_ postType: String, _ content: UIImage){
        let heightInPoints = content.size.height
        let heightInPixels = heightInPoints * content.scale
        let alert = MDCAlertController(title: "Stories", message: "Share post as a story!")
        alert.backgroundColor = .systemBackground
        alert.titleColor = .label
        alert.messageColor = .label
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
        alert.backgroundColor = .systemBackground
        alert.titleColor = .label
        alert.messageColor = .label
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
        
        cell.makeBasicCell(post: posts[indexPath.row])

        // Hide the ban button, only for BanChamberViewController
        cell.banButtonVar.isHidden = true
        
        // Hide the shout button, only for ShoutChamberViewController
        cell.shoutButtonVar.isHidden = true
        
        // If the current user created this post, he/she can delete it
        if (Constants.userID == posts[indexPath.row].poster){
            cell.enableDelete()
            cell.disableInteraction()
        } else {
            cell.disableDelete()
            cell.enableInteraction()
        }

        // The cell is shoutable
        if let expiry = posts[indexPath.row].shoutExpiration {
            if expiry > Date().timeIntervalSince1970 {
                print("Showing shouted post!")
                cell.shoutable = true
                cell.commentAreaButton.backgroundColor = Constants.Colors.yellow
                cell.label.textColor = .systemBackground
            } else {
                cell.shoutable = false
            }
        } else {
            cell.shoutable = false
        }
        
        // Ensure that the cell can communicate with this view controller, to keep things like vote statuses consistent across the app
        cell.delegate = self
        
        // Refresh the display of the cell, now that we've loaded in vote status
        cell.refreshView()
        
        return cell
    }
    
    // Context menu
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
    
    
    // The following three scroll functions allow navbar to hide on scroll
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
    /**
     Reloads the table to reflect the newly retrieved posts.
     
     - Parameters:
        - postManager: `PostManager` object that fetched the psots
        - posts: Array of posts returned by the server
        - ref: Document id of the last post retrieved from this call
     */
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
                noPostsLabel.text = "Bad Internet or no posts here."
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
    
    /**
     Adds auto-retrieved posts to the current list of posts.
     
     - Parameters:
        - postManager: `PostManager` object that fetched the posts
        - posts: Array of posts returned by the server
        - ref: Document if of the last post retrieved from this call
     */
    func didGetMorePosts(_ postManager: PostsManager, posts: [Post], ref: String) {
        DispatchQueue.main.async {
            if ref == "" {
                // Cannot retrieve more
                self.canGetMorePosts = false
            }
            
            self.tableView.tableFooterView = nil
            self.posts.append(contentsOf: posts)
            self.ref = ref
            self.tableView.reloadData()
        }
    }
    
    /**
     Fires if post fetching fails.
     
     - Parameter error: Error returned when trying to fetch posts
     */
    func didFailWithError(error: Error){
        print(error)
    }
    
    func didCreatePost() {
        return
    }
    
    func alertNoPosts(){
        let alert = MDCAlertController(title: "No posts.", message: "Either bad Internet or no posts in the current range. \n\nIf you believe this is an error, please contact teamgrapevine on Instagram or email teamgrapevineofficial@gmail.com")
        alert.backgroundColor = .systemBackground
        alert.titleColor = .label
        alert.messageColor = .label
        alert.addAction(MDCAlertAction(title: "Ok"))
        makePopup(alert: alert, image: "x.circle.fill")
        self.present(alert, animated: true)
    }
}

/// Retrieves user location data and fetches posts.
extension ViewController: CLLocationManagerDelegate {
    /**
     Fetches posts based on current user location.
     */
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            self.lat = location.coordinate.latitude
            self.lon = location.coordinate.longitude
            updateCity()
            print("Location request success")
            postsManager.fetchPosts(latitude: lat, longitude: lon, range: self.range, activityFilter:self.currentFilterState, typeFilter:self.curPostType)
        }
    }
    
    /**
    Fires if location retrieval fails.
    */
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
    }
}

/// Update post data.
extension ViewController: PostTableViewCellDelegate {
    func showSharePopup(_ postType: String, _ content: Any) {}
    
    func viewComments(_ cell: UITableViewCell) {}
    
    /**
     Updates votes view on a post.
     
     - Parameters:
        - newVote: Vote added to post's current number of votes
        - newVoteStatus: How the user interacted with the post
     */
    func updateTableViewVotes(_ cell: UITableViewCell, _ newVote: Int, _ newVoteStatus: Int) {
        let indexPath = self.tableView.indexPath(for: cell)!
        let row = indexPath.row
        posts[row].votes = posts[row].votes + newVote
        posts[row].voteStatus = newVoteStatus
    }
    
    /**
     Updates flag status on a post.
     
     - Parameters:
        - cell: Post cell to be updated
        - newFlagStatus: New flag status of a post
     */
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

    /**
     Deletes a post.
     
     - Parameter cell: Post to be deleted.
     */
    func deleteCell(_ cell: UITableViewCell) {
        let indexPath = self.tableView.indexPath(for: cell)!
        let row = indexPath.row
        let docIDtoDelete = posts[row].postId
        postsManager.deletePost(postID: docIDtoDelete)
        posts.remove(at: row)
        self.tableView.deleteRows(at: [indexPath], with: .fade)
    }
    
    
}

/// Manages the `user` object returned by the server.
extension ViewController: UserManagerDelegate {
    /**
     Checks if the user is banned.
     
     - Parameters:
        - userManager: `UserManager` object that fetched the user
        - user: `User` object returned by the server
     */
    func didGetUser(_ userManager: UserManager, user: User){
        DispatchQueue.main.async {
            if userManager.isBanned(strikes: user.strikes, banTime:user.banDate){
                self.performSegue(withIdentifier: "banScreen", sender: self)
            }
            self.user = user
        }
    }
    
    func didUpdateUser(_ userManager: UserManager) {}
    
    /**
    Fires if user retrieval fails.
    */
    func userDidFailWithError(error: Error){
        print(error)
    }
}

extension ViewController: CommentViewControllerDelegate {
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
