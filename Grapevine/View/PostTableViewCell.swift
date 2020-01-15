//
//  PostTableViewCell.swift
//  Grapevine
//
//  Created by Anthony Humay on 1/8/20.
//  Copyright © 2020 Grapevine. All rights reserved.
//

import UIKit

class PostTableViewCell: UITableViewCell {
    
    // Objects used to interface with UI
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var voteCountLabel: UILabel!
    @IBOutlet weak var downvoteImageButton: UIImageView!
    @IBOutlet weak var upvoteImageButton: UIImageView!
    @IBOutlet weak var footer: UIView!
    
    var currentVoteStatus = 0
    
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

    // Some auto generated shittt
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

    // Function executed when downvote button is tapped
    @objc func downvoteTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        if self.currentVoteStatus == 0 { // post was not voted on (neutral), after downvoting will be downvoted
            currentVoteStatus = -1
            footer.backgroundColor = UIColor(red:0.86, green:0.69, blue:0.99, alpha:1.0)
            upvoteImageButton.tintColor = UIColor(red:0.86, green:0.69, blue:0.99, alpha:1.0)
            downvoteImageButton.tintColor = .white
            voteCountLabel.textColor = .white
            voteCountLabel.text = String(Int(String(voteCountLabel.text!))! - 1)
        } else if self.currentVoteStatus == 1 { // post was upvoted, after downvoting will be neutral
            currentVoteStatus = 0
            footer.backgroundColor = UIColor(red:0.91, green:0.91, blue:0.91, alpha:1.0)
            upvoteImageButton.tintColor = UIColor(red:0.79, green:0.79, blue:0.79, alpha:1.0)
            downvoteImageButton.tintColor = UIColor(red:0.79, green:0.79, blue:0.79, alpha:1.0)
            voteCountLabel.textColor = .black
            voteCountLabel.text = String(Int(String(voteCountLabel.text!))! - 1)
        } else { // post was downvoted, after downvoting will be neutral
            currentVoteStatus = 0
            footer.backgroundColor = UIColor(red:0.91, green:0.91, blue:0.91, alpha:1.0)
            upvoteImageButton.tintColor = UIColor(red:0.79, green:0.79, blue:0.79, alpha:1.0)
            downvoteImageButton.tintColor = UIColor(red:0.79, green:0.79, blue:0.79, alpha:1.0)
            voteCountLabel.textColor = .black
            voteCountLabel.text = String(Int(String(voteCountLabel.text!))! + 1)
        }
    }
    
    // Function executed when upvote button is tapped 
    @objc func upvoteTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        if self.currentVoteStatus == 0 { // post was not voted on (neutral), after upvoting will be upvoted
            currentVoteStatus = 1
            footer.backgroundColor = UIColor(red:0.62, green:0.27, blue:0.90, alpha:1.0)
            downvoteImageButton.tintColor = UIColor(red:0.62, green:0.27, blue:0.90, alpha:1.0)
            upvoteImageButton.tintColor = .white
            voteCountLabel.textColor = .white
            voteCountLabel.text = String(Int(String(voteCountLabel.text!))! + 1)
        } else if self.currentVoteStatus == -1 {
            currentVoteStatus = 0
            footer.backgroundColor = UIColor(red:0.91, green:0.91, blue:0.91, alpha:1.0)
            downvoteImageButton.tintColor = UIColor(red:0.79, green:0.79, blue:0.79, alpha:1.0)
            upvoteImageButton.tintColor = UIColor(red:0.79, green:0.79, blue:0.79, alpha:1.0)
            voteCountLabel.textColor = .black
            voteCountLabel.text = String(Int(String(voteCountLabel.text!))! + 1)
        } else { // post was upvoted, after upvoting will be neutral
            currentVoteStatus = 0
            footer.backgroundColor = UIColor(red:0.91, green:0.91, blue:0.91, alpha:1.0)
            downvoteImageButton.tintColor = UIColor(red:0.79, green:0.79, blue:0.79, alpha:1.0)
            upvoteImageButton.tintColor = UIColor(red:0.79, green:0.79, blue:0.79, alpha:1.0)
            voteCountLabel.textColor = .black
            voteCountLabel.text = String(Int(String(voteCountLabel.text!))! - 1)
        }
    }
    
}
