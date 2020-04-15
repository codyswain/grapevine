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

protocol CommentViewControllerDelegate {
    func updateTableViewVotes(_ post: Post, _ newVote: Int, _ newVoteStatus: Int)
    func updateTableViewFlags(_ post: Post, newFlagStatus: Int)
    func showSharePopup(_ postType: String, _ content: UIImage)
}

class CommentViewController: UIViewController {
    @IBOutlet weak var postContentLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    // Outlets for creating a new comment
    @IBOutlet weak var inputTextContainerView: UIView!
    @IBOutlet weak var inputBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var inputContainerView: UIView!
    @IBOutlet weak var commentInput: UITextField!
    @IBOutlet weak var imageVar: UIImageView!
    @IBOutlet weak var actionBar: UIView!
    @IBOutlet weak var startApostrophe: UIImageView!
    @IBOutlet weak var endApostrophe: UIImageView!
    
    @IBAction func actionsButtonPressed(_ sender: Any) {
        alertActions()
    }
    
    var postID: String = ""
    var comments: [Comment] = []
    let db = Firestore.firestore()
    var commentsManager = CommentsManager()
    var indicator = UIActivityIndicatorView()
    var mainPost: Post?
    var delegate: CommentViewControllerDelegate?
    let postManager = PostsManager()
    var mainPostScreenshot: UIImage?
    var storyManager = StoryManager()

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
        if (mainPost?.type == "text"){
            postContentLabel.text = mainPost!.content
        } else {
            displayImage()
        }
        adjustFrame()
        
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
        
        // Close keyboard when tapping anywhere
        let tap = UITapGestureRecognizer(target: self.view,
                                         action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tap)
        
        
    }
    
    func displayImage(){
        postContentLabel.isHidden = true
        startApostrophe.isHidden = true
        endApostrophe.isHidden = true
        if let decodedData = Data(base64Encoded: mainPost!.content, options: .ignoreUnknownCharacters) {
            let image = UIImage(data: decodedData)!
            let scale: CGFloat
            if image.size.width > image.size.height {
                scale = imageVar.bounds.width / image.size.width
            } else {
                scale = imageVar.bounds.height / image.size.height
            }
            
            imageVar.image = image
            let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            
            UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
            image.draw(in: rect)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            imageVar.image = newImage
        }
    }
    
    func adjustFrame(){
        let heightInPoints = mainPostScreenshot?.size.height
        let heightInPixels = heightInPoints! * mainPostScreenshot!.scale
        if (mainPost?.type == "text"){
            self.actionBar.frame.origin.x = 0
            self.actionBar.frame.origin.y = max(heightInPixels / 2.5, 150)
        } else {
            self.actionBar.frame.origin.x = 0
            self.actionBar.frame.origin.y = max(heightInPixels / 2, 250)
        }
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
            if (postContent != "" && postContent != "Add an anonymous comment...") {
                commentsManager.performPOSTRequest(text:postContent, postID: postID)
            }
        }
        commentInput.endEditing(true)
        commentInput.text = "Add an anonymous comment..."
