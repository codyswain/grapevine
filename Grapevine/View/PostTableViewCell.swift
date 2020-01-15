//
//  PostTableViewCell.swift
//  Grapevine
//
//  Created by Anthony Humay on 1/8/20.
//  Copyright © 2020 Grapevine. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseFirestore

class PostTableViewCell: UITableViewCell {
    
    // Objects used to interface with UI
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var voteCountLabel: UILabel!
    @IBOutlet weak var downvoteImageButton: UIImageView!
    @IBOutlet weak var upvoteImageButton: UIImageView!
    @IBOutlet weak var footer: UIView!
    
    let db = Firestore.firestore()
    var currentVoteStatus = 0
    var documentId = ""
    
    // Initialization code
    override func awakeFromNib() {
        super.awakeFromNib() //Some pre-built in shit, probably inheritance
        
        // Add tapping capabilities to downvote button (UIImageView)
        let tapGestureRecognizer1 = UITapGestureRecognizer(target: self, action: #selector(downvoteTapped(tapGestureRecognizer:)))
        downvoteImageButton.isUserInteractionEnabled = true
        downvoteImageButton.addGestureRecognizer(tapGestureRecognizer1)
        
        // Add tapping capabilities to upvote button (UIImageView)
        let tapGestureRecognizer2 = UITapGestureRecognizer(target: self, action: #selector(upvoteTapped(tapGestureRecognizer:)))
        upvoteImageButton.isUserInteractionEnabled = true
        upvoteImageButton.addGestureRecognizer(tapGestureRecognizer2)
        
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }

    // Some auto generated shittt
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    // Get the current vote as an integer
    // You don't even need this
    func getVote(){
        let postRef = self.db.collection("posts").document(documentId)
        postRef.getDocument {(document, error) in
            if let document = document, document.exists {
                let data = document.data()
                if let currentPostVotes = data?[Constants.Firestore.votesField] as? Int {
                    print("Votes on this post is \(currentPostVotes)")
                }
            }
        }
    }
    
    // Set the vote. Also update voteStatus
    func upvote(){
        let newVote = Int(String(voteCountLabel.text!))! + 1
        let voteData: [String: Any] = ["votes": newVote]
        db.collection("posts").document(documentId).setData(voteData, merge: true){
            err in
            if let err = err {
                print("Error upvoting: \(err)")
            } else {
                print("Successfully upvoted")
            }
        }
        let voteStatusData: [String: Any] = ["voteStatus": String(self.currentVoteStatus)];   db.collection("posts").document(documentId).collection("user").document(UIDevice.current.identifierForVendor!.uuidString).setData(voteStatusData, merge: true){
            err in
            if let err = err {
                print("Error changing voteStatus: \(err)")
            } else {
                print("Successfully changed voteStatus")
            }
        }
    }
    func downvote(){
        let newVote = Int(String(voteCountLabel.text!))! - 1
        let voteData: [String: Any] = ["votes": newVote]
        db.collection("posts").document(documentId).setData(voteData, merge: true){
            err in
            if let err = err {
                print("Error upvoting: \(err)")
            } else {
                print("Successfully downvoted")
            }
        }
        let voteStatusData: [String: Any] = ["voteStatus": String(self.currentVoteStatus)];   db.collection("posts").document(documentId).collection("user").document(UIDevice.current.identifierForVendor!.uuidString).setData(voteStatusData, merge: true){
            err in
            if let err = err {
                print("Error changing voteStatus: \(err)")
            } else {
                print("Successfully changed voteStatus")
            }
        }
    }

    // Function executed when downvote button is tapped
    @objc func downvoteTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        if self.currentVoteStatus == 0 {
            currentVoteStatus = -1
            downvote()
            footer.backgroundColor = UIColor(red:0.86, green:0.69, blue:0.99, alpha:1.0)
            upvoteImageButton.tintColor = UIColor(red:0.86, green:0.69, blue:0.99, alpha:1.0)
            voteCountLabel.text = String(Int(String(voteCountLabel.text!))! - 1)
        } else if self.currentVoteStatus == 1 {
            currentVoteStatus = 0
            downvote()
            footer.backgroundColor = UIColor(red:0.91, green:0.91, blue:0.91, alpha:1.0)
            upvoteImageButton.tintColor = UIColor(red:0.79, green:0.79, blue:0.79, alpha:1.0)
            downvoteImageButton.tintColor = UIColor(red:0.79, green:0.79, blue:0.79, alpha:1.0)
            voteCountLabel.text = String(Int(String(voteCountLabel.text!))! - 1)
        } else {
            currentVoteStatus = 0
            upvote()
            footer.backgroundColor = UIColor(red:0.91, green:0.91, blue:0.91, alpha:1.0)
            upvoteImageButton.tintColor = UIColor(red:0.79, green:0.79, blue:0.79, alpha:1.0)
            voteCountLabel.text = String(Int(String(voteCountLabel.text!))! + 1)
        }
    }
    
    // Function executed when upvote button is tapped 
    @objc func upvoteTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        if self.currentVoteStatus == 0 {
            currentVoteStatus = 1
            upvote()
            footer.backgroundColor = UIColor(red:0.62, green:0.27, blue:0.90, alpha:1.0)
            downvoteImageButton.tintColor = UIColor(red:0.62, green:0.27, blue:0.90, alpha:1.0)
            voteCountLabel.text = String(Int(String(voteCountLabel.text!))! + 1)
        } else if self.currentVoteStatus == -1 {
            currentVoteStatus = 0
            upvote()
            footer.backgroundColor = UIColor(red:0.91, green:0.91, blue:0.91, alpha:1.0)
            downvoteImageButton.tintColor = UIColor(red:0.79, green:0.79, blue:0.79, alpha:1.0)
            upvoteImageButton.tintColor = UIColor(red:0.79, green:0.79, blue:0.79, alpha:1.0)
            voteCountLabel.text = String(Int(String(voteCountLabel.text!))! + 1)
        } else {
            currentVoteStatus = 0
            downvote()
            footer.backgroundColor = UIColor(red:0.91, green:0.91, blue:0.91, alpha:1.0)
            downvoteImageButton.tintColor = UIColor(red:0.79, green:0.79, blue:0.79, alpha:1.0)
            voteCountLabel.text = String(Int(String(voteCountLabel.text!))! - 1)
        }
    }
    
}
