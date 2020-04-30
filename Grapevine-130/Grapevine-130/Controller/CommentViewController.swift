//
//  CommentViewController.swift
//  Grapevine-130
//
//  Created by Cody Swain on 3/23/20.
//  Copyright © 2020 Anthony Humay. All rights reserved.
//

import UIKit

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
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var actionsButtonVar: UIButton!
    @IBOutlet weak var shareButtonVar: UIButton!
    
    @IBAction func actionsButtonPressed(_ sender: Any) {
        alertActions()
    }
    
    @IBAction func shareCommentsPressed(_ sender: Any) {
        let alert = UIAlertController(title: "Share", message: "Share post with friends!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Snapchat", style: .default){ (action:UIAlertAction) in
            self.storyManager.shareCommentsToSnap(self.createCommentsImage()!)
        })
        alert.addAction(UIAlertAction(title: "Instagram Stories", style: .default){ (action:UIAlertAction) in
            self.storyManager.shareCommentsToInstagram(self.createCommentsImage()!)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive) { (action:UIAlertAction) in
        })
        alert.view.tintColor = .black
        self.present(alert, animated: true)
    }
    
    var postID: String = ""
    var comments: [Comment] = []
    var commentsManager = CommentsManager()
    var indicator = UIActivityIndicatorView()
    var mainPost: Post?
    var delegate: CommentViewControllerDelegate?
    let postManager = PostsManager()
    var mainPostScreenshot: UIImage?
    var storyManager = StoryManager()
    var newCommentCreated: Bool = false // fixes auto scrolling bug

    // Define Refresher
    lazy var refresher: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = .black
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return refreshControl
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Show loading symbol
        activityIndicator()
        indicator.startAnimating()
        indicator.backgroundColor = .white
        
        // Load table
        tableView.dataSource = self
        tableView.refreshControl = refresher
        tableView.register(UINib(nibName: Constants.commentsCellNibName, bundle: nil), forCellReuseIdentifier: Constants.cellIdentifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 150
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        
        commentInput.text = "Add an anonymous comment..."
        commentInput.clearsOnBeginEditing = false;
        if (mainPost?.type == "text"){
            postContentLabel.text = mainPost!.content
        } else {
            displayImage()
        }
        adjustFrame()
        
        inputTextContainerView.layer.cornerRadius = 10
        
        // Reposition input when keyboard is opened vs closed
        NotificationCenter.default.addObserver(self, selector: #selector(CommentViewController.keyboardDidShow), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(CommentViewController.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(CommentViewController.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // Get comments related to post
        postID = mainPost!.postId
        commentsManager.delegate = self
        
        // Close keyboard when tapping anywhere
        let tap = UITapGestureRecognizer(target: self.view,
                                         action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tap)
        commentsManager.fetchComments(postID: postID, userID: Constants.userID)
            
        // Add Done button
        addDoneButton()
        
        // Put in date
        if let millisecondsSince1970 = mainPost?.date {
            let postDate = Date(timeIntervalSince1970: TimeInterval(millisecondsSince1970))
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd HH:mm"
            dateLabel.text = formatter.string(from: postDate)
        }
    }
    /// Displays a loading icon while posts load.
    func activityIndicator() {
        indicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        indicator.style = UIActivityIndicatorView.Style.medium
        indicator.center.y = self.tableView.center.y
        indicator.center.x = self.view.center.x
        self.view.addSubview(indicator)
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
        if (mainPost?.type == "text"){
            let heightInPoints = (mainPostScreenshot?.size.height)! - 20 // - 80 fits perfectly with no space
            self.actionBar.frame.origin.x = 0
            self.actionBar.frame.origin.y = min(heightInPoints, self.view.frame.height / 2)
        } else {
            let heightInPoints = (imageVar.image?.size.height)! + 40
            self.actionBar.frame.origin.x = 0
            self.actionBar.frame.origin.y = max((self.imageVar.image?.accessibilityFrame.origin.y)! + heightInPoints, 250)
        }
    }
        
    /// Refresh the main posts view based on current user location.
    @objc func refresh(){
        commentsManager.fetchComments(postID: postID, userID: Constants.userID)
    }
    
    // Move comment input box up when keyboard opens
    @objc func keyboardDidShow(notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            // Hacky way to scroll posts up (insert footer, then delete it)
            let footer = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: keyboardSize.height-20))
            self.tableView.tableFooterView = footer
            self.tableView.setContentOffset(CGPoint(x: 0, y: self.tableView.contentSize.height), animated: true)
            view.setNeedsLayout()
        }
