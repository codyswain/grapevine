import UIKit

protocol PostTableViewCellDelegate {
    func updateTableViewVotes(_ cell: UITableViewCell, _ newVote: Int, _ newVoteStatus: Int)
    func updateTableViewFlags(_ cell: UITableViewCell, newFlagStatus: Int)
    func deleteCell( _ cell: UITableViewCell)
    func showSharePopup(_ postType: String, _ content: UIImage)
    func viewComments(_ cell: UITableViewCell, _ postScreenshot: UIImage)
}

protocol BannedPostTableViewCellDelegate {
    func banPoster(_ cell: UITableViewCell)
}

/// Describes a cell in the posts table
class PostTableViewCell: UITableViewCell {
    // Objects used to interface with UI
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var commentAreaButton: UIView!
    @IBOutlet weak var voteCountLabel: UILabel!
    @IBOutlet weak var downvoteImageButton: UIImageView!
    @IBOutlet weak var upvoteImageButton: UIImageView!
    @IBOutlet weak var footer: UIView!
    @IBOutlet weak var deleteButton: UIImageView!
    @IBOutlet weak var banButtonVar: UIButton!
    @IBOutlet weak var shareButton: UIImageView!
    @IBOutlet weak var imageVar: UIImageView!
    @IBOutlet weak var commentButton: UIButton!
    let postManager = PostsManager()
    var currentVoteStatus = 0
    var currentFlagStatus = 0
    var currentFlagNum = 0
    var documentId = ""
    var delegate: PostTableViewCellDelegate?
    var banDelegate: BannedPostTableViewCellDelegate?
    var deletable = false
    var postType = ""
    
