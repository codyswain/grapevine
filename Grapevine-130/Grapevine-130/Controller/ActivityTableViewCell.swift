//
//  ActivityTableViewCell.swift
//  Grapevine-130
//
//  Created by Cody Swain on 11/13/20.
//  Copyright © 2020 Anthony Humay. All rights reserved.
//

import UIKit

protocol ActivityTableViewCellDelegate {
    
}

class ActivityTableViewCell: UITableViewCell {
    
    // MARK: Outlets
    @IBOutlet weak var activityTitleLabel: UILabel!
    @IBOutlet weak var activityBodyLabel: UILabel!
    
    // MARK: Variables
    var delegate: ActivityTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
