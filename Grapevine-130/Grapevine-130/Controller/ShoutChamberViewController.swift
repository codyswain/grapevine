import UIKit
import CoreLocation
import MaterialComponents.MaterialDialogs

/// Manages the main workflow of the ban chamber screen.
class ShoutChamberViewController: UIViewController {
    // UI variables
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var shoutLabel: UILabel!
    @IBOutlet weak var failedShoutLabel: UILabel!
    // Globals
    let locationManager = CLLocationManager()
    var posts: [Post] = []
    var ref = ""
    var range = 3.0
    var canGetMorePosts = true
    var postsManager = PostsManager()
    var userManager = UserManager()
    var postTableCell = PostTableViewCell()
    var lat:CLLocationDegrees = 0.0
    var lon:CLLocationDegrees = 0.0
    lazy var refresher: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = .label
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return refreshControl
    }()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return setStatusBarStyle()
    }
    
    var indicator = UIActivityIndicatorView()

    /// Manges the shout out chamber screen.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set dark/light mode from persistent storage
        setTheme(curView: self)
        
        
        // Show loading symbol
        activityIndicator()
        indicator.startAnimating()
        indicator.backgroundColor = .systemBackground

        // Get location
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        
        // Load posts
        postsManager.delegate = self
        
        userManager.delegate = self
        
        // Load table
        tableView.dataSource = self
        tableView.refreshControl = refresher
        tableView.register(UINib(nibName: Constants.cellNibName, bundle: nil), forCellReuseIdentifier: Constants.cellIdentifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        tableView.backgroundColor = UIColor.systemBackground
        
        // Add scroll to top button
        let tapGestureRecognizer1 = UITapGestureRecognizer(target: self, action: #selector(scrollToTop))
        shoutLabel.addGestureRecognizer(tapGestureRecognizer1)
    }
    
    /// Displays a loading icon while posts load.
    func activityIndicator() {
        indicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        indicator.style = UIActivityIndicatorView.Style.medium
        indicator.center = self.view.center
        self.view.addSubview(indicator)
    }
        
    /// Refresh the main posts view based on current user location.
    @objc func refresh(){
        locationManager.requestLocation() // request new location, which will trigger new posts
        let deadline = DispatchTime.now() + .milliseconds(1000)
        DispatchQueue.main.asyncAfter(deadline: deadline){
            self.refresher.endRefreshing()
        }
    }
    
    @objc func scrollToTop()
    {
        DispatchQueue.main.async {
            let topOffest = CGPoint(x: 0, y: -(self.tableView?.contentInset.top ?? 0))
            self.tableView?.setContentOffset(topOffest, animated: true)
        }
    }
}

/// Manages the posts table.
extension ShoutChamberViewController: UITableViewDataSource {
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
     Describes how to display a cell for each post.
     
     - Parameters:
        - tableView: Table being displayed
        - indexPath: Indicates which post to create a cell for.
     
     - Returns: Updated table cell
     */
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier, for: indexPath) as! PostTableViewCell
        
        DispatchQueue.main.async {
            cell.downvoteButton.isHidden = true
            cell.upvoteButton.isHidden = true
            cell.commentButton.isHidden = true
            cell.moreOptionsButton.isHidden = true
            cell.voteCountLabel.isHidden = true
            cell.abilitiesButton.isHidden = true
        }
        
        cell.makeBasicCell(post: posts[indexPath.row])
                
        // Refresh the display of the cell, now that we've loaded in vote status
        cell.refreshView()
        
        cell.shoutDelegate = self
        
        return cell
    }
}

/// Updates the posts table once posts are sent by the server.
extension ShoutChamberViewController: PostsManagerDelegate {
    func contentNotPermitted() {
        //Implemented in NewPostViewController
    }
    
    func didGetSinglePost(_ postManager: PostsManager, post: Post) {
        return
    }
    
