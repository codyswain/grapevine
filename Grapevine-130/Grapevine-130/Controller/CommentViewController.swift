//
//  CommentViewController.swift
//  Grapevine-130
//
//  Created by Cody Swain on 3/23/20.
//  Copyright © 2020 Anthony Humay. All rights reserved.
//

import UIKit



class CommentViewController: UIViewController {
    @IBOutlet weak var inputTextContainerView: UIView!
    @IBOutlet weak var postContentLabel: UILabel!
    @IBOutlet weak var inputBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var inputContainerView: UIView!
    @IBOutlet weak var commentInput: UITextField!
    var mainPost: Post?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        commentInput.text = "Add an anonymous comment..."
        commentInput.clearsOnBeginEditing = true
        postContentLabel.text = mainPost!.content
        inputTextContainerView.layer.cornerRadius = 17
        print(mainPost!)
        
        NotificationCenter.default.addObserver(self, selector: #selector(CommentViewController.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(CommentViewController.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // Move comment input box up when keyboard opens
    @objc func keyboardWillShow(notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            inputContainerView.frame.size.height -= 22.0
            inputBottomConstraint.constant = keyboardSize.height - 22.0
            view.setNeedsLayout()
        }

    }

    // Move comment input back down when keyboard closes
    @objc func keyboardWillHide(notification: Notification) {
        inputContainerView.frame.size.height += 22.0
        inputBottomConstraint.constant = 0.0
        view.setNeedsLayout()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
