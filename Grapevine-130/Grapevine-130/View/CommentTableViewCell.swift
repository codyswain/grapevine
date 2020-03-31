//
//  CommentTableViewCell.swift
//  Grapevine-130
//
//  Created by Cody Swain on 3/27/20.
//  Copyright © 2020 Anthony Humay. All rights reserved.
//

import UIKit

protocol CommentTableViewCellDelegate {
    
}

class CommentTableViewCell: UITableViewCell {
    var commentsManager = CommentsManager()
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var messageBackground: UIView!
    @IBOutlet weak var voteBackground: UIView!
    @IBOutlet weak var voteButton: UIButton!
    var commentID: String = ""
    
    var previouslyPressed: Bool = false
    
    @IBAction func upvoteCommentPressed(_ sender: Any) {
        // do stuff when someone upvotes a comment
        
        if (previouslyPressed){
            previouslyPressed = false
            voteBackground.backgroundColor = Constants.Colors.veryLightgrey
            voteButton.setTitleColor(UIColor.black, for: .normal)
            commentsManager.performUpvoteRequest(interaction: 2, commentID: commentID)
        } else {
            previouslyPressed = true
            voteBackground.backgroundColor = Constants.Colors.darkPurple
            voteButton.setTitleColor(UIColor.white, for: .normal)
            commentsManager.performUpvoteRequest(interaction: 1, commentID: commentID)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        messageBackground.layer.cornerRadius = 10
        voteBackground.layer.cornerRadius = 10
        label.text = "Test comment text"
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
