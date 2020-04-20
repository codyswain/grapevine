//
//  WalkthroughViewController.swift
//  Grapevine-130
//
//  Created by Cody Swain on 4/18/20.
//  Copyright © 2020 Anthony Humay. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase
import FirebaseFirestore

class WalkthroughViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    override func viewDidLoad() {
        super.viewDidLoad()
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
            cell.pageImageView.image = UIImage(named: "Grapes")
            let attrText = NSMutableAttributedString(string: "Welcome to Grapevine!", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24),  NSAttributedString.Key.foregroundColor: UIColor.white])
            attrText.append(NSAttributedString(string: "\n→", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 40), NSAttributedString.Key.foregroundColor: UIColor.white]))
            cell.descriptionTextView.attributedText = attrText
            cell.descriptionTextView.textAlignment = .center
            cell.descriptionTextView.translatesAutoresizingMaskIntoConstraints = false
            cell.descriptionTextView.isEditable = false
            cell.descriptionTextView.isSelectable = false
            cell.descriptionTextView.isScrollEnabled = false
            cell.continueImageView.image = UIImage(named: "")
        case 1:
            cell.pageImageView.image = UIImage(named: "Ghost")
            let attrText = NSMutableAttributedString(string: "an anonymous...", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24),  NSAttributedString.Key.foregroundColor: UIColor.white])
//            attrText.append(NSAttributedString(string: "\n→", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 26), NSAttributedString.Key.foregroundColor: UIColor.white]))
            cell.descriptionTextView.attributedText = attrText
            cell.descriptionTextView.textAlignment = .center
            cell.descriptionTextView.translatesAutoresizingMaskIntoConstraints = false
            cell.descriptionTextView.isEditable = false
            cell.descriptionTextView.isSelectable = false
            cell.descriptionTextView.isScrollEnabled = false
            cell.continueImageView.image = UIImage(named: "")
        case 2:
            cell.pageImageView.image = UIImage(named: "Map")
            let attrText = NSMutableAttributedString(string: "location based...", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24),  NSAttributedString.Key.foregroundColor: UIColor.white])
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
            cell.descriptionTextView.attributedText = NSMutableAttributedString(string: "social app!", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 26),  NSAttributedString.Key.foregroundColor: UIColor.white])
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
        let viewController:UIViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MainViewController") as UIViewController
        viewController.modalPresentationStyle = .fullScreen
        self.present(viewController, animated: false, completion: nil)
    }
}
