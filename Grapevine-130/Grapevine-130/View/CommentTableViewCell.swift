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
    var voteStatus: Int = 0
    
    var previouslyPressed: Bool = false
    
    @IBAction func upvoteCommentPressed(_ sender: UIButton) {
        // do stuff when someone upvotes a comment
        if (voteStatus == 0){
            voteStatus = 1
            voteBackground.backgroundColor = Constants.Colors.veryLightgrey
            voteButton.setTitleColor(UIColor.black, for: .normal)
            commentsManager.performUpvoteRequest(interaction: 1, commentID: commentID)
            if let voteCount = sender.title(for: .normal){
                voteButton.setTitle(String(Int(voteCount)!+1), for: .normal)
            }
        } else {
            voteStatus = 0
            voteBackground.backgroundColor = Constants.Colors.darkPurple
            voteButton.setTitleColor(UIColor.white, for: .normal)
            commentsManager.performUpvoteRequest(interaction: 0, commentID: commentID)
            if let voteCount = sender.title(for: .normal){
                voteButton.setTitle(String(Int(voteCount)!-1), for: .normal)
            }
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
