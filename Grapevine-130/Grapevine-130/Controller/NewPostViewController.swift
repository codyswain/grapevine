import Foundation
import UIKit
import CoreLocation
import MaterialComponents.MaterialDialogs

/// Manages the control flow for making a new post.
class NewPostViewController: UIViewController {
    var currentState = "text"

    @IBOutlet weak var frontTextView: UITextView! // actual user input text
    @IBOutlet weak var backTextView: UITextView! // placeholder text
    @IBOutlet weak var newPostTextBackground: UIButton! // text
    @IBOutlet weak var drawingCanvasView: CanvasView! // drawing
    var lat:CLLocationDegrees = 0.0
    var lon:CLLocationDegrees = 0.0
    var postsManager = PostsManager()
    var lastPostingTimestamp:Double = 0.0

    @IBOutlet weak var ColorButtonVar: UIButton!
    @IBOutlet weak var createTextButtonVar: UIButton!
    @IBOutlet weak var createDrawingButtonVar: UIButton!
    @IBOutlet weak var clearButtonVar: UIButton!
    @IBOutlet weak var AddButtonContainingViewConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var AddButtonContainingView: UIView!
    @IBOutlet var newPostView: UIView!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        //Changes colors of status bar so it will be visible in dark or light mode
        if Globals.ViewSettings.CurrentMode == .dark {
            return .lightContent
        }
        else{
            return .darkContent
        }
    } 
    
    /**
     Intializes the new post screen.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set dark/light mode
        if Globals.ViewSettings.CurrentMode == .dark {
            super.overrideUserInterfaceStyle = .dark
        }
        else if Globals.ViewSettings.CurrentMode == .light {
            super.overrideUserInterfaceStyle = .light
        }
        
        postsManager.delegate = self
        
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
        drawingCanvasView.isHidden = true
        clearButtonVar.isHidden = true
        ColorButtonVar.isHidden = true
        frontTextView.isHidden = false
        backTextView.isHidden = false
        newPostTextBackground.isHidden = false
    }
    
    /// Changes the current screen to show a drawing canvas.
    func changeViewToDrawing(){
        frontTextView.isHidden = true
        backTextView.isHidden = true
        newPostTextBackground.isHidden = true
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
    
    // Move comment input box up when keyboard opens
    @objc func keyboardWillShow(notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if (UIScreen.main.bounds.size.height < 736.0){
                AddButtonContainingViewConstraint.constant = keyboardSize.height + 10
            } else {
                AddButtonContainingViewConstraint.constant = keyboardSize.height - 20
            }
            view.setNeedsLayout()
        }

    }

    // Move comment input back down when keyboard closes
    @objc func keyboardWillHide(notification: Notification) {
        AddButtonContainingViewConstraint.constant = 40
        if backTextView.text == "" && frontTextView.text == "" {
            backTextView.text = "What's actually on your mind?"
        }
        
        view.setNeedsLayout()
    }
    
    /**
     Adds the new post to the database.
     
     - Parameter sender: Button pressed to activate this function
     */
    @objc func addPostButton() {
        // Don't let user post twice within 30 seconds
        if lastPostingTimestamp != 0.0 {
            print("lastPostingTimestamp is \(lastPostingTimestamp)")
            let timeDiff = Date().timeIntervalSince1970 - lastPostingTimestamp
            if timeDiff < Constants.spamLength { // less than 30 seconds ago
                spamPopup()
                return
            }
        } else {
            lastPostingTimestamp = Double(Date().timeIntervalSince1970)
        }

        // Change button color to make it feel responsive
        AddButtonContainingView.backgroundColor = Constants.Colors.lightPurple
        
        // Hide keyboard
        self.view.endEditing(true)
        
        // Show activity spinner
        let spinnerView = UIView.init(frame: self.view.bounds)
        spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        let ai = UIActivityIndicatorView.init(style: .large)
        ai.startAnimating()
        ai.center = spinnerView.center
        spinnerView.addSubview(ai)
        self.view.addSubview(spinnerView)
        
        if currentState == "text" {
            print("current state text")
            if let textFieldBody = frontTextView.text {
                if textFieldBody != "" {
                    postsManager.performPOSTRequest(contentText: textFieldBody, latitude: lat, longitude: lon, postType: "text")
                }
            }
        } else {
            drawingCanvasView.layer.cornerRadius = 0
            let imData = drawingCanvasView.renderToImage()
            if imData != nil {
                let image = imData!.jpegData(compressionQuality: 0.5)
                let base64 = image!.base64EncodedString()
                postsManager.performPOSTRequest(contentText: String(base64), latitude: lat, longitude: lon, postType: "image")
            }
            drawingCanvasView.layer.cornerRadius = 10.0
        }
    }
    
    func spamPopup(){
        let alert = MDCAlertController(title: "Too Much Posting", message: "To prevent potential spamming, we can't let you post that much. Try again later")
        alert.backgroundColor = Globals.ViewSettings.BackgroundColor
        alert.titleColor = Globals.ViewSettings.LabelColor
        alert.messageColor = Globals.ViewSettings.LabelColor
        let action1 = MDCAlertAction(title: "Ok") { (action) in }
        alert.addAction(action1)
        makePopup(alert: alert, image: "x.circle.fill")
        self.present(alert, animated: true, completion: nil)

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
    func didUpdatePosts(_ postManager: PostsManager, posts: [Post], ref: String) {}
    func didGetMorePosts(_ postManager: PostsManager, posts: [Post], ref: String) {}
    func didFailWithError(error: Error) {}
    
    func didCreatePost() {
        DispatchQueue.main.async {
          self.dismiss(animated: true, completion: nil);
        }
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
