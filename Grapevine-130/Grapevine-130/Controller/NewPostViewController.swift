import Foundation
import UIKit
import CoreLocation
import MaterialComponents.MaterialDialogs

protocol NewPostViewControllerDelegate {
    func postCreated()
}

/// Manages the control flow for making a new post.
class NewPostViewController: UIViewController {
    var currentState = "text"

    @IBOutlet weak var frontTextView: UITextView! // actual user input text
    @IBOutlet weak var backTextView: UITextView! // placeholder text
    @IBOutlet weak var newPostTextBackground: UIButton! // text
    @IBOutlet weak var drawingCanvasView: CanvasView! // drawing
    let locationManager = CLLocationManager()
    var lat:CLLocationDegrees = 0.0
    var lon:CLLocationDegrees = 0.0
    var postsManager = PostsManager()
    var groupsManager = GroupsManager()
    var groupName = "Grapevine"
    var groupID = ""
    var delegate: NewPostViewControllerDelegate?
    var newPostCreationAttempt: Bool = false //Check if there is a new post. Used to avoid creating a post when just updating location.
    var textFieldBody: String? //Store text entered by user when checking toxicity score
    var spinnerView: UIView?

    @IBOutlet weak var ColorButtonVar: UIButton!
    @IBOutlet weak var createTextButtonVar: UIButton!
    @IBOutlet weak var createDrawingButtonVar: UIButton!
    @IBOutlet weak var clearButtonVar: UIButton!
    @IBOutlet weak var AddButtonContainingViewConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var AddButtonContainingView: UIView!
    @IBOutlet var newPostView: UIView!
    
