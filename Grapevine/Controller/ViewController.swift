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
    
    
    var posts: [Post] = []
//    var posts: [Post] = [
//        Post(content:"God, North Campus is so much nicer than South Campus it’s crazy. Should’ve been an English major.", votes:5),
//        Post(content:"If you’re sitting near me, I am so sorry. Shrimp burrito is doing me dirty, Rubio’s had a special", votes:3),
//        Post(content:"Why does this school not have any pencil sharpeners? It’s actually kinda impressive", votes:3),
//        Post(content:"Best libraries: Rosenfeld > YRL > Powell > PAB > Engineering. Fight me. ", votes:3),
//        Post(content:"The Lakers are not the real deal. Clippers gonna be champs of the west mark my words baby", votes:3)
//
//    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        loadPosts()
        tableView.dataSource = self
        
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
    
    func loadPosts(){
        db.collection("posts").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    let data = document.data()
                    let documentId = document.documentID
                    if let currentPostContent = data[Constants.Firestore.textField] as? String,
                    let currentPostVotes = data[Constants.Firestore.votesField] as? Int {
                        
                        // Get existing vote status and update posts
                        var currentVoteStatus = 0
                        let voteStatusRef = self.db.collection("posts").document(documentId).collection("user").document(UIDevice.current.identifierForVendor!.uuidString)
                        voteStatusRef.getDocument { (document, error) in
                            if let document = document, document.exists {
                                let data = document.data()
                                if let currentVoteStatusString = data?["voteStatus"] as? String {
                                    currentVoteStatus = Int(currentVoteStatusString)!
                                    let newPost = Post(content: currentPostContent, votes:currentPostVotes, voteStatus: currentVoteStatus)
                                    self.posts.append(newPost)
                                    DispatchQueue.main.async {
                                        self.tableView.reloadData()
                                    }
                                } else {
                                    print("No existing vote status")
                                    print("This error should not happen!!")
                                }
                            } else {
                                print("Creating user vote status in firestore post")
                                let docData: [String: Any] = ["voteStatus": "0"];             self.db.collection("posts").document(documentId).collection("user").document(UIDevice.current.identifierForVendor!.uuidString).setData(docData) { err in
                                    if let err = err {
                                        print("Error writing document: \(err)")
                                    } else {
                                        // Success - push post to screen
                                        let newPost = Post(content: currentPostContent, votes:currentPostVotes, voteStatus: currentVoteStatus)
                                        self.posts.append(newPost)
                                        DispatchQueue.main.async {
                                            self.tableView.reloadData()
                                        }
                                    }
                                }
                                currentVoteStatus = 0
                            }
                        }
                    }
                    print("\(document.documentID) => \(document.data())")
                }
            }
        }
        
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
        
        if (posts[indexPath.row].voteStatus == 0){
            cell.currentVoteStatus = 0
            cell.footer.backgroundColor = UIColor(red:0.91, green:0.91, blue:0.91, alpha:1.0)
            cell.upvoteImageButton.tintColor = UIColor(red:0.79, green:0.79, blue:0.79, alpha:1.0)
            cell.downvoteImageButton.tintColor = UIColor(red:0.79, green:0.79, blue:0.79, alpha:1.0)
        } else if (posts[indexPath.row].voteStatus == 1) {
            cell.currentVoteStatus = 1
            cell.footer.backgroundColor = UIColor(red:0.62, green:0.27, blue:0.90, alpha:1.0)
            cell.downvoteImageButton.tintColor = UIColor(red:0.62, green:0.27, blue:0.90, alpha:1.0)
        } else if (posts[indexPath.row].voteStatus == -1) {
            cell.currentVoteStatus = -1
            cell.footer.backgroundColor = UIColor(red:0.86, green:0.69, blue:0.99, alpha:1.0)
            cell.upvoteImageButton.tintColor = UIColor(red:0.86, green:0.69, blue:0.99, alpha:1.0)
        }
        

        return cell
    }
}
