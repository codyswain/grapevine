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
    
    @IBAction func newPostButton(_ sender: UIButton) {
        self.performSegue(withIdentifier: "goToNewPosts", sender: self)
    }
    
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
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier, for: indexPath) as! PostTableViewCell
        cell.backgroundColor = UIColor.white
        // Set main body of post cell
        cell.label.text = posts[indexPath.row].content
        cell.label.textColor = UIColor.black // Set the color of the text
        
        // Set vote count of post cell
        cell.voteCountLabel.text = String(posts[indexPath.row].votes)
        cell.voteCountLabel.textColor = UIColor.black
        cell.backgroundColor = UIColor.white
        
        cell.documentId = posts[indexPath.row].postId

        if (posts[indexPath.row].voteStatus == 0){
            cell.currentVoteStatus = 0
            cell.footer.backgroundColor = Constants.Colors.darkGrey
            cell.upvoteImageButton.tintColor = Constants.Colors.lightGrey
            cell.downvoteImageButton.tintColor = Constants.Colors.lightGrey
        } else if (posts[indexPath.row].voteStatus == 1) {
            cell.currentVoteStatus = 1
            cell.footer.backgroundColor = Constants.Colors.darkPurple
            cell.downvoteImageButton.tintColor = Constants.Colors.darkPurple
            cell.upvoteImageButton.tintColor = UIColor.white
            cell.voteCountLabel.textColor = .white
        } else if (posts[indexPath.row].voteStatus == -1) {
            cell.currentVoteStatus = -1
            cell.footer.backgroundColor = Constants.Colors.lightPurple
            cell.upvoteImageButton.tintColor = Constants.Colors.lightPurple
            cell.downvoteImageButton.tintColor = UIColor.white
            cell.voteCountLabel.textColor = .white
        }
        
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

