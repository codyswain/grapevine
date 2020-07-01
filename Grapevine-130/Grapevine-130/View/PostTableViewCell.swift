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

protocol ShoutPostTableViewCellDelegate {
    func shoutPost(_ cell: UITableViewCell)
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
    @IBOutlet weak var shoutButtonVar: UIButton!
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
    var shoutDelegate: ShoutPostTableViewCellDelegate?
    var deletable = false
    var postType = ""
    var shoutable = false
    
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
        self.upvoteImageButton.isHidden = false
        self.downvoteImageButton.isHidden = false
    }
    
    func disableInteraction() {
        self.upvoteImageButton.isHidden = true
        self.downvoteImageButton.isHidden = true
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
        var color = UIColor.systemGray2
        var baseColor: UIColor = .systemBackground
        if shoutable {
            color = Constants.Colors.yellow
            baseColor = .systemBackground
        }
        commentButton.tintColor = baseColor
        downvoteImageButton.isHidden = false
        upvoteImageButton.isHidden = true
        shareButton.tintColor = baseColor
        footer.backgroundColor = color
        downvoteImageButton.tintColor = baseColor
        voteCountLabel.textColor = baseColor
        commentButton.setTitleColor(color, for: .normal)
    }
    
    /**
    Modify post colors to reflect no vote.
    */
    func setNeutralColors(){
        var buttonColor = UIColor.systemGray3
        var footerColor = UIColor.systemGray5
        var textColor = UIColor.label
        if self.shoutable {
            buttonColor = .systemBackground
            footerColor = Constants.Colors.yellow
            textColor = .label
        }
        downvoteImageButton.isHidden = false
        upvoteImageButton.isHidden = false
        shareButton.isHidden = false
        decideFlagColors()
        footer.backgroundColor = footerColor
        commentButton.tintColor = buttonColor
        upvoteImageButton.tintColor = buttonColor
        downvoteImageButton.tintColor = buttonColor
        shareButton.tintColor = buttonColor
        voteCountLabel.textColor = textColor
        commentButton.setTitleColor(footerColor, for: .normal)
    }
    
    /**
    Modify post colors to reflect an upvote.
    */
    func setUpvotedColors(){
        var color = Constants.Colors.darkPurple
        var baseColor: UIColor = .systemBackground
        if shoutable {
            color = Constants.Colors.yellow
            baseColor = .systemBackground
        }
        commentButton.tintColor = baseColor
        downvoteImageButton.isHidden = true
        upvoteImageButton.isHidden = false
        shareButton.isHidden = false
        shareButton.tintColor = baseColor
        footer.backgroundColor = color
        upvoteImageButton.tintColor = baseColor
        voteCountLabel.textColor = baseColor
        commentButton.setTitleColor(color, for: .normal)
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
        commentButton.tintColor = UIColor.systemGray2
    }
    
    /**
    Modify flag colors on a post to reflect an un-flagged status by the user.
    */
    func setUnflaggedColors(){
        commentButton.tintColor = UIColor.systemGray5
    }
    
    func decideFlagColors(){
        if currentFlagStatus == 1 {
            commentButton.tintColor = .systemBackground
        }
        if currentVoteStatus == -1 {
            commentButton.tintColor = .systemBackground
        } else {
            commentButton.tintColor = UIColor.systemGray5
        }
        
    }
        
    /// Button to ban users from the ban chamber.
    @IBAction func banButton(_ sender: Any) {
        self.banDelegate?.banPoster(self)
    }
    
    @IBAction func shoutButton(_ sender: Any) {
        self.shoutDelegate?.shoutPost(self)
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
            self.upvoteImageButton.isHidden = true
            self.upvoteImageButton.isHidden = true
        }
        return im
    }
    
    /**
    Changes the comment count number into a readable abbreviated string. Large numbers are abbreviated to the nearest hundredth.
    
    - Parameter numComments: Number of comments under the post
    - Returns: Abbreviated string representation of the comment count
    */
    func getCommentCount(numComments: Int) -> String {
        if numComments >= 1000 {
            let digit = numComments / 1000
            let rem = (numComments % 1000) / 100
            
            return "\(digit).\(rem)k"
        } else {
            return "\(numComments)"
        }
    }
    
    func makeBasicCell(post: Post) {
        // Reset cell attributes before reusing
        self.imageVar.image = nil
        self.deleteButton.tintColor = UIColor.systemGray5
        self.label.font = self.label.font.withSize(16)
        self.commentAreaButton.backgroundColor = UIColor.systemGray6
        self.label.textColor = UIColor.label
        
        // Set main body of post cell
        if (post.type == "text"){
            self.label.text = post.content
            self.postType = "text"
        } else {
            if let decodedData = Data(base64Encoded: post.content, options: .ignoreUnknownCharacters) {
                self.label.text = ""
                self.postType = "image"
                self.imageVar.image = decodeImage(imageData: decodedData, width: self.imageVar.bounds.width, height: self.imageVar.bounds.height)
            }
        }
        
        // Set the document id of the post
        self.documentId = post.postId
        
        // Set vote count of post cell
        self.voteCountLabel.text = String(post.votes)
        
        // Set vote status
        self.currentVoteStatus = post.voteStatus
        
        // Set flag status
//        self.currentFlagStatus = post.flagStatus
        
        // Set number of flags
//        self.currentFlagNum = post.numFlags
        
        // Set the comment count number
        if post.comments > 0 {
            // Show number of comments if there are comments
            let commentText = self.getCommentCount(numComments: post.comments)
            self.commentButton.setTitle(commentText, for: .normal)
            self.commentButton.setBackgroundImage(UIImage(systemName: "circle.fill"), for: .normal)
        } else {
            // Show comment symbol if there are no comments
            self.commentButton.setTitle("", for: .normal)
            self.commentButton.setBackgroundImage(UIImage(systemName: "message.circle.fill"), for: .normal)
        }
        
        
    }
}
