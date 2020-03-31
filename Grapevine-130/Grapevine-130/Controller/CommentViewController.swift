//
//  CommentViewController.swift
//  Grapevine-130
//
//  Created by Cody Swain on 3/23/20.
//  Copyright © 2020 Anthony Humay. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseFirestore

class CommentViewController: UIViewController {
    @IBOutlet weak var postContentLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    // Outlets for creating a new comment
    @IBOutlet weak var inputTextContainerView: UIView!
    @IBOutlet weak var inputBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var inputContainerView: UIView!
    @IBOutlet weak var commentInput: UITextField!
    
    @IBAction func actionsButtonPressed(_ sender: Any) {
        alertActions()
    }
    
    var postID: String = ""
    var comments: [Comment] = []
    let db = Firestore.firestore()
    var commentsManager = CommentsManager()
    var indicator = UIActivityIndicatorView()
    var mainPost: Post?
    
    
    // Define Refresher
    lazy var refresher: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = .black
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return refreshControl
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        commentInput.text = "Add an anonymous comment..."
        commentInput.clearsOnBeginEditing = true
        postContentLabel.text = mainPost!.content
        inputTextContainerView.layer.cornerRadius = 10
        
        // Reposition input when keyboard is opened vs closed
        NotificationCenter.default.addObserver(self, selector: #selector(CommentViewController.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(CommentViewController.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // Get comments related to post
        postID = mainPost!.postId
        commentsManager.delegate = self
        commentsManager.fetchComments(postID: postID, userID: Constants.userID)
        
        // Load table
        tableView.dataSource = self
        tableView.refreshControl = refresher
        tableView.register(UINib(nibName: Constants.commentsCellNibName, bundle: nil), forCellReuseIdentifier: Constants.cellIdentifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 150
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
    }
    
    /// Refresh the main posts view based on current user location.
    @objc func refresh(){
        commentsManager.fetchComments(postID: postID, userID: Constants.userID)
        let deadline = DispatchTime.now() + .milliseconds(1000)
        DispatchQueue.main.asyncAfter(deadline: deadline){
            self.refresher.endRefreshing()
        }
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
    
    
    @IBAction func submitButtonPressed(_ sender: Any) {
        if let postContent = commentInput.text {
            if postContent != "" {
                commentsManager.performPOSTRequest(text:postContent, postID: postID)
            }
        }
        commentInput.endEditing(true)
        commentInput.text = "Add an anonymous comment..."
//        self.performSegue(withIdentifier: "goToMain", sender: self)
    }
    
    /*
     // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    func alertActions(){
        let alert = UIAlertController(title: "Do Something", message: "Upvote, Downvote, Share, Flag", preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Upvote", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Downvote", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Share", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Flag", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Nevermind", style: .destructive) { (action:UIAlertAction) in
        })
        alert.view.tintColor = Constants.Colors.darkPurple
        self.present(alert, animated: true)
    }

}

/// Manages the posts table.
extension CommentViewController: UITableViewDataSource {
    /**
     Tells the table how many cells are needed.
     
     - Parameters:
        - tableView: Table to be updated
        - section: Number of rows in the section
     
     - Returns: The number of posts in the table
     */
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (comments.count != 0){
                indicator.stopAnimating()
                indicator.hidesWhenStopped = true
            // put indicator here
        }
        print("Comments count\(comments.count)")
        return comments.count
    }
    
    /**
     Describes how to display a cell for each post.
     
     - Parameters:
        - tableView: Table being displayed
        - indexPath: Indicates which post to create a cell for.
     
     - Returns: Updated table cell
     */
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier, for: indexPath) as! CommentTableViewCell
        
        // Variables retrieved from GET request
        let commentText = comments[indexPath.row].content
        let voteCount = comments[indexPath.row].votes
        let commentID = comments[indexPath.row].commentID
        let voteStatus = comments[indexPath.row].voteStatus
        
        // Setting initial values
        cell.voteButton.setTitle(String(voteCount), for: .normal)
        cell.label.text = commentText
        cell.commentID = commentID
        cell.voteStatus = voteStatus
        
        // Setting styling for liked posts
        if (voteStatus == 1){
            cell.voteBackground.backgroundColor = Constants.Colors.darkPurple
            cell.voteButton.setTitleColor(UIColor.white, for: .normal)
        } else {
            cell.voteBackground.backgroundColor = Constants.Colors.veryLightgrey
            cell.voteButton.setTitleColor(UIColor.black, for: .normal)
        }
        
        // If the current user created this comment, he/she can delete it
//            if (Constants.userID == posts[indexPath.row].poster){
//                cell.enableDelete()
//            } else {
//                cell.disableDelete()
//            }
        
        // Ensure cell can communicate with this view controller
//        cell.delegate = self
        
        // Refresh the display of the cell
//        cell.refreshView()
        
        return cell
    }
}

extension CommentViewController: CommentsManagerDelegate {
    func didUpdateComments(_ commentManager: CommentsManager, comments: [Comment]){
        DispatchQueue.main.async {
            self.comments = comments
            print(comments)
            self.tableView.reloadData()
        }
    }
    func didFailWithError(error: Error) {
        print(error)
    }
    func didCreateComment() {
        commentsManager.fetchComments(postID: postID, userID: Constants.userID)
    }
}
