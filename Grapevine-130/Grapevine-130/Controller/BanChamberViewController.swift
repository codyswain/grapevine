
import UIKit
import FirebaseDatabase
import FirebaseFirestore
import CoreLocation

/// Manages the main workflow of the ban chamber screen.
class BanChamberViewController: UIViewController {
    // UI variables
    @IBOutlet weak var tableView: UITableView!
    // Globals
    let locationManager = CLLocationManager()
    var posts: [Post] = []
    var ref = ""
    var postsManager = PostsManager()
    var userManager = UserManager()
    var postTableCell = PostTableViewCell()
    var lat:CLLocationDegrees = 0.0
    var lon:CLLocationDegrees = 0.0
    lazy var refresher: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = .black
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return refreshControl
    }()
    var indicator = UIActivityIndicatorView()

    /// Manges the ban chamber screen.
    override func viewDidLoad() {
        super.viewDidLoad()
                
        // Show loading symbol
        activityIndicator()
        indicator.startAnimating()
        indicator.backgroundColor = .white

        // Get location
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        
        // Load posts
        postsManager.delegate = self
        
        // Load table
        tableView.dataSource = self
        tableView.refreshControl = refresher
        tableView.register(UINib(nibName: Constants.cellNibName, bundle: nil), forCellReuseIdentifier: Constants.cellIdentifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        tableView.backgroundColor = UIColor.white
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
        
    /// Refresh the main posts view based on current user location.
    @objc func refresh(){
        locationManager.requestLocation() // request new location, which will trigger new posts
        let deadline = DispatchTime.now() + .milliseconds(1000)
        DispatchQueue.main.asyncAfter(deadline: deadline){
            self.refresher.endRefreshing()
        }
    }
}

/// Manages the posts table.
extension BanChamberViewController: UITableViewDataSource {
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
        
        cell.downvoteImageButton.isHidden = true
        cell.upvoteImageButton.isHidden = true
        cell.flagButton.isHidden = true
        cell.deleteButton.isHidden = true
        cell.voteCountLabel.isHidden = true
        cell.shareButton.isHidden = true
        cell.banButtonVar.isHidden = false
        // Set main body of post cell
        cell.label.text = posts[indexPath.row].content
        // Set vote count of post cell
        cell.voteCountLabel.text = String(posts[indexPath.row].votes)
        // Set the postID
        cell.documentId = posts[indexPath.row].postId
                
        // Refresh the display of the cell, now that we've loaded in vote status
        cell.refreshView()
        
        cell.banDelegate = self
        
        return cell
    }
}

/// Updates the posts table once posts are sent by the server.
extension BanChamberViewController: PostsManagerDelegate {
    /**
     Reloads the table to reflect the newly retrieved posts.
     
     - Parameters:
        - postManager: `PostManager` object that fetched the psots
        - posts: Array of posts returned by the server
     */
    func didUpdatePosts(_ postManager: PostsManager, posts: [Post], ref: String){
        DispatchQueue.main.async {
            self.posts = posts
            self.ref = ref
            self.tableView.reloadData()
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
}

/// Retrieves user location data and fetches posts.
extension BanChamberViewController: CLLocationManagerDelegate {
    /**
     Fetches posts based on current user location.
     */
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            self.lat = location.coordinate.latitude
            self.lon = location.coordinate.longitude
            print("Location request success")
            // Set to global ban range for now
            postsManager.fetchBannedPosts(latitude: lat, longitude: lon, range: 10)
        }
    }
    
    /**
    Fires if location retrieval fails.
    */
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
    }
}

extension BanChamberViewController: BannedPostTableViewCellDelegate {
    /**
    Strikes the poster of the selected post.
    
    - Parameters:
       - cell: Posts table cell of the post whose creator is to be banned
    */
    func banPoster(_ cell: UITableViewCell) {
        print("inside banPoster")
        let indexPath = self.tableView.indexPath(for: cell)!
        let row = indexPath.row
        let creatorToBeBanned = posts[row].poster
        let postToBeDeleted = posts[row].postId
        userManager.banUser(poster: creatorToBeBanned, postID: postToBeDeleted)
        self.performSegue(withIdentifier: "banToMain", sender: self)
    }
}
