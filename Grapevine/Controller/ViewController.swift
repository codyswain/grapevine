//
//  ViewController.swift
//  Grapevine
//
//  Created by Cody Swain on 1/8/20.
//  Copyright © 2020 Grapevine. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseFirestore

class ViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    var posts: [Post] = [
        Post(content:"God, North Campus is so much nicer than South Campus it’s crazy. Should’ve been an English major.", upvotes:5, downvotes:0),
        Post(content:"If you’re sitting near me, I am so sorry. Shrimp burrito is doing me dirty, Rubio’s had a special", upvotes:3, downvotes:0),
        Post(content:"Why does this school not have any pencil sharpeners? It’s actually kinda impressive", upvotes:3, downvotes:0),
        Post(content:"Best libraries: Rosenfeld > YRL > Powell > PAB > Engineering. Fight me. ", upvotes:3, downvotes:0),
        Post(content:"The Lakers are not the real deal. Clippers gonna be champs of the west mark my words baby", upvotes:3, downvotes:0)
        
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        loadPosts()
//        let db = Firestore.firestore()
        tableView.register(UINib(nibName: Constants.cellNibName, bundle: nil), forCellReuseIdentifier: Constants.cellIdentifier)
        tableView.rowHeight = 160
        tableView.backgroundColor = UIColor.white
    }
    
    // Make top information (time, battery, signal) dark
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }
    
    func loadPosts(){
            
    }

}

extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier, for: indexPath) as! PostTableViewCell
        cell.label.text = posts[indexPath.row].content
        cell.label.textColor = UIColor.black // Set the color of the text
        cell.backgroundColor = UIColor.white

        return cell
    }
}
