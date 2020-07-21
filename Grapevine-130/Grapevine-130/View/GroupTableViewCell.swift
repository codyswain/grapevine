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
    var delegate: GroupsViewControllerDelegate?
    var tableDelegate: GroupTableViewCellDelegate?
    
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
        self.tableDelegate?.deleteCell(self)
    }
    
    //sends info about selected group to delegate
    @objc func groupTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        self.delegate?.groupSelected(self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        //Styling
        cellBackground.layer.cornerRadius = 10
        cellBackground.layer.borderColor = .init(srgbRed: 0.62, green: 0.27, blue: 0.90, alpha: 1.0)
        cellBackground.backgroundColor = Globals.ViewSettings.backgroundColor
        checkmark.backgroundColor = Globals.ViewSettings.backgroundColor
        cellBackground.layer.borderWidth = 1
        
        //Enable Selection (TableViewCell.didSelectIndexAt not working)
        let tapGestureRecognizerSelect = UITapGestureRecognizer(target: self, action: #selector(groupTapped(tapGestureRecognizer:)))
        groupLabel.isUserInteractionEnabled = true
        groupLabel.addGestureRecognizer(tapGestureRecognizerSelect)
        checkmark.isUserInteractionEnabled = true
        checkmark.addGestureRecognizer(tapGestureRecognizerSelect)
    }
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        checkmark.isHidden = !selected
        if selected {
            cellBackground.backgroundColor = Globals.ViewSettings.backgroundColor.darker(by: 10)
            checkmark.backgroundColor = Globals.ViewSettings.backgroundColor.darker(by: 10)
        } else {
            cellBackground.backgroundColor = Globals.ViewSettings.backgroundColor
            checkmark.backgroundColor = Globals.ViewSettings.backgroundColor
        }
        
        self.delegate?.groupSelected(self)
        
    }
    
}

extension UIColor {

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