    @IBOutlet weak var GlobalSlider: UISegmentedControl!
    @IBOutlet weak var GlobalSliderContainingView: UIView!
    @IBOutlet weak var GlobalSliderTopToTextviewConstraint: NSLayoutConstraint!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return setStatusBarStyle()
    }
    
    var visibility = "Local"
    
    /**
     Intializes the new post screen.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set placeholder text for groups posts
        if Globals.ViewSettings.groupName == "Grapevine" {
            backTextView.text = "What's actually on your mind?"
        } else {
            backTextView.text = "Post to \(Globals.ViewSettings.groupName)"
        }
        
        if UIDevice.current.deviceType == .iPhones_5_5s_5c_SE {
            let font = UIFont.systemFont(ofSize: 10, weight: .medium)
        GlobalSlider.setTitleTextAttributes([NSAttributedString.Key.font: font], for: .normal)
        }
        
        // Set dark/light mode from persistent storage
        setTheme(curView: self)
        
        postsManager.delegate = self
        locationManager.delegate = self

        newPostTextBackground.layer.cornerRadius = 10.0
        newPostTextBackground.backgroundColor = UIColor.systemGray6
        backTextView.textColor = UIColor.lightGray
        drawingCanvasView.layer.cornerRadius = 10.0
        drawingCanvasView.backgroundColor = UIColor.systemGray6
        frontTextView.delegate = self
        frontTextView.isHidden = false
        
        // Custom "Add" post button within view
        AddButtonContainingView.layer.cornerRadius = 10
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.addPostButton))
        AddButtonContainingView.addGestureRecognizer(tapGesture)
        AddButtonContainingView.isUserInteractionEnabled = true
                
        // Add listeners to keyboard to reposition "Add Post" button
        NotificationCenter.default.addObserver(self, selector: #selector(NewPostViewController.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(NewPostViewController.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // Close keyboard when tapping anywhere
        let tap = UITapGestureRecognizer(target: self.view,
                                         action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tap)
        
        frontTextView.autocorrectionType = .yes
        frontTextView.addDoneButton(title: "Done", target: self, selector: #selector(tapDone(sender:)))
    }
    
    // Add a "Done" button to close the keyboard
    @objc func tapDone(sender: Any) {
        self.view.endEditing(true)
    }

    // Close the keyboard when you touch anywhere outside the keyboard
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }
    /**
     Switches to the screen to create a text post.
     
     - Parameter sender: Button that initiates the segue
     */
    @IBAction func createTextButton(_ sender: UIButton) {
        selectedButtonColors(button:sender)
        deselectedButtonColors(button:createDrawingButtonVar)
        changeViewToText()
        currentState = "text"
    }
    
    
    // Go back to main feed
    @IBAction func backButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil);
    }
    
    
    /**
     Switches to the screen to create a drawing post.
     
     - Parameter sender: Button that initiates the segue
     */
    @IBAction func createDrawingButton(_ sender: UIButton) {
        frontTextView.resignFirstResponder() // close keyboard if open
        selectedButtonColors(button:sender)
        deselectedButtonColors(button:createTextButtonVar)
        changeViewToDrawing()
        currentState = "draw"
    }
    
    /// Changes the current screen to show a textbox.
    func changeViewToText(){
        if drawingCanvasView.isHidden == false {
            GlobalSliderTopToTextviewConstraint.constant += 25
            drawingCanvasView.isHidden = true
        }
        clearButtonVar.isHidden = true
        ColorButtonVar.isHidden = true
        frontTextView.isHidden = false
        backTextView.isHidden = false
        newPostTextBackground.isHidden = false
    }
    
    /// Changes the current screen to show a drawing canvas.
    func changeViewToDrawing(){
        if newPostTextBackground.isHidden == false {
            GlobalSliderTopToTextviewConstraint.constant -= 25
            newPostTextBackground.isHidden = true
        }
        frontTextView.isHidden = true
        backTextView.isHidden = true
        drawingCanvasView.isHidden = false
        clearButtonVar.isHidden = false
        ColorButtonVar.isHidden = false
    }
    
    /**
     Changes the color of the selected button to purple.
     
     - Parameter button: Button that initiates this action
     */
    func selectedButtonColors(button: UIButton){
        button.setTitleColor(Constants.Colors.darkPurple, for: .normal)
        button.setImage(UIImage(systemName: "circle.fill", withConfiguration: nil), for: .normal)
        button.tintColor = Constants.Colors.darkPurple
    }
    
    /**
     Changes the color of the Deselected button to label color (black/white)
     
     - Parameter button: Button that initiates this action
     */
    func deselectedButtonColors(button: UIButton){
        button.setTitleColor(.label, for: .normal)
        button.setImage(UIImage(systemName: "circle", withConfiguration: nil), for: .normal)
        button.tintColor = .label
    }
    
    func setTimeStamp() -> Bool {
        // Don't let user post twice within 30 seconds
        if Globals.lastPostingTimestamp != 0.0 {
            print("lastPostingTimestamp is \(Globals.lastPostingTimestamp)")
            let timeDiff = Date().timeIntervalSince1970 - Globals.lastPostingTimestamp
            if timeDiff < Constants.spamLength { // less than 30 seconds ago
                spamPopup()
                return true
            }
        } else {
            Globals.lastPostingTimestamp = Double(Date().timeIntervalSince1970)
            return false
        }
        return false
    }
    
    /**
     Clear the drawing canvas and create an image from the drawing.
     
     - Parameter sender: Button initiating this action
     */
    @IBAction func clearButton(_ sender: Any) {
        drawingCanvasView.clearCanvas()
    }
    
    @IBAction func colorButton(_ sender: Any) {
        if ColorButtonVar.titleColor(for: .normal) == .label {
            ColorButtonVar.setTitleColor(Constants.Colors.darkPurple, for: .normal)
        } else {
            ColorButtonVar.setTitleColor(.label, for: .normal)
        }
        drawingCanvasView.changeColor()
    }
    
    @IBAction func GlobalSliderChanged(_ sender: Any) {
        /// selectedIndex of 0 = Post Locally, selectedIndex of 1 = Post Globally and Locally
        // Default Selected index is 0
        /// This function does nothing for now, since we are just using the selectedIndex to determine the visibility of the post
        /// Logic for post visibility is implemented server-side
        /// Attribute for post visibility is a property given to the Post data structure
    }
    
    
    // Move comment input box up when keyboard opens
    @objc func keyboardWillShow(notification: Notification) {
//        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
//        {
//            /* Don't move the submit post button
//            if (UIScreen.main.bounds.size.height < 736.0){
//                AddButtonContainingViewConstraint.constant = keyboardSize.height + 10
//            } else {
//                AddButtonContainingViewConstraint.constant = keyboardSize.height - 20
//            }
//            view.setNeedsLayout()
//             */
//        }

    }

    // Move comment input back down when keyboard closes
    @objc func keyboardWillHide(notification: Notification) {
        AddButtonContainingViewConstraint.constant = 40
        if backTextView.text == "" && frontTextView.text == "" {
            if Globals.ViewSettings.groupName == "Grapevine" {
                backTextView.text = "What's actually on your mind?"
            } else {
                backTextView.text = "Post to \(Globals.ViewSettings.groupName)"
            }
        }
        
        view.setNeedsLayout()
    }
    
    /**
     Adds the new post to the database.
     
     - Parameter sender: Button pressed to activate this function
     */
    @objc func addPostButton() {
        //Set post visibility
        if GlobalSlider.selectedSegmentIndex == 0 {
            visibility = "Local"
        } else {
            visibility = "Global"
        }

        // Change button color to make it feel responsive
        AddButtonContainingView.backgroundColor = Constants.Colors.lightPurple
        
        // Hide keyboard
        self.view.endEditing(true)
        
        // Show activity spinner
        self.spinnerView = UIView.init(frame: self.view.bounds)
        spinnerView?.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        let ai = UIActivityIndicatorView.init(style: .large)
        ai.startAnimating()
        ai.center = (spinnerView?.center)!
        spinnerView?.addSubview(ai)
        self.view.addSubview(spinnerView!)
        
        //Get Location. Callback function sends request (location manager delegate)
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestLocation()
        newPostCreationAttempt = true
    }
    
    func sendRequest() {
        if currentState == "text" {
            print("current state text")
            if var textFieldBody = frontTextView.text {
                //trim whitespace, so people cant enter a post that is just spaces (only before and after non-whitespace charachters. Not inbetween
                textFieldBody = textFieldBody.trimmingCharacters(in: .whitespacesAndNewlines)
                if textFieldBody.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                    postsManager.checkToxicity(text: textFieldBody)
                    self.textFieldBody = textFieldBody
                } else {
                    backButton(self)
                }
            }
        } else {
            drawingCanvasView.layer.cornerRadius = 0
            let imData = drawingCanvasView.renderToImage()
            if imData != nil {
                if setTimeStamp() { //Show alert and return to main screen if user is spanmming also closes view after completion
                    return
                }
                let image = imData!.pngData()
                let base64 = image!.base64EncodedString()
                postsManager.performPOSTRequest(contentText: String(base64), latitude: lat, longitude: lon, postType: "image", groupID: self.groupID, visibility: visibility)
            } else {
                backButton(self)
            }
            drawingCanvasView.layer.cornerRadius = 10.0
        }

    }
    
    func spamPopup(){
        let alert = MDCAlertController(title: "Too Much Posting", message: "To prevent potential spamming, we can't let you post that much. Try again later")
        let action1 = MDCAlertAction(title: "Ok") { (action) in super.dismiss(animated: true, completion: nil)}
        alert.addAction(action1)
        makePopup(alert: alert, image: "x.circle.fill")
        self.present(alert, animated: true)
        alert.mdc_dialogPresentationController?.dismissOnBackgroundTap = false //ideally we would have this enabled and use a completion handler to dismiss the view on background tap. But the documentation is poor and a better solution has not yet been found.

    }

}

