//
//  ViewController.swift
//  Grapevine
//
//  Created by Cody Swain on 1/8/20.
//  Copyright © 2020 Grapevine. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseFirestore

class ViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!

    let db = Firestore.firestore()
    var lastRetrievedPostDate: Double = 0.0
    var posts: [Post] = []
    lazy var refresher: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = .black
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return refreshControl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadPosts()
        tableView.dataSource = self
        tableView.refreshControl = refresher
        // TableView setup
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
        loadPosts()
        let deadline = DispatchTime.now() + .milliseconds(1000)
        DispatchQueue.main.asyncAfter(deadline: deadline){
            self.refresher.endRefreshing()
        }
    }
    
    func loadPosts(refresh:Bool){
        print("Device id")
        print(UIDevice.current.identifierForVendor!.uuidString)
        self.posts = []
        db.collection("posts")
            .order(by:Constants.Firestore.dateField)
            .limit(to:Constants.numberOfPostsPerBatch)
            .getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    let data = document.data()
                    let documentId = document.documentID
                    
                    if let currentPostContent = data[Constants.Firestore.textField] as? String,
                    let currentPostVotes = data[Constants.Firestore.votesField] as? Int,
                    let currentPostDate = data[Constants.Firestore.votesField] as? Double {
                        // If we're refreshing and we've already retrieved this post, we shouldn't add it to the list again
//                        if (refresh && currentPostDate <= self.lastRetrievedPostDate){
//
//                            continue
//                        } else {
//                            self.lastRetrievedPostDate = max(self.lastRetrievedPostDate, currentPostDate)
//                        }
                        
                        // Get existing vote status
                        let voteStatusRef = self.db.collection("posts").document(documentId).collection("user").document(UIDevice.current.identifierForVendor!.uuidString)
                        voteStatusRef.getDocument { (document, error) in
                            if let document = document, document.exists {
                                
                                // For debugging only
                                let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
                                print("Document data: \(dataDescription)")
                                
                                // Get existing vote status
                                let data = document.data()
                                if let voteStatus = data?["voteStatus"] as? String {
                                    print("Existing vote status \(voteStatus)")
                                } else {
                                    print("No existing vote status")
                                }
                                
                                
                            } else {
                                print("Creating user vote status in firestore post")
                                let docData: [String: Any] = ["voteStatus": "0"];             self.db.collection("posts").document(documentId).collection("user").document(UIDevice.current.identifierForVendor!.uuidString).setData(docData) { err in
                                    if let err = err {
                                        print("Error writing document: \(err)")
                                    } else {
                                        print("Document successfully written!")
                                    }
                                }
                            }
                        }
                        
                        
                        let newPost = Post(content: currentPostContent, votes:currentPostVotes, date:currentPostDate)
                        self.posts.insert(newPost, at:0)
                        
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    }
//                    print("\(document.documentID) => \(document.data())")
                }
            }
        }
        
        
//        db.collection(Constants.Firestore.collectionName).getDocuments{ (querySnapshot, error) in
//            if let e = error {
//                print("Error return posts from Firestore: \(e)")
//            } else {
//                for document in querySnapshot!.documents {
//                    let data = document.data()
//
//                    if let currentPostContent = data[Constants.Firestore.textField] as? String,
//                        let currentPostVotes = data[Constants.Firestore.votesField] as? Int {
//
//                        if let obj = data[Constants.Firestore.userField] as? NSObject {
//                            print("Object found")
//                        } else {
//                            print("Object not found")
//                        }
//
//
//                        let newPost = Post(content: currentPostContent, votes:currentPostVotes)
//                        self.posts.append(newPost)
//
//                        DispatchQueue.main.async {
//                            self.tableView.reloadData()
//                        }
//                    }
//                }
//            }
//        }
    }
    
    // ADD: Reload wheel
    // ADD: Auto-update posts when user submits one

}

extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
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

        return cell
    }
}