//
    }
    
    // Move comment input box up when keyboard opens
    @objc func keyboardWillShow(notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            self.inputContainerView.frame.size.height -= 22.0
            self.inputBottomConstraint.constant = keyboardSize.height - 22.0
            UIView.animate(withDuration: 0.1) {
                self.view.layoutIfNeeded()
            }
            
//            let footer = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: keyboardSize.height-20))
//            self.tableView.tableFooterView = footer
//            self.tableView.setContentOffset(CGPoint(x: 0, y: self.tableView.contentSize.height), animated: true)
            
            // Clear comment input if placeholder text is present
            if let postContent = commentInput.text {
                if (postContent == "Add an anonymous comment...") {
                    commentInput.text = "";
                }
            }
            view.setNeedsLayout()
        }

    }

    // Move comment input back down when keyboard closes
    @objc func keyboardWillHide(notification: Notification) {
        // scroll back to bottom of posts
        let footer = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        self.tableView.tableFooterView = footer
        self.tableView.setContentOffset(CGPoint(x: 0, y: self.tableView.contentSize.height), animated: true)
        
        inputContainerView.frame.size.height += 22.0
        inputBottomConstraint.constant = 0.0
        if let postContent = commentInput.text {
            if (postContent == "") {
                commentInput.text = "Add an anonymous comment...";
            }
        }
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
        alert.addAction(UIAlertAction(title: "Share Comments To Snap", style: .default){ (action:UIAlertAction) in
            self.storyManager.shareCommentsToSnap(self.createCommentsImage()!)
        })
        alert.addAction(UIAlertAction(title: "Share Comments To IG", style: .default){ (action:UIAlertAction) in
            self.storyManager.shareCommentsToInstagram(self.createCommentsImage()!)
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
            postManager.performInteractionRequest(interaction: 1, docID: mainPost?.postId ?? "-1", poster: mainPost?.poster ?? "-1")
            self.delegate?.updateTableViewVotes(mainPost!, 1, currentVoteStatus ?? 0)
        } else if currentVoteStatus == -1 { // post was downvoted, after upvoting will be neutral
            currentVoteStatus = 0
            postManager.performInteractionRequest(interaction: 2, docID: mainPost?.postId ?? "-1", poster: mainPost?.poster ?? "-1")
            self.delegate?.updateTableViewVotes(mainPost!, 1, currentVoteStatus ?? 0)
        } else { // post was upvoted, after upvoting will be neutral
            currentVoteStatus = 0
            postManager.performInteractionRequest(interaction: 1, docID: mainPost?.postId ?? "-1", poster: mainPost?.poster ?? "-1")
            self.delegate?.updateTableViewVotes(mainPost!, -1, currentVoteStatus ?? 0)
        }
    }
    
    func downvoteTapped(){
        var currentVoteStatus = mainPost?.voteStatus
        if currentVoteStatus == 0 { // post was not voted on (neutral), after downvoting will be downvoted
            currentVoteStatus = -1
            postManager.performInteractionRequest(interaction: 2, docID: mainPost?.postId ?? "-1", poster: mainPost?.poster ?? "-1")
            self.delegate?.updateTableViewVotes(mainPost!, -1, currentVoteStatus ?? 0)
        } else if currentVoteStatus == 1 { // post was upvoted, after downvoting will be neutral
            currentVoteStatus = 0
            postManager.performInteractionRequest(interaction: 1, docID: mainPost?.postId ?? "-1", poster: mainPost?.poster ?? "-1")
            self.delegate?.updateTableViewVotes(mainPost!, -1, currentVoteStatus ?? 0)
        } else { // post was downvoted, after downvoting will be neutral
            currentVoteStatus = 0
            postManager.performInteractionRequest(interaction: 2, docID: mainPost?.postId ?? "-1", poster: mainPost?.poster ?? "-1")
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
        postManager.performInteractionRequest(interaction: 4, docID: mainPost?.postId ?? "-1", poster: mainPost?.poster ?? "-1")
    }
    
    func createCommentsImage() -> UIImage? {
        let dimensions = CGSize(width: self.view.frame.width, height: self.view.frame.height - 100)
        prepareCommentScreenshot(showElementsToggle:true)
        UIGraphicsBeginImageContextWithOptions(dimensions, false, 0.0)
        if let currentContext = UIGraphicsGetCurrentContext() {
            self.view.layer.render(in: currentContext)
            let nameImage = UIGraphicsGetImageFromCurrentImageContext()
            prepareCommentScreenshot(showElementsToggle:false)
            return nameImage
        }
        prepareCommentScreenshot(showElementsToggle:false)
        return nil
    }
    
    func prepareCommentScreenshot(showElementsToggle: Bool){
        dateLabel.isHidden = showElementsToggle
        actionsButtonVar.isHidden = showElementsToggle
        shareButtonVar.isHidden = showElementsToggle
    }
    
    // Add a "Done" button to close the keyboard
    @objc func tapDone(sender: Any) {
        self.view.endEditing(true)
    }
    
    func addDoneButton(){
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
        doneToolbar.barStyle = .default
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.tapDone))
        
        let items = [flexSpace, done]
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        commentInput.inputAccessoryView = doneToolbar
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
//        if (comments.count != 0){
//                indicator.stopAnimating()
//                indicator.hidesWhenStopped = true
//            // put indicator here
//        }
//        print("Comments count\(comments.count)")
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
            if self.comments.count == 0 {
                let noCommentsLabel = UILabel()
                noCommentsLabel.frame = CGRect(x: CGFloat(0), y: CGFloat(0), width: self.tableView.bounds.width, height: CGFloat(44))
                noCommentsLabel.textAlignment = .center
                noCommentsLabel.text = "🙁 No comments yet..."
                self.tableView.tableHeaderView = noCommentsLabel
                self.tableView.tableHeaderView?.isHidden = false
            } else {
                self.tableView.tableHeaderView = nil
            }
            self.tableView.reloadData()
            self.indicator.stopAnimating()
            self.indicator.hidesWhenStopped = true
            self.tableView.refreshControl?.endRefreshing()
            self.tableView.setContentOffset(CGPoint(x: 0, y: self.tableView.contentSize.height), animated: true)
            if (self.newCommentCreated){
                let indexPath = IndexPath(row: self.comments.count-1, section: 0)
                self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            }
            self.newCommentCreated = false
        }
    }
    func didFailWithError(error: Error) {
        print(error)
    }
    func didCreateComment() {
        self.newCommentCreated = true
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
