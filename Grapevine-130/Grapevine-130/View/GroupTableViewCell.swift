//
//  GroupTableViewCell.swift
//  
//
//  Created by Kelsey Lieberman, Cody Swain on 7/20/20.
//  Copyright © 2020 Anthony Humay. All rights reserved.

import UIKit

protocol GroupTableViewCellDelegate {
    func deleteCell( _ cell: UITableViewCell)
}

class GroupTableViewCell: UITableViewCell {

    //MARK: Properties
    
    @IBOutlet weak var cellBackground: UIView!
    @IBOutlet weak var groupLabel: UILabel!
    @IBOutlet weak var checkmark: UIImageView!
    @IBOutlet weak var deleteButton: UIImageView!
    
    var delegate: GroupTableViewCellDelegate?
    
    func enableDelete(){
        //enable post to be deleted by unhiding and enabling button
        let tapGestureRecognizerDelete = UITapGestureRecognizer(target: self, action: #selector(deleteGroupPressed(tapGestureRecognizer:)))
        deleteButton.isUserInteractionEnabled = true
        deleteButton.addGestureRecognizer(tapGestureRecognizerDelete)
        deleteButton.isHidden = false
    }
    
    func disableDelete(){
        //disable deletion of group
        deleteButton.isHidden = true
        deleteButton.isUserInteractionEnabled = true
    }
    
    /** Deletes a `group`.
     - Parameter tapGestureRecognizer: Gesture performed by the user */
    @objc func deleteGroupPressed(tapGestureRecognizer: UITapGestureRecognizer)
    {
        deleteButton.tintColor = Constants.Colors.darkPurple
        self.delegate?.deleteCell(self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        cellBackground.layer.cornerRadius = 10
        cellBackground.layer.borderColor = .init(srgbRed: 0.62, green: 0.27, blue: 0.90, alpha: 1.0)
        cellBackground.backgroundColor = .systemBackground
        cellBackground.layer.borderWidth = 1
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        checkmark.isHidden = !selected
    }
    
}