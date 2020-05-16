import UIKit
import CoreLocation
import MaterialComponents.MaterialBottomNavigation

/// Manages the main workflow.
class ViewController: UIViewController {
    // UI variables
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var nearbyLabel: UILabel!
    @IBOutlet weak var rangeButton: UIButton!
    @IBOutlet weak var filterButton: UIButton!
    
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
        refreshControl.tintColor = .black
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return refreshControl
    }()
    var indicator = UIActivityIndicatorView()
    
    // Post clicked to view comments
    var selectedPost: Post?
    var selectedPostScreenshot: UIImage?

    // Floating button
    var addButton = UIButton()
    
    let bottomNavBar = MDCBottomNavigationBar()
    /// Main control flow that manages the app once the first screen is entered.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Check ban status
        userManager.delegate = self
        userManager.fetchUser()
        
        // Show loading symbol
        activityIndicator()
        indicator.startAnimating()
        indicator.backgroundColor = .white

        // Get location
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestLocation()
                
        // Load table
        prepareTableView()
        
        // Add scroll-to-top button
        let tapGestureRecognizer1 = UITapGestureRecognizer(target: self, action: #selector(scrollToTop))
        nearbyLabel.addGestureRecognizer(tapGestureRecognizer1)
        
        let tapGestureRecognizer2 = UITapGestureRecognizer(target: self, action: #selector(changeRange(tapGestureRecognizer:)))
        rangeButton.addGestureRecognizer(tapGestureRecognizer2)
        
        // Add floating button programatically 
        prepareFloatingAddButton()
        
        // Add menu navigation bar programatically
        prepareBottomNavBar()
    }
    
    func prepareTableView(){
        postsManager.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        tableView.refreshControl = refresher
        tableView.register(UINib(nibName: Constants.cellNibName, bundle: nil), forCellReuseIdentifier: Constants.cellIdentifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        tableView.backgroundColor = UIColor.white
    }
    
    func prepareBottomNavBar() {
        var bottomNavBarFrame = CGRect(x: 0, y: view.frame.height - 80, width: view.frame.width, height: 80)
        
        // Extend the Bottom Navigation to the bottom of the screen.
        if #available(iOS 11.0, *) {
            bottomNavBarFrame.size.height += view.safeAreaInsets.bottom
            bottomNavBarFrame.origin.y -= view.safeAreaInsets.bottom
        }
        bottomNavBar.frame = bottomNavBarFrame
        
        // Potential other images: pencil.and.outline, doc.append, quote.bubble, scribble
        let tabBarItem1 = UITabBarItem(title: "Posts", image: UIImage(systemName: "scribble"), tag: 0)
        let tabBarItem2 = UITabBarItem(title: "Karma", image: UIImage(systemName: "k.circle.fill"), tag: 1)
        let tabBarItem3 = UITabBarItem(title: "Me", image: UIImage(systemName: "person.circle.fill"), tag: 2)

        bottomNavBar.items = [tabBarItem1, tabBarItem2, tabBarItem3]
        bottomNavBar.selectedItem = tabBarItem1
        
        bottomNavBar.delegate = self
        
        bottomNavBarStyling()
        
        view.addSubview(bottomNavBar)
    }
    
    func bottomNavBarStyling(){
        bottomNavBar.itemTitleFont = UIFont.boldSystemFont(ofSize: 17)
        bottomNavBar.itemsContentVerticalMargin = 5
        bottomNavBar.backgroundColor = UIColor(white: 1, alpha: 0.97)
        // Ripple effect: this doesn't turn it off for whatever reason
        self.bottomNavBar.enableRippleBehavior = false
    }
    
    func prepareFloatingAddButton(){
        self.view.addSubview(addButton)
        self.addButton.addTarget(self, action: #selector(addButtonPressed(_:)), for: UIControl.Event.touchUpInside)
        addButton.layer.cornerRadius = addButton.layer.frame.size.width/2
        addButton.clipsToBounds = true
        addButton.setBackgroundImage(UIImage(named:"addButton1"), for: .normal)
        addButton.tintColor = Constants.Colors.darkPurple
        addButton.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        addButton.layer.masksToBounds = false
        addButton.layer.shadowRadius = 2.0
        addButton.layer.shadowOpacity = 0.25
        addButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            addButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20),
            addButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -40),
        addButton.widthAnchor.constraint(equalToConstant: 50),
        addButton.heightAnchor.constraint(equalToConstant: 50)])
    }
    
    /// Displays a loading icon while posts load.
    func activityIndicator() {
        indicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        indicator.style = UIActivityIndicatorView.Style.medium
        indicator.center = self.view.center
        self.view.addSubview(indicator)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }
            
    /**
     Scrolls to the first post
     
     - Parameter tapGestureRegnizer: Tap gesture that fires this function
     */
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
        let alert = UIAlertController(title: "Change Range", message: "Find more posts around you!", preferredStyle: .alert)
                
        let action1 = UIAlertAction(title: "3 miles", style: .default) { (action:UIAlertAction) in
            self.range = 3
            self.rangeButton.setTitle( " 3 miles" , for: .normal )
            self.nearbyLabel.text = "Posts Near You"
            
            // Scroll to top
            self.scrollToTop()
            self.tableView?.contentOffset = CGPoint(x: 0, y: -((self.tableView?.refreshControl?.frame.height)!))
            
            // Refresh posts in the table
            self.tableView.refreshControl?.beginRefreshing()
//            self.refresh()
            self.applyFilter(reset: true)
        }
        
        let action2 = UIAlertAction(title: "Global", style: .default) { (action:UIAlertAction) in
            self.range = -1
            self.rangeButton.setTitle( " Global" , for: .normal )
            self.nearbyLabel.text = "Global Posts"

            // Scroll to top
            self.scrollToTop()
            self.tableView?.contentOffset = CGPoint(x: 0, y: -((self.tableView?.refreshControl?.frame.height)!))
            
            // Refresh posts in the table
            self.tableView.refreshControl?.beginRefreshing()
//            self.refresh()
            self.applyFilter(reset: true)
        }
        
        let action3 = UIAlertAction(title: "Cancel", style: .destructive) { (action:UIAlertAction) in
            
        }

        alert.addAction(action1)
        alert.addAction(action2)
        alert.addAction(action3)
        alert.view.tintColor = .black
        self.present(alert, animated: true, completion: nil)
    }
    
    /// Refresh the main posts view based on current user location.
    @objc func refresh(){
        locationManager.requestLocation() // request new location, which will trigger new posts
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
        let alert = UIAlertController(title: "Stories", message: "Share post as a story!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Snapchat", style: .default){ (action:UIAlertAction) in
            var backgroundImage: UIImage
            if self.range == -1 {
                backgroundImage = self.storyManager.createBackgroundImage(postType, "NO_CITY", heightInPixels)!
            } else {
                backgroundImage = self.storyManager.createBackgroundImage(postType, self.currentCity, heightInPixels)!
            }
            self.storyManager.shareToSnap(backgroundImage, content)
        })
        alert.addAction(UIAlertAction(title: "Instagram Stories", style: .default){ (action:UIAlertAction) in
            var backgroundImage: UIImage
            if self.range == -1 {
                backgroundImage = self.storyManager.createInstaBackgroundImage(postType, "NO_CITY", heightInPixels)!
            } else {
                backgroundImage = self.storyManager.createInstaBackgroundImage(postType, self.currentCity, heightInPixels)!
            }
            self.storyManager.shareToInstagram(backgroundImage, content)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive) { (action:UIAlertAction) in
        })
        alert.view.tintColor = .black
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
        let alert = UIAlertController(title: "Sorry about that. Post was flagged.", message: "Please email teamgrapevineofficial@gmail.com if this is urgently serious.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Ok", style: .default){ (action:UIAlertAction) in })
        self.present(alert, animated: true)
    }
    
    @IBAction func addButtonPressed(_ sender: UIButton){
        self.performSegue(withIdentifier: "goToNewPosts", sender: self)
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
            postsManager.fetchMorePosts(latitude: self.lat, longitude: self.lon, range: self.range, ref: self.ref, filter:currentFilterState)
            print("Getting more posts")

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
        
        // Reset cell attributes before reusing
        cell.imageVar.image = nil
        cell.deleteButton.tintColor = Constants.Colors.lightGrey
        
        if (posts[indexPath.row].type == "text"){
            // Set main body of post cell
            cell.label.text = posts[indexPath.row].content
            cell.postType = "text"
        } else {
            if let decodedData = Data(base64Encoded: posts[indexPath.row].content, options: .ignoreUnknownCharacters) {
                let image = UIImage(data: decodedData)!
                cell.label.text = ""
                let scale: CGFloat
                if image.size.width > image.size.height {
                    scale = cell.imageVar.bounds.width / image.size.width
                } else {
                    scale = cell.imageVar.bounds.height / image.size.height
                }
                
                cell.imageVar.image = image
                let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
                let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                
                UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
                image.draw(in: rect)
                let newImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                cell.postType = "image"
                cell.imageVar.image = newImage
            }
        }
        // Set vote count of post cell
        cell.voteCountLabel.text = String(posts[indexPath.row].votes)
        // Set the postID
        cell.documentId = posts[indexPath.row].postId
        // Set vote status
        cell.currentVoteStatus = posts[indexPath.row].voteStatus
        // Set flag status
//        cell.currentFlagStatus = posts[indexPath.row].flagStatus
        // Set number of flags
//        cell.currentFlagNum = posts[indexPath.row].numFlags
        // Set the comment count number
        if posts[indexPath.row].comments > 0 {
            let commentText = cell.getCommentCount(numComments: posts[indexPath.row].comments)
            cell.commentButton.setTitle(commentText, for: .normal)
            cell.commentButton.setBackgroundImage(UIImage(systemName: "circle.fill"), for: .normal)
        } else {
            cell.commentButton.setTitle("", for: .normal)
            cell.commentButton.setBackgroundImage(UIImage(systemName: "message.circle.fill"), for: .normal)
        }
        // Hide the ban button, only for BanChamberViewController
        cell.banButtonVar.isHidden = true
        // If the current user created this post, he/she can delete it
        if (Constants.userID == posts[indexPath.row].poster){
            cell.enableDelete()
            cell.disableInteraction()
        } else {
            cell.disableDelete()
            cell.enableInteraction()
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
                let noPostsLabel = UILabel()
                noPostsLabel.frame = CGRect(x: CGFloat(0), y: CGFloat(0), width: self.tableView.bounds.width, height: CGFloat(44))
                noPostsLabel.textAlignment = .center
                noPostsLabel.text = "Bad Internet or no posts in your area :("
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
            
            //print("reference doc: ", ref)
            //print("posts: ", posts)
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
        print("This is what I want to run")
//        /**
//        Fires after a new post is created and return processed. This ensures a newly created post will show up.
//        */
//        func didCreatePost() {
//            print("Create post delegate executed. ")
//            // Refresh posts in the table
//            self.tableView.refreshControl?.beginRefreshing()
//            self.refresh()
//        }
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
            postsManager.fetchPosts(latitude: lat, longitude: lon, range: self.range, filter:self.currentFilterState)
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
    
    func didBanUser(_ userManager: UserManager) {}
    
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
        if item.title! == "Posts" {
            scrollToTop()
        } else if item.title! == "Karma" {
            self.performSegue(withIdentifier: "mainViewToScoreView", sender: self)
        } else if item.title! == "Me" {
            scrollToTop()
        }
    }
}
