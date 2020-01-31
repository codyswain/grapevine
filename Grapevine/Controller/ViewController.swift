//
//  ViewController.swift
//  Grapevine
//
//  Created by Anthony Humay on 1/8/20.
//  Copyright © 2020 Grapevine. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseFirestore
import CoreLocation

class ViewController: UIViewController {
    // UI variables
    @IBOutlet weak var tableView: UITableView!

    // Globals
    let db = Firestore.firestore()
    let locationManager = CLLocationManager()
    var posts: [Post] = []
    var postsManager = PostsManager()
    var postTableCell = PostTableViewCell()
    var lat:CLLocationDegrees = 0.0
    var lon:CLLocationDegrees = 0.0
    lazy var refresher: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = .black
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return refreshControl
    }()
    
    // viewDidLoad(), the first function that runs. This is sort of like "main"
    override func viewDidLoad() {
        super.viewDidLoad()
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
        tableView.rowHeight = 160
        tableView.backgroundColor = UIColor.white
    }
    
    // Make top information (time, battery, signal) dark mode
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }
    
    // This is how we change screens when a button is pressed
    @IBAction func newPostButton(_ sender: UIButton) {
        self.performSegue(withIdentifier: "goToNewPosts", sender: self)
    }
    
    // This function is called when users refresh
    @objc func refresh(){
        locationManager.requestLocation() // request new location, which will trigger new posts
        let deadline = DispatchTime.now() + .milliseconds(1000)
        DispatchQueue.main.asyncAfter(deadline: deadline){
            self.refresher.endRefreshing()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToNewPosts" {
            let destinationVC = segue.destination as! NewPostViewController
            destinationVC.lat = self.lat
            destinationVC.lon = self.lon
        }
    }
}

extension ViewController: UITableViewDataSource {
    // Auto-generated function header
    // Implementation tells the table how many cells we'll need
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    // Auto-generated function header
    // Implementation tells the table how to display a cell for each of the cells
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier, for: indexPath) as! PostTableViewCell
        // Set main body of post cell
        cell.label.text = posts[indexPath.row].content
        // Set vote count of post cell
        cell.voteCountLabel.text = String(posts[indexPath.row].votes)
        // Set the postID
        cell.documentId = posts[indexPath.row].postId
        // Set vote status
        cell.currentVoteStatus = posts[indexPath.row].voteStatus
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

extension ViewController: PostsManagerDelegate {
    func didUpdatePosts(_ postManager: PostsManager, posts: [Post]){
        DispatchQueue.main.async {
            self.posts = posts
            self.tableView.reloadData()
        }
    }
    
    func didFailWithError(error: Error){
        print(error)
    }
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            self.lat = location.coordinate.latitude
            self.lon = location.coordinate.longitude
            postsManager.fetchPosts(latitude: lat, longitude: lon)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
    }
}

extension ViewController: PostTableViewCellDelegate {
    func updateTableView(_ cell: UITableViewCell, _ newVote: Int, _ newVoteStatus: Int) {
        let indexPath = self.tableView.indexPath(for: cell)!
        let row = indexPath.row
        posts[row].votes = posts[row].votes + newVote
        posts[row].voteStatus = newVoteStatus
    }
    
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
}
