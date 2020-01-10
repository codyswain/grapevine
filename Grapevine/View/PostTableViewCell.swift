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
        footer.backgroundColor = UIColor(red:0.91, green:0.91, blue:0.91, alpha:1.0)
        print("Downvote tapped")
    }
    
    // Function executed when upvote button is tapped 
    @objc func upvoteTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        footer.backgroundColor = UIColor(red:0.62, green:0.27, blue:0.90, alpha:1.0)
        print("Upvote tapped")
    }
    
}
