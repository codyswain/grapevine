//
//  CommentTableViewCell.swift
//  Grapevine-130
//
//  Created by Cody Swain on 3/27/20.
//  Copyright © 2020 Anthony Humay. All rights reserved.
//

import UIKit

protocol CommentTableViewCellDelegate {
    func updateTableViewVotes(_ cell: UITableViewCell, _ newVote: Int, _ newVoteStatus: Int)
    func deleteCell( _ cell: UITableViewCell)
}

class CommentTableViewCell: UITableViewCell {
    var commentsManager = CommentsManager()
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var messageBackground: UIView!
    @IBOutlet weak var voteBackground: UIView!
    @IBOutlet weak var voteButton: UIButton!
    @IBOutlet weak var voteButtonIcon: UIImageView!
    @IBOutlet weak var deleteButton: UIImageView!
    var delegate: CommentTableViewCellDelegate?
    
    var commentID: String = ""
    var documentId: String = ""
    var voteStatus: Int = 0
    
    var previouslyPressed: Bool = false
    var isOwnUsersComment: Bool = false
    
    /** Enable deletion of a comment. */
    func enableDelete(){
        // Set up delete button
        print("Deletable: \(documentId)")
        let tapGestureRecognizerDelete = UITapGestureRecognizer(target: self, action: #selector(deleteCommentPressed(tapGestureRecognizer:)))
        deleteButton.isUserInteractionEnabled = true
        deleteButton.addGestureRecognizer(tapGestureRecognizerDelete)
        deleteButton.isHidden = false
    }
    
    /** Disable deletion of a post. */
    func disableDelete(){
        print("Not deletable: \(documentId)")
        deleteButton.isHidden = true
    }
    
    @IBAction func upvoteCommentPressed(_ sender: UIButton) {
        // do stuff when someone upvotes a comment
        if (voteStatus == 0){
            voteStatus = 1
            voteBackground.backgroundColor = Constants.Colors.darkPurple
            voteButtonIcon.tintColor = UIColor.systemBackground
            voteButton.setTitleColor(UIColor.systemBackground, for: .normal)
            commentsManager.performUpvoteRequest(interaction: 1, commentID: commentID)
            if let voteCount = sender.title(for: .normal){
                voteButton.setTitle(String(Int(voteCount)!+1), for: .normal)
            }
            self.delegate?.updateTableViewVotes(self, 1, voteStatus)
        } else {
            voteStatus = 0
            voteBackground.backgroundColor = UIColor(named: "PostColors")
            voteButtonIcon.tintColor = UIColor.label
            voteButton.setTitleColor(UIColor.label, for: .normal)
            commentsManager.performUpvoteRequest(interaction: 0, commentID: commentID)
            if let voteCount = sender.title(for: .normal){
                voteButton.setTitle(String(Int(voteCount)!-1), for: .normal)
            }
            self.delegate?.updateTableViewVotes(self, -1, voteStatus)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        messageBackground.layer.cornerRadius = 5
        voteBackground.layer.cornerRadius = 5
        label.text = "Test comment text"
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    /** Deletes a `comment`.
     - Parameter tapGestureRecognizer: Gesture performed by the user */
    @objc func deleteCommentPressed(tapGestureRecognizer: UITapGestureRecognizer)
    {
        deleteButton.tintColor = Constants.Colors.darkPurple
        self.delegate?.deleteCell(self)
    }
}
