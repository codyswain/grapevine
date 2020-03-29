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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        label.text = "yadaasdadsfasdfasdfasdfsdfasdfasdfasdfasdfsadfsdfasdsfdsf"
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
