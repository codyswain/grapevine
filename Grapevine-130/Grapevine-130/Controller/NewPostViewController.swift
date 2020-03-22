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
    }
    
    /// Changes the current screen to show a drawing canvas.
    func changeViewToDrawing(){
        frontTextView.isHidden = true
        backTextView.isHidden = true
        newPostTextBackground.isHidden = true
        drawingCanvasView.isHidden = false
        clearButtonVar.isHidden = false
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
                print("base64 image to be sent")
                print(base64)
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

