//
//  NotificationManager.swift
//  Grapevine-130
//
//  Created by Cody Swain on 11/13/20.
//  Copyright © 2020 Cody Swain. All rights reserved.
//

import Foundation

protocol ActivityManagerDelegate {
    func didUpdateActivities(activities: [Activity])
}

struct ActivityManager {
    var delegate: ActivityManagerDelegate?
    
    var test_activities: [Activity] = [
        Activity(title: "test1", body: "body1"),
        Activity(title: "test2", body: "body2")
    ]
    
    func fetchTestActivities(){
        self.delegate?.didUpdateActivities(activities: test_activities)
    }
}