    /**
     Reloads the table to reflect the newly retrieved posts.
     
     - Parameters:
        - postManager: `PostManager` object that fetched the psots
        - posts: Array of posts returned by the server
     */
    func didUpdatePosts(_ postManager: PostsManager, posts: [Post], ref: String){
        DispatchQueue.main.async {
            self.indicator.stopAnimating()
            
            if ref == "" {
                self.canGetMorePosts = false
            } else {
                self.canGetMorePosts = true
            }
            
            self.posts = posts
            self.ref = ref
            self.tableView.reloadData()
            
            if self.posts.count == 0 {
                self.alertNoPosts()
                let noPostsLabel = UILabel()
                noPostsLabel.frame = CGRect(x: CGFloat(0), y: CGFloat(0), width: self.tableView.bounds.width, height: CGFloat(44))
                noPostsLabel.textAlignment = .center
                noPostsLabel.text = "No bannable posts in your area."
                self.tableView.tableHeaderView = noPostsLabel
                self.tableView.tableHeaderView?.isHidden = false
            } else {
                self.tableView.tableHeaderView = nil
            }
        }
    }
    
    func didGetMorePosts(_ postManager: PostsManager, posts: [Post], ref: String) {
        // Nothing yet
    }
    
    /**
     Fires if post fetching fails.
     
     - Parameter error: Error returned when trying to fetch posts
     */
    func didFailWithError(error: Error){
        print(error)
    }
    
    /**
    This function must be declared but is never called
    */
    func didCreatePost() {
        return
    }
    
    func alertNoPosts(){
        let alert = MDCAlertController(title: "No posts available to shout.", message: "To show in the shout out chamber, posts must not be shouted out. No karma was lost.")
        alert.addAction(MDCAlertAction(title: "Ok"))
        makePopup(alert: alert, image: "x.circle.fill")
        self.present(alert, animated: true)
    }

}

/// Retrieves user location data and fetches posts.
extension ShoutChamberViewController: CLLocationManagerDelegate {
    /**
     Fetches posts based on current user location.
     */
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            self.lat = location.coordinate.latitude
            self.lon = location.coordinate.longitude
            print("Location request success")
            postsManager.fetchShoutablePosts(latitude: lat, longitude: lon, range: self.range)
        }
    }
    
    /**
    Fires if location retrieval fails.
    */
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
    }
}

extension ShoutChamberViewController: ShoutPostTableViewCellDelegate {
    /**
    Strikes the poster of the selected post.
    
    - Parameters:
       - cell: Posts table cell of the post whose creator is to be banned
    */
    func shoutPost(_ cell: UITableViewCell) {
        print("inside banPoster")
        
        let alert = MDCAlertController(title: "Confirm", message: "Are you sure you want give a shout out to this post?")
        let action1 = MDCAlertAction(title: "Cancel") { (action) in }
        let action2 = MDCAlertAction(title: "Yes") { (action) in
            let indexPath = self.tableView.indexPath(for: cell)!
            let row = indexPath.row
            let creator = self.posts[row].poster
            let postToBeShoutOut = self.posts[row].postId
            self.userManager.shoutPost(poster: creator, postID: postToBeShoutOut, groupID: Globals.ViewSettings.groupID)
        }
        alert.addAction(action1)
        alert.addAction(action2)
        makePopup(alert: alert, image: "waveform")
        self.present(alert, animated: true)
    }
}

extension ShoutChamberViewController: UserManagerDelegate {
    func didGetUser(_ userManager: UserManager, user: User) {}
    
    func didUpdateUser(_ userManager: UserManager) {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "shoutToMain", sender: self)
        }
    }
    
    func userDidFailWithError(error: Error) {
        // TODO: Refactor scrolling to the top and refreshing for this and ViewController
        // Scroll to top and refresh posts in the table
        self.scrollToTop()
        DispatchQueue.main.async {
            self.failedShoutLabel.isHidden = false
            UIView.animate(withDuration: 2, animations: { () -> Void in
                self.failedShoutLabel.alpha = 0
            }, completion: { finished in
                // Reset the failed ban label
                self.failedShoutLabel.isHidden = true
                self.failedShoutLabel.alpha = 1
            })
            
            self.tableView?.contentOffset = CGPoint(x: 0, y: -((self.tableView?.refreshControl?.frame.height)!))
            
            self.tableView.refreshControl?.beginRefreshing()
        }
        
        self.refresh()
    }
}
