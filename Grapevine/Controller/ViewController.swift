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
    var lastRetrievedPostDate: Double = 0.0
    var posts: [Post] = []
    var postsManager = PostsManager()
    var postTableCell = PostTableViewCell()
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
        var cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier, for: indexPath) as! PostTableViewCell
        // Set main body of post cell
        cell.label.text = posts[indexPath.row].content
        // Set vote count of post cell
        cell.voteCountLabel.text = String(posts[indexPath.row].votes)
        // Set the postID
        cell.documentId = posts[indexPath.row].postId
        // Set vote status
        cell.currentVoteStatus = posts[indexPath.row].voteStatus
        
        // Ensure that the vote number stays accurate
        cell.delegate = self
        cell.indexOfPost = indexPath.row
        
        // Refresh the display of the cell, now that we've loaded in vote status
        cell.awakeFromNib()
        
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
            let lat = location.coordinate.latitude
            let lon = location.coordinate.longitude
            postsManager.fetchPosts(latitude: lat, longitude: lon)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
    }
}

extension ViewController: PostTableViewCellDelegate {
    func updateTableView(_ indexOfPost: Int, _ newVote: Int, _ newVoteStatus: Int) {
        posts[indexOfPost].votes = posts[indexOfPost].votes + newVote
        posts[indexOfPost].voteStatus = newVoteStatus
    }
}
