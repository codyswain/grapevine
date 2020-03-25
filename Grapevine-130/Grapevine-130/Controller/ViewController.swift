import UIKit
import FirebaseDatabase
import FirebaseFirestore
import CoreLocation

/// Manages the main workflow.
class ViewController: UIViewController {
    // UI variables
    @IBOutlet weak var tableView: UITableView!

    // Globals
    let db = Firestore.firestore()
    let locationManager = CLLocationManager()
    var posts: [Post] = []
    var postsManager = PostsManager()
    var user: User?
    var userManager = UserManager()
    var scoreManager = ScoreManager()
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
    
    /**
     Segue to the new post screen on button press.
     
     - Parameter sender: Segue initiator
     */
    @IBAction func newPostButton(_ sender: Any) {
        self.performSegue(withIdentifier: "goToNewPosts", sender: self)
    }
    
    /**
     Segue to the score screen on button press.
     
     - Parameter sender: Segue initiator
     */
    @IBAction func scoreButton(_ sender: Any) {
        self.performSegue(withIdentifier: "mainViewToScoreView", sender: self)
    }
    
    /// Refresh the main posts view based on current user location.
    @objc func refresh(){
        locationManager.requestLocation() // request new location, which will trigger new posts
        let deadline = DispatchTime.now() + .milliseconds(1000)
        DispatchQueue.main.asyncAfter(deadline: deadline){
            self.refresher.endRefreshing()
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
            if let curScore = user?.score {
                destinationVC.score = curScore
                destinationVC.emoji = scoreManager.getEmoji(score:curScore)
                destinationVC.strikesLeftMessage = scoreManager.getStrikeMessage(strikes:user!.strikes)
            } else {
                destinationVC.score = 0
                destinationVC.emoji = scoreManager.getEmoji(score:0)
                destinationVC.strikesLeftMessage = scoreManager.getStrikeMessage(strikes:0)
            }
        }
    }
}

/// Manages the posts table.
extension ViewController: UITableViewDataSource {
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
        cell.imageVar.image = nil // Clear out image content before reusing cells
        if (posts[indexPath.row].type == "text"){
            // Set main body of post cell
            cell.label.text = posts[indexPath.row].content
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
        cell.currentFlagStatus = posts[indexPath.row].flagStatus
        // Set number of flags
        cell.currentFlagNum = posts[indexPath.row].numFlags
        // Hide the ban button, only for BanChamberViewController
        cell.banButtonVar.isHidden = true
        // If the current user created this post, he/she can delete it
        if (Constants.userID == posts[indexPath.row].poster){
            cell.enableDelete()
        } else {
            cell.disableDelete()
        }
        
        // Ensure that the cell can communicate with this view controller, to keep things like vote statuses consistent across the app
        cell.delegate = self
        
        // Refresh the display of the cell, now that we've loaded in vote status
        cell.refreshView()
        
        return cell
    }
}

/// Updates the posts table once posts are sent by the server.
extension ViewController: PostsManagerDelegate {
    /**
     Reloads the table to reflect the newly retrieved posts.
     
     - Parameters:
        - postManager: `PostManager` object that fetched the psots
        - posts: Array of posts returned by the server
     */
    func didUpdatePosts(_ postManager: PostsManager, posts: [Post]){
        DispatchQueue.main.async {
            self.posts = posts
            self.tableView.reloadData()
            
            print(posts)
        }
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
extension ViewController: CLLocationManagerDelegate {
    /**
     Fetches posts based on current user location.
     */
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            self.lat = location.coordinate.latitude
            self.lon = location.coordinate.longitude
            print("Location request success")
            postsManager.fetchPosts(latitude: lat, longitude: lon, range: 500)
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
        db.collection("posts").document(docIDtoDelete).delete() { err in
            if let err = err {
                print("Error deleting document: \(err)")
            } else {
                print("Post successfully deleted!")
            }
        }
        posts.remove(at: row)
        self.tableView.deleteRows(at: [indexPath], with: .fade)
    }
    
    ///Displays the sharing popup, so users can share a post to Snapchat.
    func showSharePopup(){
        let alert = UIAlertController(title: "Share Post", message: "Share this post with your friends!", preferredStyle: .alert)
                
        let action1 = UIAlertAction(title: "Share To Snapchat", style: .default) { (action:UIAlertAction) in
            // share to Snapchat logic goes here
        }
        
        let action2 = UIAlertAction(title: "Cancel", style: .destructive) { (action:UIAlertAction) in
            
        }

        alert.addAction(action1)
        alert.addAction(action2)
        alert.view.tintColor = UIColor(red:0.95, green:0.77, blue:0.06, alpha:1.0)
        self.present(alert, animated: true, completion: nil)
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
    
    /**
    Fires if user retrieval fails.
    */
    func userDidFailWithError(error: Error){
        print(error)
    }
}
