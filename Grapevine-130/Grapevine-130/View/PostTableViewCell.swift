import UIKit
import MaterialComponents.MaterialCards

protocol PostTableViewCellDelegate {
    func updateTableViewVotes(_ cell: UITableViewCell, _ newVote: Int, _ newVoteStatus: Int)
    func updateTableViewFlags(_ cell: UITableViewCell, newFlagStatus: Int)
    func deleteCell( _ cell: UITableViewCell)
    func showAbilitiesView(_ cell: UITableViewCell)
    func showSharePopup(_ cell: UITableViewCell, _ postType: String, _ content: UIImage)
    func viewComments(_ cell: UITableViewCell, _ postScreenshot: UIImage)
    func userTappedAbility(_ cell: UITableViewCell, _ ability: String)
}

protocol BannedPostTableViewCellDelegate {
    func banPoster(_ cell: UITableViewCell)
}

protocol ShoutPostTableViewCellDelegate {
    func shoutPost(_ cell: UITableViewCell)
}

/// Describes a cell in the posts table
class PostTableViewCell: UITableViewCell {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var commentAreaButton: UIView!
    @IBOutlet weak var voteCountLabel: UILabel!
    @IBOutlet weak var downvoteImageButton: UIImageView!
    @IBOutlet weak var upvoteImageButton: UIImageView!
    @IBOutlet weak var footer: UIView!
    @IBOutlet weak var deleteButton: UIImageView!
    @IBOutlet weak var banButtonVar: UIButton!
    @IBOutlet weak var shoutButtonVar: UIButton!
    @IBOutlet weak var imageVar: UIImageView!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var shareButtonVar: UIButton!
    
    // Abilities
    var abilitiesToggleIsActive: Bool = false
    @IBOutlet weak var abilitiesView: UIView!
    @IBOutlet weak var abilitiesBackgroundView: UIView!
    @IBOutlet weak var abilitiesButton: UIImageView!
    @IBOutlet weak var burnButtonView: UIImageView!
    @IBOutlet weak var burnBlockedView: UIImageView!
    @IBOutlet weak var shoutButtonView: UIImageView!
    @IBOutlet weak var pushButtonView: UIImageView!
    @IBOutlet weak var shareButtonView: UIImageView!
    
    /// Specify which abilites may be activated
    var flammable: Bool = false
    var pushable: Bool = true       // we don't use this yet
    var deletable: Bool = false
    
    /// Specify which abilites are active
    var flameActive: Bool = false
    var shoutActive: Bool = false
    var pushActive: Bool = false
    
    let postManager = PostsManager()
    var currentVoteStatus = 0
    var currentFlagStatus = 0
    var currentFlagNum = 0
    var documentId: String = ""
    var postType: String = ""
    var delegate: PostTableViewCellDelegate?
    var banDelegate: BannedPostTableViewCellDelegate?
    var shoutDelegate: ShoutPostTableViewCellDelegate?
    var user: User? // Get user for flammable ability
    
