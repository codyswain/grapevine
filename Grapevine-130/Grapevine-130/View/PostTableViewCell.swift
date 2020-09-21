import UIKit
import MaterialComponents.MaterialCards

protocol PostTableViewCellDelegate {
    func updateTableViewVotes(_ cell: UITableViewCell, _ newVote: Int, _ newVoteStatus: Int)
    func updateTableViewFlags(_ cell: UITableViewCell, newFlagStatus: Int)
    func deleteCell( _ cell: UITableViewCell)
    func showAbilitiesView(_ cell: PostTableViewCell)
    func showSharePopup(_ cell: PostTableViewCell, _ postType: String, _ content: UIImage)
    func viewComments(_ cell: PostTableViewCell, _ postScreenshot: UIImage, cellHeight: CGFloat)
    func userTappedAbility(_ cell: UITableViewCell, _ ability: String)
    func expandCell(_ cell: PostTableViewCell, cellHeight: CGFloat)
    func moreOptionsTapped(_ cell: PostTableViewCell, alert: UIAlertController)
}

protocol BannedPostTableViewCellDelegate {
    func banPoster(_ cell: UITableViewCell)
}

protocol ShoutPostTableViewCellDelegate {
    func shoutPost(_ cell: UITableViewCell)
}

/// Describes a cell in the posts table
class PostTableViewCell: UITableViewCell {
    @IBOutlet weak var BoundingView: UIView!
    @IBOutlet weak var ContentView: UIView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var expandButton: UIButton!
    @IBOutlet weak var commentAreaView: UIView!
    @IBOutlet weak var voteCountLabel: UILabel!
    @IBOutlet weak var downvoteButton: UIButton!
    @IBOutlet weak var upvoteButton: UIButton!
    @IBOutlet weak var moreOptionsButton: UIButton!
    @IBOutlet weak var imageVar: UIImageView!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var shareButtonVar: UIButton!
    @IBOutlet weak var timeStampLabel: UILabel!
    @IBOutlet weak var VotesContainerView: UIView!
    @IBOutlet weak var ExpandLabel: UILabel!
    
    // Abilities
    var abilitiesToggleIsActive: Bool = false
    @IBOutlet weak var abilitiesView: UIView!
    @IBOutlet weak var abilitiesBackgroundView: UIView!
    @IBOutlet weak var burnButtonView: UIImageView!
    @IBOutlet weak var abilitiesButton: UIButton!
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
    var postDate: Date?
    
    ///Post Expansion
    var isExpanded: Bool = false
    
    ///Deleteable
    var isDeleteable = false
    
    ///Gradient layer
    var gradient: CAGradientLayer?
    