/// Manages the text displayed in the new post.
extension NewPostViewController: UITextViewDelegate {
    /**
     Removes the default text once the user starts editing.
     
     - Parameter textView: Textbox being modifed.
     */
    func textViewDidBeginEditing(_ textView: UITextView){
        backTextView.text = ""
        frontTextView.textColor = UIColor.label
        frontTextView.tintColor = Constants.Colors.darkPurple

    }
    
    /**
     Updates the new post text box.
     
     - Parameters:
        - textView: Textbox being modified
        - range: Characters to be replaced
        - text: New text to be displayed
     
     - Returns: True or false based on whether the total number of characters in the text box are under the character limit
     */
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).replacingCharacters(in:range, with: text)
        let numberOfChars = newText.count
        return numberOfChars < Constants.numberOfCharactersPerPost;
    }
}

extension NewPostViewController: PostsManagerDelegate {
    func handleToxicityStatus(toxicScore: Double) {
        DispatchQueue.main.async {
            if toxicScore >= 0.8 {
                let alert = MDCAlertController(title: "High Toxicity Score", message: "Your post has a high toxicity score: " + String(toxicScore) + ". It may be flagged for review. Would you like to post it anyways?")
                let action1 = MDCAlertAction(title: "Don't Post") { (action) in //self.dismiss(animated: true, completion: {
                    self.spinnerView?.removeFromSuperview()
                    self.newPostCreationAttempt = false
                    self.selectedButtonColors(button: self.createTextButtonVar)
                    self.deselectedButtonColors(button: self.createDrawingButtonVar)
                    self.changeViewToText()
                    self.currentState = "text"
                    self.backTextView.text = ""
                    self.frontTextView.text = self.textFieldBody
                    self.AddButtonContainingView.backgroundColor = .systemBackground
                }//}) }
                let action2 = MDCAlertAction(title: "Post anyway") { (action) in
                    if self.setTimeStamp() { //Show alert and return to main screen if user is spanmming also closes view after completion
                        return
                    }
                    self.postsManager.performPOSTRequest(contentText: self.textFieldBody!, latitude: self.lat, longitude: self.lon, postType: "text", groupID: self.groupID, visibility: self.visibility)
                }
                alert.addAction(action2)
                alert.addAction(action1)
                makePopup(alert: alert, image: "x.circle.fill")
                let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.warning)
                self.present(alert, animated: true)
                alert.mdc_dialogPresentationController?.dismissOnBackgroundTap = false //ideally we would have this enabled and use a completion handler to dismiss the view on background tap. But the documentation is poor and a better solution has not yet been found.
            } else {
                if self.setTimeStamp() { //Show alert and return to main screen if user is spanmming also closes view after completion
                    return
                }
                self.postsManager.performPOSTRequest(contentText: self.textFieldBody!, latitude: self.lat, longitude: self.lon, postType: "text", groupID: self.groupID, visibility: self.visibility)
            }
        }
    }
    
    func contentNotPermitted() {
        DispatchQueue.main.async {
            let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.error)
            let alert = MDCAlertController(title: "Content Not Permitted", message: "You created a post containing content that we do not support on this platform. Please be respectful to other users.")
            let action1 = MDCAlertAction(title: "Ok") { (action) in super.dismiss(animated: true, completion: nil) }
            alert.addAction(action1)
            makePopup(alert: alert, image: "x.circle.fill")
            self.present(alert, animated: true)
            alert.mdc_dialogPresentationController?.dismissOnBackgroundTap = false //ideally we would have this enabled and use a completion handler to dismiss the view on background tap. But the documentation is poor and a better solution has not yet been found.
        }
    }
    
    func didGetSinglePost(_ postManager: PostsManager, post: Post) {
        return
    }
    
    func didUpdatePosts(_ postManager: PostsManager, posts: [Post], ref: String) {}
    func didGetMorePosts(_ postManager: PostsManager, posts: [Post], ref: String) {}
    func didFailWithError(error: Error) {}
    
    func didCreatePost() {
        self.delegate?.postCreated()
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil);
        }
    }
}

