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

protocol PostTableViewCellDelegate {
    func updateVotes(_ indexOfPost: Int, _ newVote: Int)
}

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
    var indexOfPost = 0
    var delegate: PostTableViewCellDelegate?
    
    // Initialization code, auto-generated
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
        
        if self.currentVoteStatus == 0 {
            setNeutralColors()
        } else if self.currentVoteStatus == -1 {
            setDownvotedColors()
        } else {
            setUpvotedColors()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    // Auto-generated
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    // Function executed when upvote button is tapped
    @objc func upvoteTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        if self.currentVoteStatus == 0 { // post was not voted on (neutral), after upvoting will be upvoted
            currentVoteStatus = 1
            upvote()
            setUpvotedColors()
            voteCountLabel.text = String(Int(String(voteCountLabel.text!))! + 1)
            self.delegate?.updateVotes(indexOfPost, 1)
        } else if self.currentVoteStatus == -1 { // post was downvoted, after upvoting will be neutral
            currentVoteStatus = 0
            upvote()
            setNeutralColors()
            voteCountLabel.text = String(Int(String(voteCountLabel.text!))! + 1)
            self.delegate?.updateVotes(indexOfPost, 1)
        } else { // post was upvoted, after upvoting will be neutral
            currentVoteStatus = 0
            downvote()
            setNeutralColors()
            voteCountLabel.text = String(Int(String(voteCountLabel.text!))! - 1)
            self.delegate?.updateVotes(indexOfPost, -1)
        }
    }

    // Function executed when downvote button is tapped
    @objc func downvoteTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        if self.currentVoteStatus == 0 { // post was not voted on (neutral), after downvoting will be downvoted
            currentVoteStatus = -1
            downvote()
            setDownvotedColors()
            voteCountLabel.text = String(Int(String(voteCountLabel.text!))! - 1)
            self.delegate?.updateVotes(indexOfPost, -1)
        } else if self.currentVoteStatus == 1 { // post was upvoted, after downvoting will be neutral
            currentVoteStatus = 0
            downvote()
            setNeutralColors()
            voteCountLabel.text = String(Int(String(voteCountLabel.text!))! - 1)
            self.delegate?.updateVotes(indexOfPost, -1)
        } else { // post was downvoted, after downvoting will be neutral
            currentVoteStatus = 0
            upvote()
            setNeutralColors()
            voteCountLabel.text = String(Int(String(voteCountLabel.text!))! + 1)
            self.delegate?.updateVotes(indexOfPost, 1)
        }
    }
    
    // Modify the database to reflect the upvote
    func upvote(){
        let newVote = Int(String(voteCountLabel.text!))! + 1
        let voteData: [String: Any] = ["votes": newVote]
        db.collection("posts").document(documentId).setData(voteData, merge: true){
            err in
            if let err = err {
                print("Error upvoting: \(err)")
            } else {
                print("Successfully upvoted in DB")
            }
        }
        let voteStatusData: [String: Any] = ["voteStatus": String(self.currentVoteStatus)];   db.collection("posts").document(documentId).collection("user").document(Constants.userID).setData(voteStatusData, merge: true){
            err in
            if let err = err {
                print("Error changing voteStatus: \(err)")
            } else {
                print("Successfully changed voteStatus in DB")
            }
        }
    }
    
    // Modify the database to reflect the downvote
    func downvote(){
        let newVote = Int(String(voteCountLabel.text!))! - 1
        let voteData: [String: Any] = ["votes": newVote]
        db.collection("posts").document(documentId).setData(voteData, merge: true){
            err in
            if let err = err {
                print("Error upvoting: \(err)")
            } else {
                print("Successfully downvoted in DB")
            }
        }
        let voteStatusData: [String: Any] = ["voteStatus": String(self.currentVoteStatus)];   db.collection("posts").document(documentId).collection("user").document(Constants.userID).setData(voteStatusData, merge: true){
            err in
            if let err = err {
                print("Error changing voteStatus: \(err)")
            } else {
                print("Successfully changed voteStatus in DB")
            }
        }
    }

    // Change the cell's colors
    func setDownvotedColors(){
        footer.backgroundColor = Constants.Colors.lightPurple
        upvoteImageButton.tintColor = Constants.Colors.lightPurple
        downvoteImageButton.tintColor = .white
        voteCountLabel.textColor = .white
    }
    
    // Change the cell's colors
    func setNeutralColors(){
        footer.backgroundColor = Constants.Colors.darkGrey
        upvoteImageButton.tintColor = Constants.Colors.lightGrey
        downvoteImageButton.tintColor = Constants.Colors.lightGrey
        voteCountLabel.textColor = .black
    }
    
    // Change the cell's colors 
    func setUpvotedColors(){
        footer.backgroundColor = Constants.Colors.darkPurple
        downvoteImageButton.tintColor = Constants.Colors.darkPurple
        upvoteImageButton.tintColor = .white
        voteCountLabel.textColor = .white
    }
}
