import Foundation
import FirebaseFirestore
import UIKit
import CoreLocation

/// Manages the control flow for making a new post.
class NewPostViewController: UIViewController {
    let db = Firestore.firestore()
    var currentState = "text"
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var frontTextView: UITextView! // actual user input text
    @IBOutlet weak var backTextView: UITextView! // placeholder text
    @IBOutlet weak var newPostTextBackground: UIButton! // text
    @IBOutlet weak var drawingCanvasView: CanvasView! // drawing
    var lat:CLLocationDegrees = 0.0
    var lon:CLLocationDegrees = 0.0
    var postsManager = PostsManager()
    
    @IBOutlet weak var createTextButtonVar: UIButton!
    @IBOutlet weak var createDrawingButtonVar: UIButton!
    @IBOutlet weak var clearButtonVar: UIButton!
    
    
    @IBOutlet weak var AddButtonContainingViewConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var AddButtonContainingView: UIView!
    
    /**
     Intializes the new post screen.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        newPostTextBackground.layer.cornerRadius = 10.0
        newPostTextBackground.backgroundColor = UIColor(red:0.98, green:0.98, blue:0.98, alpha:1.0)
        backTextView.textColor = UIColor.lightGray
        drawingCanvasView.layer.cornerRadius = 10.0
        drawingCanvasView.backgroundColor = UIColor(red:0.98, green:0.98, blue:0.98, alpha:1.0)
        frontTextView.delegate = self
        frontTextView.isHidden = false
        
        AddButtonContainingView.layer.cornerRadius = 25
        
        // Add listeners to keyboard to reposition "Add Post" button
        NotificationCenter.default.addObserver(self, selector: #selector(CommentViewController.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(CommentViewController.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
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
    
    /**
     Switches to the screen to create a drawing post.
     
     - Parameter sender: Button that initiates the segue
     */
    @IBAction func createDrawingButton(_ sender: UIButton) {
        selectedButtonColors(button:sender)
        deselectedButtonColors(button:createTextButtonVar)
        changeViewToDrawing()
        currentState = "draw"
    }
    
    /// Changes the current screen to show a textbox.
    func changeViewToText(){
        drawingCanvasView.isHidden = true
        clearButtonVar.isHidden = true
        frontTextView.isHidden = false
        backTextView.isHidden = false
        newPostTextBackground.isHidden = false
        AddButtonContainingViewConstraint.constant = 240
    }
    
    /// Changes the current screen to show a drawing canvas.
    func changeViewToDrawing(){
        frontTextView.isHidden = true
        backTextView.isHidden = true
        newPostTextBackground.isHidden = true
        drawingCanvasView.isHidden = false
        clearButtonVar.isHidden = false
        AddButtonContainingViewConstraint.constant = 240
    }
    
    /**
     Changes the color of the canvas brush to purple.
     
     - Parameter button: Button that initiates this action
     */
    func selectedButtonColors(button: UIButton){
        button.setTitleColor(Constants.Colors.darkPurple, for: .normal)
        button.setImage(UIImage(systemName: "circle.fill", withConfiguration: nil), for: .normal)
        button.tintColor = Constants.Colors.darkPurple
    }
    
    /**
     Changes the color of the cancas brush to black.
     
     - Parameter button: Button that initiates this action
     */
    func deselectedButtonColors(button: UIButton){
        button.setTitleColor(.black, for: .normal)
        button.setImage(UIImage(systemName: "circle", withConfiguration: nil), for: .normal)
        button.tintColor = .black
    }
    
    /**
     Clear the drawing canvas and create an image from the drawing.
     
     - Parameter sender: Button initiating this action
     */
    @IBAction func clearButton(_ sender: Any) {
        drawingCanvasView.clearCanvas()
    }
    
    // Move comment input box up when keyboard opens
    @objc func keyboardWillShow(notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            AddButtonContainingViewConstraint.constant = keyboardSize.height - 20
            view.setNeedsLayout()
        }

    }

    // Move comment input back down when keyboard closes
    @objc func keyboardWillHide(notification: Notification) {
        AddButtonContainingViewConstraint.constant = 240
        view.setNeedsLayout()
    }
    
    /**
     Adds the new post to the database.
     
     - Parameter sender: Button pressed to activate this function
     */
    @IBAction func addPostButton(_ sender: Any) {
        if currentState == "text" {
            print("current state text")
            if let textFieldBody = frontTextView.text {
                if textFieldBody != "" {
                    postsManager.performPOSTRequest(contentText: textFieldBody, latitude: lat, longitude: lon, postType: "text")
                    self.frontTextView.text = ""
                }
            }
            self.performSegue(withIdentifier: "goToMain", sender: self)
        } else {
            let imData = drawingCanvasView.renderToImage()
            if imData != nil {
                let image = imData!.pngData()
                let base64 = image!.base64EncodedString()
                postsManager.performPOSTRequest(contentText: String(base64), latitude: lat, longitude: lon, postType: "image")
            }
            self.performSegue(withIdentifier: "goToMain", sender: self)
        }
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
        frontTextView.textColor = UIColor.black
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

// Add a "Done" button to close the keyboard
extension UITextView {
    func addDoneButton(title: String, target: Any, selector: Selector) {
        let toolBar = UIToolbar(frame: CGRect(x: 0.0,
                                              y: 0.0,
                                              width: UIScreen.main.bounds.size.width,
                                              height: 44.0))//1
        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)//2
        let barButton = UIBarButtonItem(title: title, style: .plain, target: target, action: selector)//3
        toolBar.setItems([flexible, barButton], animated: false)//4
        self.inputAccessoryView = toolBar//5
    }
}