//        self.performSegue(withIdentifier: "goToMain", sender: self)
    }
        
    func alertActions(){
        let alert = UIAlertController(title: "Do Something", message: "Upvote, Downvote, Flag", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Upvote", style: .default){ (action:UIAlertAction) in
            self.upvoteTapped()
        })
        alert.addAction(UIAlertAction(title: "Downvote", style: .default){ (action:UIAlertAction) in
            self.downvoteTapped()
        })
        alert.addAction(UIAlertAction(title: "Share Comments", style: .default){ (action:UIAlertAction) in
            self.storyManager.shareImageToSnapNoSticker(self.createCommentsImage()!)
        })
        alert.addAction(UIAlertAction(title: "Flag", style: .default){ (action:UIAlertAction) in
            self.flagTapped()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive) { (action:UIAlertAction) in
        })
        alert.view.tintColor = Constants.Colors.darkPurple
        self.present(alert, animated: true)
    }
    
    func upvoteTapped(){
        var currentVoteStatus = mainPost?.voteStatus
        if currentVoteStatus == 0 { // post was not voted on (neutral), after upvoting will be upvoted
            currentVoteStatus = 1
            postManager.performInteractionRequest(interaction: 1, docID: mainPost?.postId ?? "-1")
            self.delegate?.updateTableViewVotes(mainPost!, 1, currentVoteStatus ?? 0)
        } else if currentVoteStatus == -1 { // post was downvoted, after upvoting will be neutral
            currentVoteStatus = 0
            postManager.performInteractionRequest(interaction: 2, docID: mainPost?.postId ?? "-1")
            self.delegate?.updateTableViewVotes(mainPost!, 1, currentVoteStatus ?? 0)
        } else { // post was upvoted, after upvoting will be neutral
            currentVoteStatus = 0
            postManager.performInteractionRequest(interaction: 1, docID: mainPost?.postId ?? "-1")
            self.delegate?.updateTableViewVotes(mainPost!, -1, currentVoteStatus ?? 0)
        }
    }
    
    func downvoteTapped(){
        var currentVoteStatus = mainPost?.voteStatus
        if currentVoteStatus == 0 { // post was not voted on (neutral), after downvoting will be downvoted
            currentVoteStatus = -1
            postManager.performInteractionRequest(interaction: 2, docID: mainPost?.postId ?? "-1")
            self.delegate?.updateTableViewVotes(mainPost!, -1, currentVoteStatus ?? 0)
        } else if currentVoteStatus == 1 { // post was upvoted, after downvoting will be neutral
            currentVoteStatus = 0
            postManager.performInteractionRequest(interaction: 1, docID: mainPost?.postId ?? "-1")
            self.delegate?.updateTableViewVotes(mainPost!, -1, currentVoteStatus ?? 0)
        } else { // post was downvoted, after downvoting will be neutral
            currentVoteStatus = 0
            postManager.performInteractionRequest(interaction: 2, docID: mainPost?.postId ?? "-1")
            self.delegate?.updateTableViewVotes(mainPost!, 1, currentVoteStatus ?? 0)
        }
    }
    
    func flagTapped(){
        var currentFlagStatus = mainPost?.flagStatus
        // wasn't flagged, now is flagged
        if currentFlagStatus == 0 {
            currentFlagStatus = 1
            self.delegate?.updateTableViewFlags(mainPost!, newFlagStatus: 1)
        // was flagged, now isn't flagged
        } else {
            currentFlagStatus = 0
            self.delegate?.updateTableViewFlags(mainPost!, newFlagStatus: 0)
        }
        postManager.performInteractionRequest(interaction: 4, docID: mainPost?.postId ?? "-1")
    }
    
    func createCommentsImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.view.frame.size, false, 0.0)
        if let currentContext = UIGraphicsGetCurrentContext() {
            self.view.layer.render(in: currentContext)
            let nameImage = UIGraphicsGetImageFromCurrentImageContext()
            return nameImage
        }
        return nil
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
            cell.voteButtonIcon.tintColor = UIColor.white
        } else {
            cell.voteBackground.backgroundColor = Constants.Colors.veryLightgrey
            cell.voteButton.setTitleColor(UIColor.black, for: .normal)
            cell.voteButtonIcon.tintColor = UIColor.black
        }
        
        // If the current user created this comment, he/she can delete it
//            if (Constants.userID == posts[indexPath.row].poster){
//                cell.enableDelete()
//            } else {
//                cell.disableDelete()
//            }
        
        // Ensure cell can communicate with this view controller
        cell.delegate = self
        
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

extension CommentViewController: CommentTableViewCellDelegate {
    func updateTableViewVotes(_ cell: UITableViewCell, _ newVote: Int, _ newVoteStatus: Int) {
        let indexPath = self.tableView.indexPath(for: cell)!
        let row = indexPath.row
        comments[row].votes = comments[row].votes + newVote
        comments[row].voteStatus = newVoteStatus
    }
}
