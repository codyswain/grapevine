
import UIKit
import CoreLocation

/// Manages the main workflow of the ban chamber screen.
class BanChamberViewController: UIViewController {
    // UI variables
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var banLabel: UILabel!
    @IBOutlet weak var failedBanLabel: UILabel!
    // Globals
    let locationManager = CLLocationManager()
    var posts: [Post] = []
    var ref = ""
    var range = 3
    var canGetMorePosts = true
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
        
        userManager.delegate = self
        
        // Load table
        tableView.dataSource = self
        tableView.refreshControl = refresher
        tableView.register(UINib(nibName: Constants.cellNibName, bundle: nil), forCellReuseIdentifier: Constants.cellIdentifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        tableView.backgroundColor = UIColor.white
        
        // Add scroll to top button
        let tapGestureRecognizer1 = UITapGestureRecognizer(target: self, action: #selector(scrollToTop))
        banLabel.addGestureRecognizer(tapGestureRecognizer1)
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
    
    @objc func scrollToTop()
    {
        DispatchQueue.main.async {
            let topOffest = CGPoint(x: 0, y: -(self.tableView?.contentInset.top ?? 0))
            self.tableView?.setContentOffset(topOffest, animated: true)
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
        
        cell.imageVar.image = nil
        
        DispatchQueue.main.async {
            cell.downvoteImageButton.isHidden = true
            cell.upvoteImageButton.isHidden = true
            cell.commentButton.isHidden = true
            cell.deleteButton.isHidden = true
            cell.voteCountLabel.isHidden = true
            cell.shareButton.isHidden = true
            cell.banButtonVar.isHidden = false
        }
        
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
                let noPostsLabel = UILabel()
                noPostsLabel.frame = CGRect(x: CGFloat(0), y: CGFloat(0), width: self.tableView.bounds.width, height: CGFloat(44))
                noPostsLabel.textAlignment = .center
                noPostsLabel.text = "No bannable posts in your area :( No karma was lost!"
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
            postsManager.fetchBannedPosts(latitude: lat, longitude: lon, range: self.range)
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
        
        let alert = UIAlertController(title: "Are you sure you want to ban this user?", message: "", preferredStyle: .alert)
        let action1 = UIAlertAction(title: "Yes", style: .default) { (action:UIAlertAction) in
            let indexPath = self.tableView.indexPath(for: cell)!
            let row = indexPath.row
            let creatorToBeBanned = self.posts[row].poster
            let postToBeDeleted = self.posts[row].postId
            self.userManager.banUser(poster: creatorToBeBanned, postID: postToBeDeleted)
        }
        let action2 = UIAlertAction(title: "Cancel", style: .destructive) { (action:UIAlertAction) in
            print("You've pressed cancel");
        }
        alert.addAction(action1)
        alert.addAction(action2)
        alert.view.tintColor = Constants.Colors.darkPurple
        self.present(alert, animated: true, completion: nil)
    }
}

extension BanChamberViewController: UserManagerDelegate {
    func didGetUser(_ userManager: UserManager, user: User) {}
    
    func didBanUser(_ userManager: UserManager) {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "banToMain", sender: self)
        }
    }
    
    func userDidFailWithError(error: Error) {
        // TODO: Refactor scrolling to the top and refreshing for this and ViewController
        // Scroll to top and refresh posts in the table
        self.scrollToTop()
        DispatchQueue.main.async {
            self.failedBanLabel.isHidden = false
            UIView.animate(withDuration: 2, animations: { () -> Void in
                self.failedBanLabel.alpha = 0
            }, completion: { finished in
                // Reset the failed ban label
                self.failedBanLabel.isHidden = true
                self.failedBanLabel.alpha = 1
            })
            
            self.tableView?.contentOffset = CGPoint(x: 0, y: -((self.tableView?.refreshControl?.frame.height)!))
            
            self.tableView.refreshControl?.beginRefreshing()
        }
        
        self.refresh()
    }
}