    /**
    Initializes the posts table and adds gestures.
    */
    override func awakeFromNib() {
        super.awakeFromNib() /// builtin function that prepares component for service
        
        // Voting, flag, comment tap gesture setup
        downvoteImageButton.isUserInteractionEnabled = true
        upvoteImageButton.isUserInteractionEnabled = true
        commentButton.isUserInteractionEnabled = true
        commentAreaButton.isUserInteractionEnabled = true
        let tapGestureRecognizerDownvote = UITapGestureRecognizer(target: self, action: #selector(downvoteTapped(tapGestureRecognizer:)))
        let tapGestureRecognizerUpvote = UITapGestureRecognizer(target: self, action: #selector(upvoteTapped(tapGestureRecognizer:)))
        let tapGestureRecognizerFlag = UITapGestureRecognizer(target: self, action: #selector(commentTapped(tapGestureRecognizer:)))
        let tapGestureRecognizerComment = UITapGestureRecognizer(target: self, action: #selector(commentTapped(tapGestureRecognizer:)))
        downvoteImageButton.addGestureRecognizer(tapGestureRecognizerDownvote)
        upvoteImageButton.addGestureRecognizer(tapGestureRecognizerUpvote)
        commentButton.addGestureRecognizer(tapGestureRecognizerFlag)
        commentAreaButton.addGestureRecognizer(tapGestureRecognizerComment)
        
        // Abilities tap gesture setup
        abilitiesButton.isUserInteractionEnabled = true
        burnButtonView.isUserInteractionEnabled = true
        shoutButtonView.isUserInteractionEnabled = true
        pushButtonView.isUserInteractionEnabled = true
        shareButtonView.isUserInteractionEnabled = true
        let tapGestureRecognizerShare = UITapGestureRecognizer(target: self, action: #selector(shareTapped(tapGestureRecognizer:)))
        let tapRecognizerBurnAbility = UITapGestureRecognizer(target: self, action: #selector(burnAbilitySelected(tapGestureRecognizer:)))
        let tapRecognizerShoutAbility = UITapGestureRecognizer(target: self, action: #selector(shoutAbilitySelected(tapGestureRecognizer:)))
        let tapRecognizerPushAbility = UITapGestureRecognizer(target: self, action: #selector(pushAbilitySelected(tapGestureRecognizer:)))
        let tapRecognizerShareAbility = UITapGestureRecognizer(target: self, action: #selector(shareAbilitySelected(tapGestureRecognizer:)))
        abilitiesButton.addGestureRecognizer(tapGestureRecognizerShare)
        burnButtonView.addGestureRecognizer(tapRecognizerBurnAbility)
        shoutButtonView.addGestureRecognizer(tapRecognizerShoutAbility)
        pushButtonView.addGestureRecognizer(tapRecognizerPushAbility)
        shareButtonView.addGestureRecognizer(tapRecognizerShareAbility)
        
        // Add radius to abilities view
        DispatchQueue.main.async {
            let path = UIBezierPath(roundedRect:self.abilitiesBackgroundView.bounds,
                                    byRoundingCorners:[.topLeft, .topRight],
                                    cornerRadii: CGSize(width: 10, height:  10))
            let maskLayer = CAShapeLayer()
            maskLayer.path = path.cgPath
            self.abilitiesBackgroundView.layer.mask = maskLayer
            self.abilitiesBackgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        }
        
    }
    
    /** Update the client view of a post. */
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
    
    /** Enable deletion of a post. */
    func enableDelete(){
        // Set up delete button
        print("Deletable: \(documentId)")
        let tapGestureRecognizer3 = UITapGestureRecognizer(target: self, action: #selector(deleteTapped(tapGestureRecognizer:)))
        deleteButton.isUserInteractionEnabled = true
        deleteButton.addGestureRecognizer(tapGestureRecognizer3)
        deleteButton.isHidden = false
    }
    
    /** Disable deletion of a post. */
    func disableDelete(){
        print("Not deletable: \(documentId)")
        deleteButton.isHidden = true
    }
    //show and enable abilities button
    func enableAbilities() {
        abilitiesButton.isUserInteractionEnabled = true
        abilitiesButton.isHidden = false
    }
    
    //hide and disable abilities button
    func disableAbilities() {
        abilitiesButton.isUserInteractionEnabled = false
        abilitiesButton.isHidden = true
    }
    
    //Sets the location of the share button to where the abilities button normally is for when the user is looking at their own post
    func moveShareButton(){
        shareButtonVar.trailingAnchor.constraint(equalTo: shareButtonVar.superview!.trailingAnchor, constant: -8).isActive = true
    }
    func revertShareButton(){
        shareButtonVar.trailingAnchor.constraint(equalTo: shareButtonVar.superview!.trailingAnchor, constant: -44).isActive = true
    }
    
    
    func enableInteraction() {
        DispatchQueue.main.async {
            self.upvoteImageButton.isUserInteractionEnabled = true
            self.downvoteImageButton.isUserInteractionEnabled = true
            self.upvoteImageButton.image = UIImage(systemName: "arrowtriangle.up.circle.fill")
            self.downvoteImageButton.image = UIImage(systemName: "arrowtriangle.down.circle.fill")
        }
    }
    
    func disableInteraction() {
        DispatchQueue.main.async {
            self.setUpvotedColors()
            self.upvoteImageButton.isHidden = true
            self.downvoteImageButton.isHidden = true
            self.upvoteImageButton.isUserInteractionEnabled = false
            self.downvoteImageButton.isUserInteractionEnabled = false
            self.upvoteImageButton.image = UIImage(systemName: "circle.fill")
            self.downvoteImageButton.image = UIImage(systemName: "circle.fill")
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
    @objc func upvoteTapped(tapGestureRecognizer: UITapGestureRecognizer){
        if self.currentVoteStatus == 0 { /// post was not voted on (neutral), after upvoting will be upvoted
            currentVoteStatus = 1
            postManager.performInteractionRequest(interaction: 1, docID: self.documentId)
            setUpvotedColors()
            voteCountLabel.text = String(Int(String(voteCountLabel.text!))! + 1)
            self.delegate?.updateTableViewVotes(self, 1, currentVoteStatus)
        } else if self.currentVoteStatus == -1 { /// post was downvoted, after upvoting will be neutral
            currentVoteStatus = 0
            postManager.performInteractionRequest(interaction: 2, docID: self.documentId)
            setNeutralColors()
            voteCountLabel.text = String(Int(String(voteCountLabel.text!))! + 1)
            self.delegate?.updateTableViewVotes(self, 1, currentVoteStatus)
        } else { /// post was upvoted, after upvoting will be neutral
            currentVoteStatus = 0
            postManager.performInteractionRequest(interaction: 1, docID: self.documentId)
            setNeutralColors()
            voteCountLabel.text = String(Int(String(voteCountLabel.text!))! - 1)
            self.delegate?.updateTableViewVotes(self, -1, currentVoteStatus)
        }
    }

    /** Update vote information when user downvotes a `post`.
    - Parameter tapGestureRecognizer: Gesture performed by the user */
    @objc func downvoteTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        if self.currentVoteStatus == 0 { /// post was not voted on (neutral), after downvoting will be downvoted
            currentVoteStatus = -1
            postManager.performInteractionRequest(interaction: 2, docID: self.documentId)
            setDownvotedColors()
            voteCountLabel.text = String(Int(String(voteCountLabel.text!))! - 1)
            self.delegate?.updateTableViewVotes(self, -1, currentVoteStatus)
        } else if self.currentVoteStatus == 1 { /// post was upvoted, after downvoting will be neutral
            currentVoteStatus = 0
            postManager.performInteractionRequest(interaction: 1, docID: self.documentId)
            setNeutralColors()
            voteCountLabel.text = String(Int(String(voteCountLabel.text!))! - 1)
            self.delegate?.updateTableViewVotes(self, -1, currentVoteStatus)
        } else { /// post was downvoted, after downvoting will be neutral
            currentVoteStatus = 0
            postManager.performInteractionRequest(interaction: 2, docID: self.documentId)
            setNeutralColors()
            voteCountLabel.text = String(Int(String(voteCountLabel.text!))! + 1)
            self.delegate?.updateTableViewVotes(self, 1, currentVoteStatus)
        }
    }
    
    /** Deletes a `post`.
     - Parameter tapGestureRecognizer: Gesture performed by the user */
    @objc func deleteTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        deleteButton.tintColor = Constants.Colors.darkPurple
        self.delegate?.deleteCell(self)
    }
    
    /** Flags a `post`.
    - Parameter tapGestureRecognizer: Gesture performed by the user */
    @objc func flagTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        /// wasn't flagged, now is flagged
        if self.currentFlagStatus == 0 {
            self.currentFlagStatus = 1
            resetFlagColors()
            self.delegate?.updateTableViewFlags(self, newFlagStatus: 1)
        /// was flagged, now isn't flagged
        } else {
            self.currentFlagStatus = 0
            resetFlagColors()
            self.delegate?.updateTableViewFlags(self, newFlagStatus: 0)
        }
        
        postManager.performInteractionRequest(interaction: 4, docID: self.documentId)
    }
    
    func toggleAbilities(){
        if (abilitiesToggleIsActive){
            /// Show the comment tappable area
            commentAreaButton.isHidden = false
            commentAreaButton.isUserInteractionEnabled = true
            abilitiesView.isHidden = true
            abilitiesBackgroundView.isHidden = true
            abilitiesToggleIsActive = false
            print(abilitiesToggleIsActive)
        } else {
            /// Hide the comment tappable area
            commentAreaButton.isHidden = true
            commentAreaButton.isUserInteractionEnabled = false
            abilitiesView.isHidden = false
            abilitiesBackgroundView.isHidden = false
            abilitiesToggleIsActive = true
            print(abilitiesToggleIsActive)
        }
    }
    
    @objc func shareTapped(tapGestureRecognizer: UITapGestureRecognizer){
        self.delegate?.showAbilitiesView(self)
    }
    
    @IBAction func shareButtonPressed(_ sender: Any) {
        if postType == "text" {
            self.delegate?.showSharePopup(self, "text", createTableCellImage() ?? nil!)
        } else {
            self.delegate?.showSharePopup(self, "image", createTableCellImage() ?? nil!)
        }
    }
    
    /// Segue to view comment screen
    @objc func commentTapped(tapGestureRecognizer: UITapGestureRecognizer){
        self.delegate?.viewComments(self, (createTableCellImage() ?? nil)!)
    }

    /** Modify post colors to reflect a downvote. */
    func setDownvotedColors(){
        var footerColor = Constants.Colors.veryDarkGrey
        var buttonColor: UIColor = .systemBackground
        if self.shoutActive {
            footerColor = Constants.Colors.yellow
            buttonColor = .systemBackground
        }
        commentButton.tintColor = buttonColor
        downvoteImageButton.isHidden = false
        upvoteImageButton.isHidden = true
        abilitiesButton.tintColor = buttonColor
        footer.backgroundColor = footerColor
        downvoteImageButton.tintColor = buttonColor
        voteCountLabel.textColor = buttonColor
        shareButtonVar.tintColor = buttonColor
        commentButton.setTitleColor(footerColor, for: .normal)
    }
    
    /** Modify post colors to reflect no vote.  */
    func setNeutralColors(){
        var buttonColor = UIColor.systemGray3
        var footerColor = UIColor.systemGray5
        var textColor = UIColor.label
        if self.shoutActive {
            buttonColor = .systemBackground
            footerColor = Constants.Colors.yellow
            if let curTheme = UserDefaults.standard.string(forKey: Globals.userDefaults.themeKey){
                if (curTheme == "dark") { textColor = .black }
                else { textColor = .white }
            }
        }
        downvoteImageButton.isHidden = false
        upvoteImageButton.isHidden = false
        decideFlagColors()
        footer.backgroundColor = footerColor
        commentButton.tintColor = buttonColor
        upvoteImageButton.tintColor = buttonColor
        downvoteImageButton.tintColor = buttonColor
        abilitiesButton.tintColor = buttonColor
        shareButtonVar.tintColor = buttonColor
        voteCountLabel.textColor = textColor
        commentButton.setTitleColor(footerColor, for: .normal)
    }
    
    /** Modify post colors to reflect an upvote. */
    func setUpvotedColors(){
        var buttonColor: UIColor = .systemBackground
        var footerColor = Constants.Colors.darkPurple
        if self.shoutActive {
            footerColor = Constants.Colors.yellow
            footerColor = Constants.Colors.yellow
            buttonColor = .systemBackground
        }
        commentButton.tintColor = buttonColor
        downvoteImageButton.isHidden = true
        upvoteImageButton.isHidden = false
        abilitiesButton.tintColor = buttonColor
        footer.backgroundColor = footerColor
        upvoteImageButton.tintColor = buttonColor
        voteCountLabel.textColor = buttonColor
        shareButtonVar.tintColor = buttonColor
        commentButton.setTitleColor(footerColor, for: .normal)
    }
    
    /** Modify flag colors on a post. */
    func resetFlagColors(){
        if self.currentFlagStatus == 0 {
            setUnflaggedColors()
        } else {
            setFlaggedColors()
        }
    }
    
    /** Modify flag colors on a post to reflect a flagged status by the user. */
    func setFlaggedColors(){
        commentButton.tintColor = UIColor.systemGray2
    }
    
    /** Modify flag colors on a post to reflect an un-flagged status by the user. */
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
    
    /** Changes the comment count number into a readable abbreviated string. Large numbers are abbreviated to the nearest hundredth.
    - Parameter numComments: Number of comments under the post
    - Returns: Abbreviated string representation of the comment count */
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
        /// Reset cell attributes before reusing
        self.imageVar.image = nil
        self.deleteButton.tintColor = UIColor.systemGray5
        self.label.font = self.label.font.withSize(16)
        self.commentAreaButton.backgroundColor = UIColor.systemGray6
        self.label.textColor = UIColor.label
        
        /// Set main body of post cell
        if (post.type == "text"){
            self.label.text = post.content
            self.postType = "text"
        } else {
            if let decodedData = Data(base64Encoded: post.content, options: .ignoreUnknownCharacters) {
                let imageData = UIImage(data: decodedData)!
                self.label.text = ""
                self.postType = "image"
                self.imageVar.image = resizeImage(image: imageData, newWidth: self.imageVar.bounds.width)
            }
        }
        
        /// Set the document id of the post
        self.documentId = post.postId
        
        /// Set vote count of post cell
        self.voteCountLabel.text = String(post.votes)
        
        /// Set vote status
        self.currentVoteStatus = post.voteStatus
        
        /// Set the comment count number
        if post.comments > 0 {
            /// Show number of comments if there are comments
            let commentText = self.getCommentCount(numComments: post.comments)
            self.commentButton.setTitle(commentText, for: .normal)
            self.commentButton.setBackgroundImage(UIImage(systemName: "circle.fill"), for: .normal)
        } else {
            /// Show comment symbol if there are no comments
            self.commentButton.setTitle("", for: .normal)
            self.commentButton.setBackgroundImage(UIImage(systemName: "message.circle.fill"), for: .normal)
        }
        
        /// Cell is flammable
        if (post.votes < -3 && post.poster != self.user!.user){
            print("Post is flammable/bannable")
            burnBlockedView.isUserInteractionEnabled = false
            burnBlockedView.isHidden = true
        } else {
            print("Post is not flammable/bannable")
            burnBlockedView.isUserInteractionEnabled = true
            burnBlockedView.isHidden = false
        }
    }
    
    // Abilities
    /// TO-DO: simplify these into one function with a case statement
    @objc func burnAbilitySelected(tapGestureRecognizer: UITapGestureRecognizer){
        toggleAbilities()
        self.delegate?.userTappedAbility(self, "burn")
    }
    @objc func shoutAbilitySelected(tapGestureRecognizer: UITapGestureRecognizer){
        toggleAbilities()
        self.delegate?.userTappedAbility(self, "shout")
    }
    @objc func pushAbilitySelected(tapGestureRecognizer: UITapGestureRecognizer){
        toggleAbilities()
        self.delegate?.userTappedAbility(self, "push")
    }
    @objc func shareAbilitySelected(tapGestureRecognizer: UITapGestureRecognizer){
        toggleAbilities()
        if postType == "text" {
            self.delegate?.showAbilitiesView(self)
        } else {
            self.delegate?.showAbilitiesView(self)
        }
    }
}
