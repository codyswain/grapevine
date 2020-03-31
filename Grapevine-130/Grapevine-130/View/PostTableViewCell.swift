import UIKit
import FirebaseDatabase
import FirebaseFirestore


protocol PostTableViewCellDelegate {
    func updateTableViewVotes(_ cell: UITableViewCell, _ newVote: Int, _ newVoteStatus: Int)
    func updateTableViewFlags(_ cell: UITableViewCell, newFlagStatus: Int)
    func deleteCell( _ cell: UITableViewCell)
    func showSharePopup()
    func viewComments(_ cell: UITableViewCell)
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
    @IBOutlet weak var flagButton: UIImageView!
    @IBOutlet weak var banButtonVar: UIButton!
    @IBOutlet weak var shareButton: UIImageView!
    @IBOutlet weak var imageVar: UIImageView!    
    let db = Firestore.firestore()
    let postManager = PostsManager()
    var currentVoteStatus = 0
    var currentFlagStatus = 0
    var currentFlagNum = 0
    var documentId = ""
    var delegate: PostTableViewCellDelegate?
    var banDelegate: BannedPostTableViewCellDelegate?
    var deletable = false
    
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
        let tapGestureRecognizerFlag = UITapGestureRecognizer(target: self, action: #selector(flagTapped(tapGestureRecognizer:)))
        flagButton.isUserInteractionEnabled = true
        flagButton.addGestureRecognizer(tapGestureRecognizerFlag)
        
        // Tapping capabilities for share button
        let tapGestureRecognizerShare = UITapGestureRecognizer(target: self, action: #selector(shareTapped(tapGestureRecognizer:)))
        shareButton.isUserInteractionEnabled = true
        shareButton.addGestureRecognizer(tapGestureRecognizerShare)
        
        let tapGestureRecognizerComment = UITapGestureRecognizer(target: self, action: #selector(commentTapped(tapGestureRecognizer:)))
        commentAreaButton.isUserInteractionEnabled = true
        commentAreaButton.addGestureRecognizer(tapGestureRecognizerComment)
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
            setFlaggedColorsToPurple() // hide the flag icon
            setShareButtonHighlightedColors()
            voteCountLabel.text = String(Int(String(voteCountLabel.text!))! + 1)
            self.delegate?.updateTableViewVotes(self, 1, currentVoteStatus)
        } else if self.currentVoteStatus == -1 { // post was downvoted, after upvoting will be neutral
            currentVoteStatus = 0
            postManager.performInteractionRequest(interaction: 2, docID: self.documentId)
            setNeutralColors()
            setShareButtonNormalColors()
            voteCountLabel.text = String(Int(String(voteCountLabel.text!))! + 1)
            self.delegate?.updateTableViewVotes(self, 1, currentVoteStatus)
        } else { // post was upvoted, after upvoting will be neutral
            currentVoteStatus = 0
            postManager.performInteractionRequest(interaction: 1, docID: self.documentId)
            resetFlagColors()
            setNeutralColors()
            setShareButtonNormalColors()
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
            setShareButtonHighlightedColors()
            self.delegate?.updateTableViewVotes(self, -1, currentVoteStatus)
        } else if self.currentVoteStatus == 1 { // post was upvoted, after downvoting will be neutral
            currentVoteStatus = 0
            postManager.performInteractionRequest(interaction: 1, docID: self.documentId)
            setNeutralColors()
            resetFlagColors()
            setShareButtonNormalColors()
            voteCountLabel.text = String(Int(String(voteCountLabel.text!))! - 1)
            self.delegate?.updateTableViewVotes(self, -1, currentVoteStatus)
        } else { // post was downvoted, after downvoting will be neutral
            currentVoteStatus = 0
            postManager.performInteractionRequest(interaction: 2, docID: self.documentId)
            setNeutralColors()
            setShareButtonNormalColors()
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
        self.delegate?.showSharePopup()
    }
    
    // Segue to view comment screen
    @objc func commentTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        self.delegate?.viewComments(self)
    }
    
    /**
    Modify post colors to reflect a downvote.
    */
    func setDownvotedColors(){
        footer.backgroundColor = Constants.Colors.veryDarkGrey
        upvoteImageButton.tintColor = Constants.Colors.veryDarkGrey
        downvoteImageButton.tintColor = .white
        voteCountLabel.textColor = .white
    }
    
    /**
    Modify post colors to reflect no vote.
    */
    func setNeutralColors(){
        footer.backgroundColor = Constants.Colors.darkGrey
        upvoteImageButton.tintColor = Constants.Colors.lightGrey
        downvoteImageButton.tintColor = Constants.Colors.lightGrey
        voteCountLabel.textColor = .black
    }
    
    /**
    Modify post colors to reflect an upvote.
    */
    func setUpvotedColors(){
        footer.backgroundColor = Constants.Colors.darkPurple
        downvoteImageButton.tintColor = Constants.Colors.darkPurple
        upvoteImageButton.tintColor = .white
        voteCountLabel.textColor = .white
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
        flagButton.tintColor = Constants.Colors.veryDarkGrey
    }
    
    /**
    Modify flag colors on a post to reflect an un-flagged status by the user.
    */
    func setUnflaggedColors(){
        flagButton.tintColor = Constants.Colors.lightGrey
    }
    
    /// Hide the flag button if a user upvotes a post.
    func setFlaggedColorsToPurple(){
        flagButton.tintColor = Constants.Colors.darkPurple
    }
    
    func setShareButtonHighlightedColors(){
        shareButton.tintColor = .white
    }
    
    /// Initialize the share button colors.
    func setShareButtonNormalColors(){
        shareButton.tintColor = Constants.Colors.lightGrey
    }
    
    /// Button to ban users from the ban chamber.
    @IBAction func banButton(_ sender: Any) {
        self.banDelegate?.banPoster(self)
    }
}
