//
//  ViewController.swift
//  Grapevine
//
//  Created by Cody Swain on 1/8/20.
//  Copyright © 2020 Grapevine. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    var posts: [Post] = [
        Post(content:"Hi Cody", upvotes:5, downvotes:0),
        Post(content:"Jason is a tank", upvotes:3, downvotes:0)
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        // Do any additional setup after loading the view.
    }


}

extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier, for: indexPath)
        cell.textLabel?.text = posts[indexPath.row].content

        return cell
    }
}
