//
//  WalkthroughViewController.swift
//  Grapevine-130
//
//  Created by Cody Swain on 4/18/20.
//  Copyright © 2020 Anthony Humay. All rights reserved.
//

import Foundation
import UIKit
import MaterialComponents.MaterialDialogs

class WalkthroughViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return setStatusBarStyle()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set dark/light mode from persistent storage
        setTheme(curView: self)
        
        collectionView?.backgroundColor = Constants.Colors.darkPurple
        collectionView?.register(WalkthroughPageCell.self, forCellWithReuseIdentifier:"cellId")
        collectionView?.isPagingEnabled = true
        
    }
    
    // Fix weird spacing for each cell (minimum is 10 by default)
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }
    
    // Define cells
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellId", for: indexPath) as? WalkthroughPageCell else {
            fatalError("Wrong cell class dequeued")}
//        cell.backgroundColor = indexPath.item % 2 == 0 ? .red : .green
        cell.delegate = self
        switch indexPath.item {
        case 0:
            cell.pageImageView.image = UIImage(named: "Grapevine Icon Transparent")
            let attrText = NSMutableAttributedString(string: "Welcome to Grapevine!", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24),  NSAttributedString.Key.foregroundColor: UIColor.white])
            attrText.append(NSAttributedString(string: "\n←", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 40), NSAttributedString.Key.foregroundColor: UIColor.white]))
            attrText.append(NSAttributedString(string: "\nSwipe left to start", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18), NSAttributedString.Key.foregroundColor: UIColor.white]))
            cell.descriptionTextView.attributedText = attrText
            cell.descriptionTextView.textAlignment = .center
            cell.descriptionTextView.translatesAutoresizingMaskIntoConstraints = false
            cell.descriptionTextView.isEditable = false
            cell.descriptionTextView.isSelectable = false
            cell.descriptionTextView.isScrollEnabled = false
            cell.continueImageView.image = UIImage(named: "")
        case 1:
            cell.pageImageView.image = UIImage(named: "Map")
            let attrText = NSMutableAttributedString(string: "This is your location based,", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24),  NSAttributedString.Key.foregroundColor: UIColor.white])
//            attrText.append(NSAttributedString(string: "\n→", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 26), NSAttributedString.Key.foregroundColor: UIColor.white]))
            cell.descriptionTextView.attributedText = attrText
            cell.descriptionTextView.textAlignment = .center
            cell.descriptionTextView.translatesAutoresizingMaskIntoConstraints = false
            cell.descriptionTextView.isEditable = false
            cell.descriptionTextView.isSelectable = false
            cell.descriptionTextView.isScrollEnabled = false
            cell.continueImageView.image = UIImage(named: "")
        case 2:
            cell.pageImageView.image = UIImage(named: "Ghost")
            let attrText = NSMutableAttributedString(string: "anonymous,", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24),  NSAttributedString.Key.foregroundColor: UIColor.white])
//            attrText.append(NSAttributedString(string: "\n→", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 26), NSAttributedString.Key.foregroundColor: UIColor.white]))
            cell.descriptionTextView.attributedText = attrText
            cell.descriptionTextView.textAlignment = .center
            cell.descriptionTextView.translatesAutoresizingMaskIntoConstraints = false
            cell.descriptionTextView.isEditable = false
            cell.descriptionTextView.isSelectable = false
            cell.descriptionTextView.isScrollEnabled = false
            cell.continueImageView.image = UIImage(named: "")
        case 3:
            cell.pageImageView.image = UIImage(named: "Party")
            cell.descriptionTextView.attributedText = NSMutableAttributedString(string: "community!", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 26),  NSAttributedString.Key.foregroundColor: UIColor.white])
            cell.descriptionTextView.textAlignment = .center
            cell.descriptionTextView.translatesAutoresizingMaskIntoConstraints = false
            cell.descriptionTextView.isEditable = false
            cell.descriptionTextView.isSelectable = false
            cell.descriptionTextView.isScrollEnabled = false
            cell.continueImageView.image = UIImage(named: "Enter")
        default:
            print("This should not be occuring")
        }
        return cell
    }
    
    // Set the size of each element
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: view.frame.height)
    }
    
    // Removes header of the UICollectionView
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize.zero
    }
    
}

extension WalkthroughViewController: WalkthroughPageCellDelegate {
    func continueButtonTapped() {
        firstTimeUserWelcomeAlert()
    }
        
    func firstTimeUserWelcomeAlert(){
        let alert = MDCAlertController(title: "Just a few more details!", message: "The main feed shows you posts that were created within a few miles of you, anonymously.\n\nYou can create your own or upvote, downvote, and comment on others!")
        alert.addAction(MDCAlertAction(title: "Next") { (action) in self.firstTimeUserKarmaAlert() })
        makePopup(alert: alert, image: "location.circle.fill")
        super.present(alert, animated: true)
    }
    
    func firstTimeUserKarmaAlert(){
        let alert = MDCAlertController(title: "Karma", message: "The upvotes/downvotes you get on your posts and comments are tallied and summed into a number called Karma.\n\nKarma allows you to unlock special abilities on Grapevine, like being able to notify close by users of your posts or being able to ban people.")
        alert.addAction(MDCAlertAction(title: "Next") { (action) in self.firstTimeUserRulesAlert() })
        makePopup(alert: alert, image: "location.circle.fill")
        super.present(alert, animated: true)
    }
    
    func firstTimeUserRulesAlert(){
        let alert = MDCAlertController(title: "Rules", message: "You must agree to our rules. If you see content that doesn't belong, press and hold to report!\n\n1. Posting bullying, threats, terrorism, harrassment, or stalking will not be allowed and may force law enforcement to be involved.\n\n2. Using names of individual people (non-public figures) is not allowed.\n\n3. Anonymity is a privilege, not a right. You can be banned at any time for any reason. ")
        alert.addAction(MDCAlertAction(title: "I agree, let me in!") { (action) in
            let viewController:UIViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MainViewController") as UIViewController
            viewController.modalPresentationStyle = .fullScreen
            self.present(viewController, animated: false, completion: nil)
        })
        alert.addAction(MDCAlertAction(title: "Privacy Policy") { (action) in
            let application = UIApplication.shared
            let webURL = URL(string: "https://medium.com/@ahumay/grapevine-privacy-policy-a4cf5a4e0fd9")!
            application.open(webURL)
        })
        makePopup(alert: alert, image: "location.circle.fill")
        super.present(alert, animated: true)
    }
}