    /// post expansion
    let maxLines = 3
    /**
    Initializes the posts table and adds gestures.
    */
    override func awakeFromNib() {
        super.awakeFromNib() /// builtin function that prepares component for service
        
        //comment tap gesture setup
        let tapGestureRecognizerComment = UITapGestureRecognizer(target: self, action: #selector(commentTapped(tapGestureRecognizer:)))
        commentAreaView.addGestureRecognizer(tapGestureRecognizerComment)
        
        downvoteButton.isUserInteractionEnabled = true
        upvoteButton.isUserInteractionEnabled = true
        commentButton.isUserInteractionEnabled = true
        commentAreaView.isUserInteractionEnabled = true
        
        // Abilities tap gesture setup
        
        abilitiesButton.isUserInteractionEnabled = true
        shareButtonView.isUserInteractionEnabled = true
        
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
    
    // show how long ago a post was created
    func setTimeSincePost() {
        if let date = self.postDate {
            let elapsedTime = date.getElapsedInterval()
            print("Time ago :", elapsedTime)
            self.timeStampLabel.text = elapsedTime
        }
    }
    
    func enableInteraction() {
        self.upvoteButton.isHidden = false
        self.downvoteButton.isHidden = false
        self.upvoteButton.isUserInteractionEnabled = true
        self.downvoteButton.isUserInteractionEnabled = true
    }
    
    func disableInteraction() {
        self.upvoteButton.isHidden = true
        self.downvoteButton.isHidden = true
        self.upvoteButton.isUserInteractionEnabled = false
        self.downvoteButton.isUserInteractionEnabled = false
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
    @IBAction func upvoteTapped(_ sender: Any) {
        if self.currentVoteStatus == 0 { /// post was not voted on (neutral), after upvoting will be upvoted
            currentVoteStatus = 1
            postManager.performInteractionRequest(interaction: 1, docID: self.documentId, groupID: Globals.ViewSettings.groupID)
            self.delegate?.updateTableViewVotes(self, 1, currentVoteStatus)
            
            //Animate Upvote (expand)
            //let transform = CATransform3DIdentity
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut,
                animations: {
                    self.upvoteButton.transform = CGAffineTransform(scaleX: 2, y: 2)
                    self.setUpvotedColors()
                    self.voteCountLabel.text = String(Int(String(self.voteCountLabel.text!))! + 1)
                },
                completion: { _ in
                    UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn, animations: {
                        self.upvoteButton.transform = CGAffineTransform.identity
                    }, completion: nil)
//                    completion: {_ in
//                        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {
//                            self.upvoteButton.layer.transform = CATransform3DRotate(transform, CGFloat(180 * Double.pi / 180), 0, 1, 0)
//                        })
//                    })
                })
            }
            
        } else if self.currentVoteStatus == -1 { /// post was downvoted, after upvoting will be neutral
            currentVoteStatus = 0
            postManager.performInteractionRequest(interaction: 2, docID: self.documentId, groupID: Globals.ViewSettings.groupID)
            setNeutralColors()
            voteCountLabel.text = String(Int(String(voteCountLabel.text!))! + 1)
            self.delegate?.updateTableViewVotes(self, 1, currentVoteStatus)
        } else { /// post was upvoted, after upvoting will be neutral
            currentVoteStatus = 0
            postManager.performInteractionRequest(interaction: 1, docID: self.documentId, groupID: Globals.ViewSettings.groupID)
            self.delegate?.updateTableViewVotes(self, -1, currentVoteStatus)
            
            //Animate Upvote (Shrink)
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut,
                animations: {
                    self.upvoteButton.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                    self.setNeutralColors()
                    self.voteCountLabel.text = String(Int(String(self.voteCountLabel.text!))! - 1)
                },
                completion: { _ in
                    UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn, animations: {
                        self.upvoteButton.transform = CGAffineTransform.identity
                    })
                })
            }
        }
    }

    /** Update vote information when user downvotes a `post`.
    - Parameter tapGestureRecognizer: Gesture performed by the user */
    @IBAction func downvoteTapped(_ sender: Any) {
        if self.currentVoteStatus == 0 { /// post was not voted on (neutral), after downvoting will be downvoted
            currentVoteStatus = -1
            postManager.performInteractionRequest(interaction: 2, docID: self.documentId, groupID: Globals.ViewSettings.groupID)
            self.delegate?.updateTableViewVotes(self, -1, currentVoteStatus)
            
            //Animate Downvote (fly down from top)
            DispatchQueue.main.async {
//                UIView.animate(withDuration: 0.0, delay: 0.0, options: [],
//                animations: {
//                    self.downvoteButton.transform = CGAffineTransform(translationX: 0, y: -50)
//                    self.downvoteButton.alpha = 0
//                },
//                completion: { _ in
//                    UIView.animate(withDuration: 0.5, delay: 0.0, options: [],
//                    animations: {
//                        self.upvoteButton.transform = CGAffineTransform(rotationAngle: .pi)
//                        self.upvoteButton.alpha = 0
//                        self.downvoteButton.alpha = 1
//                    },
//                    completion: { _ in
//                        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseIn, animations: {
//                            self.voteCountLabel.text = String(Int(String(self.voteCountLabel.text!))! - 1)
//                            self.setDownvotedColors()
//                            self.downvoteButton.transform = CGAffineTransform.identity
//                            self.upvoteButton.transform = CGAffineTransform.identity
//                            self.upvoteButton.alpha = 1
//                        })
//                    })
//                })
                UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut, animations: {
                    self.downvoteButton.transform = CGAffineTransform(scaleX: 2, y: 2)
                    self.voteCountLabel.text = String(Int(String(self.voteCountLabel.text!))! - 1)
                    self.setDownvotedColors()
                }, completion: { _ in
                    UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseIn, animations: {
                        self.downvoteButton.transform = CGAffineTransform.identity
                    }, completion: nil)
                })
            }
            
        } else if self.currentVoteStatus == 1 { /// post was upvoted, after downvoting will be neutral
            currentVoteStatus = 0
            postManager.performInteractionRequest(interaction: 1, docID: self.documentId, groupID: Globals.ViewSettings.groupID)
            setNeutralColors()
            voteCountLabel.text = String(Int(String(voteCountLabel.text!))! - 1)
            self.delegate?.updateTableViewVotes(self, -1, currentVoteStatus)
        } else { /// post was downvoted, after downvoting will be neutral
            currentVoteStatus = 0
            postManager.performInteractionRequest(interaction: 2, docID: self.documentId, groupID: Globals.ViewSettings.groupID)
            self.delegate?.updateTableViewVotes(self, 1, currentVoteStatus)
            
            //Animate Downvote (Shrink)
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut,
                animations: {
                    self.downvoteButton.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                    self.setNeutralColors()
                    self.voteCountLabel.text = String(Int(String(self.voteCountLabel.text!))! + 1)                },
                completion: { _ in
                    UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn, animations: {
                        self.downvoteButton.transform = CGAffineTransform.identity
                    })
                })
            }
        }
    }
    
    @IBAction func moreOptionsTapped(_ sender: Any) {
        moreOptionsButton.tintColor = UIColor(named: "GrapevinePurple")
        moreOptionsButton.setTitleColor(UIColor(named: "GrapevinePurple"), for: .normal)
        DispatchQueue.main.async{
            UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseOut, animations: {
                self.moreOptionsButton.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            }, completion: nil)
        }
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        var flagTitle = "Flag Post"
        if currentFlagStatus == 1 {
            flagTitle = "Unflag Post"
        }
        let action1 = UIAlertAction(title: flagTitle, style: .destructive) { (action) in self.flagTappedInMoreOptions()
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseIn, animations: {
                    self.moreOptionsButton.transform = .identity
                    self.moreOptionsButton.tintColor = .systemGray2
                    self.moreOptionsButton.setTitleColor(.systemGray2, for: .normal)
                }, completion: nil)
            }
        }
        let action2 = UIAlertAction(title: "Delete Post", style:.destructive) { (action) in self.delegate?.deleteCell(self)
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseIn, animations: {
                    self.moreOptionsButton.transform = .identity
                    self.moreOptionsButton.tintColor = .systemGray2
                    self.moreOptionsButton.setTitleColor(.systemGray2, for: .normal)
                }, completion: nil)
            }
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { (action) in 
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseIn, animations: {
                    self.moreOptionsButton.transform = .identity
                    self.moreOptionsButton.tintColor = .systemGray2
                    self.moreOptionsButton.setTitleColor(.systemGray2, for: .normal)
                }, completion: nil)
            }
        })
        alert.addAction(action1)
        if isDeleteable == true {
            alert.addAction(action2)
        }
        self.delegate?.moreOptionsTapped(self, alert: alert)
    }
        
    func flagTappedInMoreOptions() {
        /// wasn't flagged, now is flagged
        if self.currentFlagStatus == 0 {
            self.currentFlagStatus = 1
            self.delegate?.updateTableViewFlags(self, newFlagStatus: 1)
        /// was flagged, now isn't flagged
        } else {
            self.currentFlagStatus = 0
            self.delegate?.updateTableViewFlags(self, newFlagStatus: 0)
        }
        
        postManager.performInteractionRequest(interaction: 4, docID: self.documentId, groupID: Globals.ViewSettings.groupID)
    }
    
    func toggleAbilities(){
        if (abilitiesToggleIsActive){
            abilitiesView.isHidden = true
            abilitiesBackgroundView.isHidden = true
            abilitiesToggleIsActive = false
        } else {
            abilitiesView.isHidden = false
            abilitiesBackgroundView.isHidden = false
            abilitiesToggleIsActive = true
            print(abilitiesToggleIsActive)
        }
    }
    
    @IBAction func shareButtonPressed(_ sender: Any) {
        let cellImage = createTableCellImage()! //Dont want purple share button in screenshot
        shareButtonVar.tintColor = UIColor(named: "GrapevinePurple")
        shareButtonVar.setTitleColor(UIColor(named: "GrapevinePurple"), for: .normal)
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseOut, animations: {
                self.shareButtonVar.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            }, completion: nil)
        }
        if postType == "text" {
            self.delegate?.showSharePopup(self, "text", cellImage)
        } else {
            self.delegate?.showSharePopup(self, "image", cellImage)
        }
    }
    
    
    @IBAction func commentButtonTapped(_ sender: Any) {
        self.commentButton.tintColor = UIColor(named: "GrapevinePurple")
        self.commentButton.setTitleColor(UIColor(named: "GrapevinePurple"), for: .normal)
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseOut, animations: {
                self.commentButton.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            }, completion: {_ in
                UIView.animate(withDuration: 0.1, animations: {
                    self.commentButton.transform = .identity
                    self.commentButton.tintColor = .systemGray2
                    self.commentButton.setTitleColor(.systemGray2, for: .normal)
                }, completion: nil)
            })
        }
        self.viewCommentScreen()
    }
    /// Segue to view comment screen
    @objc func commentTapped(tapGestureRecognizer: UITapGestureRecognizer){
        commentButtonTapped(self)
    }
    
    func viewCommentScreen(){
        let cellHeight = self.label.totalNumberOfLines() * Int(ceil(self.label.font.lineHeight)) + 86
        self.delegate?.viewComments(self, (createTableCellImage() ?? nil)!, cellHeight: CGFloat(cellHeight))
    }
    
    /** Modify post colors to reflect a downvote. */
    func setDownvotedColors(){
        downvoteButton.isHidden = false
        downvoteButton.isUserInteractionEnabled = true
        upvoteButton.isHidden = true
        upvoteButton.isUserInteractionEnabled = false
        downvoteButton.tintColor = Constants.Colors.veryDarkGrey
        voteCountLabel.textColor = Constants.Colors.veryDarkGrey
    }
    
    /** Modify post colors to reflect no vote.  */
    func setNeutralColors(){
        downvoteButton.isHidden = false
        upvoteButton.isHidden = false
        downvoteButton.isUserInteractionEnabled = true
        upvoteButton.isUserInteractionEnabled = true
        upvoteButton.tintColor = .systemGray3
        downvoteButton.tintColor = .systemGray3
        voteCountLabel.textColor = .systemGray2
    }
    
    /** Modify post colors to reflect an upvote. */
    func setUpvotedColors(){
        downvoteButton.isHidden = true
        downvoteButton.isUserInteractionEnabled = false
        upvoteButton.isHidden = false
        upvoteButton.isUserInteractionEnabled = true
        upvoteButton.tintColor = Constants.Colors.darkPurple
        voteCountLabel.textColor = Constants.Colors.darkPurple
    }
    
    func createTableCellImage() -> UIImage? {
        var im:UIImage?
        if deletable {
            self.moreOptionsButton.isHidden = true
            self.upvoteButton.isHidden = false
            self.downvoteButton.isHidden = false
        }
        UIGraphicsBeginImageContextWithOptions(self.BoundingView.frame.size, false, 0.0)
        if let currentContext = UIGraphicsGetCurrentContext() {
            self.layer.render(in: currentContext)
            im = UIGraphicsGetImageFromCurrentImageContext()
        }
        if deletable {
            self.moreOptionsButton.isHidden = false
            self.upvoteButton.isHidden = true
            self.upvoteButton.isHidden = true
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
        //This keeps button colors from changing to gray when an alert is peresnted
        self.moreOptionsButton.tintAdjustmentMode = .normal
        self.shareButtonVar.tintAdjustmentMode = .normal
        self.abilitiesButton.tintAdjustmentMode = .normal
        self.commentButton.tintAdjustmentMode = .normal
        self.upvoteButton.tintAdjustmentMode = .normal
        self.downvoteButton.tintAdjustmentMode = .normal
        
        self.BoundingView.layer.borderWidth = 0
        self.BoundingView.layer.borderColor = nil
        self.expandButton.tintColor = UIColor(named: "GrapevinePurple")
        self.imageVar.image = nil
        self.moreOptionsButton.tintColor = UIColor.systemGray2
        self.label.font = self.label.font.withSize(16)
        if let curTheme = UserDefaults.standard.string(forKey: Globals.userDefaults.themeKey){
            if (curTheme == "dark") {
                self.commentAreaView.backgroundColor = .systemGray6
                self.ContentView.backgroundColor = .black
            }
            else {
                self.commentAreaView.backgroundColor = .systemBackground
                self.ContentView.backgroundColor = .systemGray6

            }
        }
        self.label.textColor = UIColor.label
        commentButton.isUserInteractionEnabled = true
        
        /// Set main body of post cell
        if (post.type == "text"){
            self.postType = "text"
            self.label.text = post.content
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
        
        /// Set the date of the post
        self.postDate = Date(timeIntervalSince1970: post.date)
        
        /// Set vote count of post cell
        self.voteCountLabel.text = String(post.votes)
//        self.voteCountLabel.textColor = .label
        
        /// Set vote status
        self.currentVoteStatus = post.voteStatus
        
        /// Set the comment count number
        if post.comments > 0 {
            /// Show number of comments if there are comments
            let commentText = self.getCommentCount(numComments: post.comments)
            self.commentButton.setTitle(" " + commentText + " Replies", for: .normal)
            self.commentButton.setImage(UIImage(systemName: "message"), for: .normal)
        } else {
            /// Show comment symbol if there are no comments
            self.commentButton.setTitle(" 0 Replies", for: .normal)
            self.commentButton.setImage(UIImage(systemName: "message"), for: .normal)
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
        
        // Collapse Cell
        label.numberOfLines = maxLines
        commentAreaView.clipsToBounds = true
        ExpandLabel.text = "Tap and hold to expand"

        if self.label.totalNumberOfLines() > maxLines {
            expandButton.isUserInteractionEnabled = true
            ExpandLabel.isHidden = false
            expandButton.isHidden = true
            label.lineBreakMode = .byTruncatingTail
            self.shrinkCell()
        }
        else {
            ExpandLabel.isHidden = true
            expandButton.isUserInteractionEnabled = false
            expandButton.isHidden = true
            label.lineBreakMode = .byWordWrapping
        }
        gradient?.removeFromSuperlayer()
        shoutActive = false
        enableInteraction()
    }
    
    func expandCell() {
        self.isExpanded = true
        self.label.numberOfLines = -1 //infinity
        self.label.lineBreakMode = .byWordWrapping
        self.expandButton.setImage(UIImage(systemName: "chevron.compact.up"), for: .normal)
        layoutSubviews()
    }
    
    func shrinkCell() {
        self.isExpanded = false
        self.label.lineBreakMode = .byTruncatingTail
        self.label.numberOfLines = self.maxLines
        self.expandButton.setImage(UIImage(systemName: "chevron.compact.down"), for: .normal)
        layoutSubviews()
    }
    
    //Expand cell button. Expands or contracts cell if pressed when content too large
    @IBAction func expandButtonPressed(_ sender: Any) {
        if self.isExpanded == false {
            //UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut, animations: {
                self.delegate?.expandCell(self, cellHeight: CGFloat(self.label.totalNumberOfLines()) * self.label.font.lineHeight + 96)
                self.expandButton.tintColor = .systemGray3
            //}, completion: nil )
            
        } else {
            //UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut, animations: {
                self.delegate?.expandCell(self, cellHeight: CGFloat(self.maxLines) * self.label.font.lineHeight + 96)
                self.expandButton.tintColor = .systemGray3
            //}, completion: nil)
        }
    }
    
    /// This is abilities button
    @IBAction func shareAbilitySelected(_ sender: Any) {
        self.abilitiesButton.tintColor = UIColor(named: "GrapevinePurple")
        self.abilitiesButton.setTitleColor(UIColor(named: "GrapevinePurple"), for: .normal)
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseOut, animations: {
                self.abilitiesButton.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            }, completion: {_ in
                UIView.animate(withDuration: 0.1, animations: {
                    self.abilitiesButton.transform = .identity
                    self.abilitiesButton.tintColor = .systemGray2
                    self.abilitiesButton.setTitleColor(.systemGray2, for: .normal)
                }, completion: nil)
            })
        }
        toggleAbilities()
        if postType == "text" {
            self.delegate?.showAbilitiesView(self)
        } else {
            self.delegate?.showAbilitiesView(self)
        }
    }
}

