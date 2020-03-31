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
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var messageBackground: UIView!
    @IBOutlet weak var voteBackground: UIView!
    
    @IBAction func upvoteCommentPressed(_ sender: Any) {
        // do stuff when someone upvotes a comment
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
