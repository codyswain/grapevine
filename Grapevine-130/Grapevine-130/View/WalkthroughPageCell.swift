//
//  WalkthroughPageCell.swift
//  Grapevine-130
//
//  Created by Cody Swain on 4/18/20.
//  Copyright © 2020 Anthony Humay. All rights reserved.
//

import UIKit

protocol WalkthroughPageCellDelegate {
    func continueButtonTapped()
}

class WalkthroughPageCell: UICollectionViewCell {
    var pageIndex = 0
    var pageImageView = UIImageView()
    var topImageContainerView = UIView()
    var descriptionTextView = UITextView()
    var continueImageView = UIImageView()
    var renderContinueButton: Bool = false
    var bottomDescriptionView = UIView()
    var delegate: WalkthroughPageCellDelegate?
    
//    let descriptionTextView: UITextView = {
//        let textView = UITextView()
//        let attributedText = NSMutableAttributedString(string: "Welcome to Grapevine!", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24),  NSAttributedString.Key.foregroundColor: UIColor.white])
//        attributedText.append(NSAttributedString(string: "\n→", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 40), NSAttributedString.Key.foregroundColor: UIColor.white]))
//
////        attributedText.append(NSAttributedString(string: "\n\n\nAre you ready for loads and loads of fun? Don't wait any longer! We hope to see you in our stores soon.", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13), NSAttributedString.Key.foregroundColor: UIColor.gray]))
////
//        textView.attributedText = attributedText
//        textView.translatesAutoresizingMaskIntoConstraints = false
//        textView.textAlignment = .center
//        textView.isEditable = false
//        textView.isScrollEnabled = false
//        return textView
//    }()
    
    override init(frame: CGRect){
        super.init(frame: frame)
        backgroundColor = UIColor.systemGray3
        pageImageView.translatesAutoresizingMaskIntoConstraints = false
        pageImageView.contentMode = .scaleAspectFit
        
        // Add tapping capabilities to downvote button (UIImageView)
        let tapGestureRecognizerContinue = UITapGestureRecognizer(target: self, action: #selector(continueTapped(tapGestureRecognizer:)))
        continueImageView.isUserInteractionEnabled = true
        continueImageView.addGestureRecognizer(tapGestureRecognizerContinue)
        
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func continueTapped(tapGestureRecognizer: UITapGestureRecognizer){
        self.delegate?.continueButtonTapped()
    }
    
    public func setupLayout() {
            topImageContainerView.backgroundColor = Constants.Colors.darkPurple
            addSubview(topImageContainerView)
            //enable auto layout
            topImageContainerView.translatesAutoresizingMaskIntoConstraints = false
            topImageContainerView.topAnchor.constraint(equalTo: topAnchor).isActive = true
            topImageContainerView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            topImageContainerView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            
            topImageContainerView.addSubview(pageImageView)
            pageImageView.centerXAnchor.constraint(equalTo: topImageContainerView.centerXAnchor).isActive = true
            pageImageView.centerYAnchor.constraint(equalTo: topImageContainerView.centerYAnchor, constant: 100).isActive = true
            pageImageView.heightAnchor.constraint(equalTo: topImageContainerView.heightAnchor, multiplier: 0.4).isActive = true
        
            topImageContainerView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.5).isActive = true
        
            addSubview(bottomDescriptionView)
            bottomDescriptionView.translatesAutoresizingMaskIntoConstraints = false
            bottomDescriptionView.topAnchor.constraint(equalTo: topImageContainerView.bottomAnchor).isActive = true
            bottomDescriptionView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            bottomDescriptionView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            bottomDescriptionView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
            bottomDescriptionView.backgroundColor = Constants.Colors.darkPurple
        
            bottomDescriptionView.addSubview(descriptionTextView)
            descriptionTextView.backgroundColor = Constants.Colors.darkPurple
            descriptionTextView.topAnchor.constraint(equalTo: topImageContainerView.bottomAnchor, constant: 30).isActive = true
            descriptionTextView.leftAnchor.constraint(equalTo: leftAnchor, constant: 24).isActive = true
            descriptionTextView.rightAnchor.constraint(equalTo: rightAnchor, constant: -24).isActive = true
            descriptionTextView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
        
            bottomDescriptionView.addSubview(continueImageView)
            continueImageView.translatesAutoresizingMaskIntoConstraints = false
            continueImageView.centerXAnchor.constraint(equalTo: descriptionTextView.centerXAnchor).isActive = true
            continueImageView.centerYAnchor.constraint(equalTo: bottomAnchor, constant: -80).isActive = true
            continueImageView.heightAnchor.constraint(equalTo: bottomDescriptionView.heightAnchor, multiplier: 0.14).isActive = true
            continueImageView.widthAnchor.constraint(equalTo: bottomDescriptionView.widthAnchor, multiplier: 0.7).isActive = true
        
        }
}