extension NewPostViewController: CLLocationManagerDelegate {
    /** Fetches posts based on current user location. */
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            self.lat = location.coordinate.latitude
            self.lon = location.coordinate.longitude
            print("Location request success")
            if newPostCreationAttempt == true {
                self.sendRequest()
                newPostCreationAttempt = false
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
        let alert = MDCAlertController(title: "Crikey! Unable to verify location", message: "Would you like to submit your post to Global?")
        let action1 = MDCAlertAction(title: "Yes") { (action) in super.dismiss(animated: true, completion: {self.sendRequest()})}
        alert.addAction(action1)
        let action2 = MDCAlertAction(title: "No") { (action) in super.dismiss(animated: true, completion: nil)}
        alert.addAction(action2)
        makePopup(alert: alert, image: "info.circle.fill")
        self.present(alert, animated: true)
        alert.mdc_dialogPresentationController?.dismissOnBackgroundTap = false //ideally we would have this enabled and use a completion handler to dismiss the view on background tap. But the documentation is poor and a better solution has not yet been found.
    }
}

// Add a "Done" button to close the keyboard
extension UITextView {
    func addDoneButton(title: String, target: Any, selector: Selector) {
        let toolBar = UIToolbar(frame: CGRect(x: 0.0,
                                              y: 0.0,
                                              width: UIScreen.main.bounds.size.width,
                                              height: 44.0))//1
        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)//2
        let barButton = UIBarButtonItem(title: title, style: .done, target: target, action: selector)//3
        toolBar.setItems([flexible, barButton], animated: false)//4
        self.inputAccessoryView = toolBar//5
    }
}
