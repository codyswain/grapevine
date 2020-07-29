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
    
    //MARK: Cell Utility Methods
    
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
        deleteButton.isUserInteractionEnabled = false
    }
    
    //MARK: Cell Interaction Methods
    
    @objc func deleteGroupPressed(tapGestureRecognizer: UITapGestureRecognizer) {
        //Indicates interaction with delete button and sends function call to GroupTableViewCellDelegate
        deleteButton.tintColor = Constants.Colors.darkPurple
        self.delegate?.deleteCell(self)
    }
    
    //MARK: Cell Initialization
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialize the styling of the cells
        cellBackground.layer.cornerRadius = 10
//        cellBackground.backgroundColor = Constants.Colors.
        checkmark.backgroundColor = Globals.ViewSettings.backgroundColor
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configures the appearance of the cell when it is selected
        checkmark.isHidden = !selected
        if selected {
            cellBackground.backgroundColor = Globals.ViewSettings.backgroundColor.darker(by: 10)
            checkmark.backgroundColor = Globals.ViewSettings.backgroundColor.darker(by: 10)
        } else {
            cellBackground.backgroundColor = Globals.ViewSettings.backgroundColor
            checkmark.backgroundColor = Globals.ViewSettings.backgroundColor
        }
        
    }
    
}

//MARK: Extensions

extension UIColor {
    // Utility extension for setting the colors of selected cells. Makes a UIColor loighter or darker by a specified percentage

    func lighter(by percentage: CGFloat = 30.0) -> UIColor? {
        return self.adjust(by: abs(percentage) )
    }

    func darker(by percentage: CGFloat = 30.0) -> UIColor? {
        return self.adjust(by: -1 * abs(percentage) )
    }

    func adjust(by percentage: CGFloat = 30.0) -> UIColor? {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return UIColor(red: min(red + percentage/100, 1.0),
                           green: min(green + percentage/100, 1.0),
                           blue: min(blue + percentage/100, 1.0),
                           alpha: alpha)
        } else {
            return nil
        }
    }
}