    /**
    Initializes the posts table and adds gestures.
    */
    override func awakeFromNib() {
        super.awakeFromNib() //Some pre-built thing
                
        // Add tapping capabilities to downvote button (UIImageView)
        let tapGestureRecognizerDownvote = UITapGestureRecognizer(target: self, action: #selector(downvoteTapped(tapGestureRecognizer:)))
        downvoteImageButton.isUserInteractionEnabled = true
        downvoteImageButton.addGestureRecognizer(tapGestureRecognizerDownvote)
        
        // Add tapping capabilities to upvote button (UIImageView)
        let tapGestureRecognizerUpvote = UITapGestureRecognizer(target: self, action: #selector(upvoteTapped(tapGestureRecognizer:)))
        upvoteImageButton.isUserInteractionEnabled = true
        upvoteImageButton.addGestureRecognizer(tapGestureRecognizerUpvote)
        
        // Tapping capabilities for flag button
        let tapGestureRecognizerFlag = UITapGestureRecognizer(target: self, action: #selector(commentTapped(tapGestureRecognizer:)))
        commentButton.isUserInteractionEnabled = true
        commentButton.addGestureRecognizer(tapGestureRecognizerFlag)
        
        // Tapping capabilities for share button
        let tapGestureRecognizerShare = UITapGestureRecognizer(target: self, action: #selector(shareTapped(tapGestureRecognizer:)))
        shareButton.isUserInteractionEnabled = true
        shareButton.addGestureRecognizer(tapGestureRecognizerShare)
        
        let tapGestureRecognizerComment = UITapGestureRecognizer(target: self, action: #selector(commentTapped(tapGestureRecognizer:)))
        commentAreaButton.isUserInteractionEnabled = true
        commentAreaButton.addGestureRecognizer(tapGestureRecognizerComment)
        
        let pressGestureRecognizerOptions = UILongPressGestureRecognizer(target: self, action: #selector(optionsPressed(longPressGestureRecognizer:)))
        commentAreaButton.isUserInteractionEnabled = true
        commentAreaButton.addGestureRecognizer(pressGestureRecognizerOptions)
    }
    
    /**
    Update the client view of a post.
    */
    func refreshView(){
        // Render the cell colors
        if self.currentVoteStatus == 0 {
            setNeutralColors()
        } else if self.currentVoteStatus == -1 {
            setDownvotedColors()
        } else {
            setUpvotedColors()
        }
        
        if self.currentFlagStatus == 1 {
            setFlaggedColors()
        }
    }
    
    /**
    Enable deletion of a post.
    */
    func enableDelete(){
        // Set up delete button
        print("Deletable: \(documentId)")
        let tapGestureRecognizer3 = UITapGestureRecognizer(target: self, action: #selector(deleteTapped(tapGestureRecognizer:)))
        deleteButton.isUserInteractionEnabled = true
        deleteButton.addGestureRecognizer(tapGestureRecognizer3)
        deleteButton.isHidden = false
    }
    
    /**
    Disable deletion of a post.
    */
    func disableDelete(){
        print("Not deletable: \(documentId)")
        deleteButton.isHidden = true
    }
    
    func enableInteraction() {
        DispatchQueue.main.async {
            self.upvoteImageButton.isHidden = false
            self.downvoteImageButton.isHidden = false
        }
    }
    
    func disableInteraction() {
        DispatchQueue.main.async {
            self.upvoteImageButton.isHidden = true
            self.downvoteImageButton.isHidden = true
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    // Auto-generated
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    /**
    Update vote information when user upvotes a `post`.
     
    - Parameter tapGestureRecognizer: Gesture performed by the user
    */
    @objc func upvoteTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        if self.currentVoteStatus == 0 { // post was not voted on (neutral), after upvoting will be upvoted
            currentVoteStatus = 1
            postManager.performInteractionRequest(interaction: 1, docID: self.documentId)
            setUpvotedColors()
            voteCountLabel.text = String(Int(String(voteCountLabel.text!))! + 1)
            self.delegate?.updateTableViewVotes(self, 1, currentVoteStatus)
        } else if self.currentVoteStatus == -1 { // post was downvoted, after upvoting will be neutral
            currentVoteStatus = 0
            postManager.performInteractionRequest(interaction: 2, docID: self.documentId)
            setNeutralColors()
            voteCountLabel.text = String(Int(String(voteCountLabel.text!))! + 1)
            self.delegate?.updateTableViewVotes(self, 1, currentVoteStatus)
        } else { // post was upvoted, after upvoting will be neutral
            currentVoteStatus = 0
            postManager.performInteractionRequest(interaction: 1, docID: self.documentId)
            setNeutralColors()
            voteCountLabel.text = String(Int(String(voteCountLabel.text!))! - 1)
            self.delegate?.updateTableViewVotes(self, -1, currentVoteStatus)
        }
    }

    /**
    Update vote information when user downvotes a `post`.
     
    - Parameter tapGestureRecognizer: Gesture performed by the user
    */
    @objc func downvoteTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        if self.currentVoteStatus == 0 { // post was not voted on (neutral), after downvoting will be downvoted
            currentVoteStatus = -1
            postManager.performInteractionRequest(interaction: 2, docID: self.documentId)
            setDownvotedColors()
            voteCountLabel.text = String(Int(String(voteCountLabel.text!))! - 1)
            self.delegate?.updateTableViewVotes(self, -1, currentVoteStatus)
        } else if self.currentVoteStatus == 1 { // post was upvoted, after downvoting will be neutral
            currentVoteStatus = 0
            postManager.performInteractionRequest(interaction: 1, docID: self.documentId)
            setNeutralColors()
            voteCountLabel.text = String(Int(String(voteCountLabel.text!))! - 1)
            self.delegate?.updateTableViewVotes(self, -1, currentVoteStatus)
        } else { // post was downvoted, after downvoting will be neutral
            currentVoteStatus = 0
            postManager.performInteractionRequest(interaction: 2, docID: self.documentId)
            setNeutralColors()
            voteCountLabel.text = String(Int(String(voteCountLabel.text!))! + 1)
            self.delegate?.updateTableViewVotes(self, 1, currentVoteStatus)
        }
    }
    
    /**
    Deletes a `post`.
     
    - Parameter tapGestureRecognizer: Gesture performed by the user
    */
    @objc func deleteTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        deleteButton.tintColor = Constants.Colors.darkPurple
        self.delegate?.deleteCell(self)
    }
    
    /**
    Flags a `post`.
     
    - Parameter tapGestureRecognizer: Gesture performed by the user
    */
    @objc func flagTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        // wasn't flagged, now is flagged
        if self.currentFlagStatus == 0 {
            self.currentFlagStatus = 1
            resetFlagColors()
            self.delegate?.updateTableViewFlags(self, newFlagStatus: 1)
        // was flagged, now isn't flagged
        } else {
            self.currentFlagStatus = 0
            resetFlagColors()
            self.delegate?.updateTableViewFlags(self, newFlagStatus: 0)
        }
        
        postManager.performInteractionRequest(interaction: 4, docID: self.documentId)
    }
        
    @objc func shareTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        if postType == "text" {
            self.delegate?.showSharePopup("text", createTableCellImage() ?? nil!)
        } else {
            self.delegate?.showSharePopup("image", createTableCellImage() ?? nil!)
        }
    }
    
    // Segue to view comment screen
    @objc func commentTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        self.delegate?.viewComments(self, (createTableCellImage() ?? nil)!)
    }
    
    @objc func optionsPressed(longPressGestureRecognizer: UILongPressGestureRecognizer)
    {
//        let generator = UIImpactFeedbackGenerator(style: .medium)
//        generator.impactOccurred()
//        self.delegate?.viewOptions(self);
    }
    
    
    /**
    Modify post colors to reflect a downvote.
    */
    func setDownvotedColors(){
        commentButton.tintColor = UIColor.white
        downvoteImageButton.isHidden = false
        upvoteImageButton.isHidden = true
//        shareButton.isHidden = true
        shareButton.tintColor = .white
        footer.backgroundColor = Constants.Colors.veryDarkGrey
        downvoteImageButton.tintColor = .white
        voteCountLabel.textColor = .white
        commentButton.setTitleColor(Constants.Colors.veryDarkGrey, for: .normal)
    }
    
    /**
    Modify post colors to reflect no vote.
    */
    func setNeutralColors(){
        
        downvoteImageButton.isHidden = false
        upvoteImageButton.isHidden = false
        shareButton.isHidden = false
        decideFlagColors()
        footer.backgroundColor = Constants.Colors.darkGrey
        upvoteImageButton.tintColor = Constants.Colors.lightGrey
        downvoteImageButton.tintColor = Constants.Colors.lightGrey
        shareButton.tintColor = Constants.Colors.lightGrey
        voteCountLabel.textColor = .black
        commentButton.setTitleColor(Constants.Colors.darkGrey, for: .normal)
    }
    
    /**
    Modify post colors to reflect an upvote.
    */
    func setUpvotedColors(){
        commentButton.tintColor = UIColor.white
        downvoteImageButton.isHidden = true
        upvoteImageButton.isHidden = false
        shareButton.isHidden = false
        shareButton.tintColor = .white
        footer.backgroundColor = Constants.Colors.darkPurple
        upvoteImageButton.tintColor = .white
        voteCountLabel.textColor = .white
        commentButton.setTitleColor(Constants.Colors.darkPurple, for: .normal)
    }
    
    /**
    Modify flag colors on a post.
    */
    func resetFlagColors(){
        if self.currentFlagStatus == 0 {
            setUnflaggedColors()
        } else {
            setFlaggedColors()
        }
    }
    
    /**
    Modify flag colors on a post to reflect a flagged status by the user.
    */
    func setFlaggedColors(){
        commentButton.tintColor = Constants.Colors.veryDarkGrey
    }
    
    /**
    Modify flag colors on a post to reflect an un-flagged status by the user.
    */
    func setUnflaggedColors(){
        commentButton.tintColor = Constants.Colors.lightGrey
    }
    
    func decideFlagColors(){
        if currentFlagStatus == 1 {
            commentButton.tintColor = .white
        }
        if currentVoteStatus == -1 {
            commentButton.tintColor = .white
        } else {
            commentButton.tintColor = Constants.Colors.lightGrey
        }
        
    }
        
    /// Button to ban users from the ban chamber.
    @IBAction func banButton(_ sender: Any) {
        self.banDelegate?.banPoster(self)
    }
    
    func createTableCellImage() -> UIImage? {
        var im:UIImage?
        if deletable {
            self.deleteButton.isHidden = true
            self.upvoteImageButton.isHidden = false
            self.downvoteImageButton.isHidden = false
        }
        UIGraphicsBeginImageContextWithOptions(self.frame.size, false, 0.0)
        if let currentContext = UIGraphicsGetCurrentContext() {
            self.layer.render(in: currentContext)
            im = UIGraphicsGetImageFromCurrentImageContext()
        }
        if deletable {
            self.deleteButton.isHidden = false
        }
        return im
    }
    
    func getCommentCount(numComments: Int) -> String {
        if numComments >= 1000 {
            let digit = numComments / 1000
            let rem = (numComments % 1000) / 100
            
            return "\(digit).\(rem)k"
        } else {
            return "\(numComments)"
        }
    }
}