//MARK: Utility Extensions

extension UILabel {
    func totalNumberOfLines() -> Int {
        let maxSize = CGSize(width: frame.size.width, height: CGFloat(Float.infinity))
        let charSize = font.lineHeight
        let text = (self.text ?? "") as NSString
        let textSize = text.boundingRect(with: maxSize, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font as Any], context: nil)
        let linesRoundedUp = Int(ceil(textSize.height/charSize))
        return linesRoundedUp
    }
}

extension Date {
    
    func getElapsedInterval() -> String {
        
        let interval = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self, to: Date())
        
        if let year = interval.year, year > 0 {
            return year == 1 ? "\(year)" + " " + "year" :
                "\(year)" + " " + "years"
        } else if let month = interval.month, month > 0 {
            return month == 1 ? "\(month)" + " " + "month" :
                "\(month)" + " " + "months"
        } else if let day = interval.day, day > 0 {
            return day == 1 ? "\(day)" + " " + "day" :
                "\(day)" + " " + "days"
        } else if let hour = interval.hour, hour > 0 {
            return hour == 1 ? "\(hour)" + " " + "hour" :
                "\(hour)" + " " + "hours"
        } else if let minute = interval.minute, minute > 0 {
            return minute == 1 ? "\(minute)" + " " + "minute" :
                "\(minute)" + " " + "minutes"
        } else if let second = interval.second, second > 0 {
            return second == 1 ? "\(second)" + " " + "second" :
                "\(second)" + " " + "seconds"
        } else {
            return "a moment ago"
        }
    }
}
