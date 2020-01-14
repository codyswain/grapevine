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

    @IBOutlet weak var newPostTextBox: UITextField!
        
    override func viewDidLoad() {
        super.viewDidLoad()
//        navigationItem.hidesBackButton = true
    }
    
    @IBAction func PostButton(_ sender: UIButton) {
        if let textFieldBody = newPostTextBox.text {
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
                         self.newPostTextBox.text = ""
                    }
                }
            }
        }
        self.performSegue(withIdentifier: "goToMain", sender: self)
    }
}
