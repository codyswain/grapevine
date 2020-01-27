//
//  NewPostViewController.swift
//  Grapevine
//
//  Created by Anthony Humay on 1/13/20.
//  Copyright © 2020 Grapevine. All rights reserved.
//

import Foundation
import FirebaseFirestore
import UIKit

class NewPostViewController: UIViewController {
    let db = Firestore.firestore()

    @IBOutlet weak var postButton: UIButton!
    @IBOutlet weak var frontTextView: UITextView! // actual user input text
    @IBOutlet weak var backTextView: UITextView! // placeholder text
    @IBOutlet weak var newPostTextBackground: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        frontTextView.delegate = self
        postButton.tintColor = Constants.Colors.darkPurple
        newPostTextBackground.layer.cornerRadius = 10.0
        newPostTextBackground.backgroundColor = UIColor(red:0.98, green:0.98, blue:0.98, alpha:1.0)
        backTextView.textColor = UIColor.lightGray
    }
        
    @IBAction func PostButton(_ sender: UIButton) {
        if let textFieldBody = frontTextView.text {
            db.collection(Constants.Firestore.collectionName).addDocument(data: [
                Constants.Firestore.textField: textFieldBody,
                Constants.Firestore.userIDField: "",
                Constants.Firestore.votesField: 0,
                Constants.Firestore.dateField: Date().timeIntervalSince1970
            ]) { (error) in
                if let e = error {
                    print("There was an issue saving data to firestore, \(e)")
                } else {
                    print("Successfully saved data.")

                    DispatchQueue.main.async {
                         self.frontTextView.text = ""
                    }
                }
            }
        }
        self.performSegue(withIdentifier: "goToMain", sender: self)
    }
}

extension NewPostViewController: UITextViewDelegate {
    // Gets rid of placeholder text
    func textViewDidBeginEditing(_ textView: UITextView){
        backTextView.text = ""
        frontTextView.textColor = UIColor.black
    }
    
    // Limit the number of characters in a post
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).replacingCharacters(in:range, with: text)
        let numberOfChars = newText.count
        return numberOfChars < Constants.numberOfCharactersPerPost;
    }

}

