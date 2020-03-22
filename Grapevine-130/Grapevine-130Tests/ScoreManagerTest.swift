//
//  ScoreManagerTest.swift
//  Grapevine-130Tests
//
//  Created by Ning Hu on 2/20/20.
//  Copyright © 2020 Anthony Humay. All rights reserved.
//

import XCTest

class ScoreManagerTest: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testGetEmoji() {
        let scoreManager = ScoreManager()
        
        for n in -50...100 {
            if (n <= -10){
                XCTAssertEqual(scoreManager.getEmoji(score: n), "😭")
            } else if (n <= -5){
                XCTAssertEqual(scoreManager.getEmoji(score: n), "😢")
            } else if (n <= 0){
                XCTAssertEqual(scoreManager.getEmoji(score: n), "🥱")
            } else if (n <= 1){
                XCTAssertEqual(scoreManager.getEmoji(score: n), "😮")
            } else if (n <= 5){
                XCTAssertEqual(scoreManager.getEmoji(score: n), "😤")
            } else if (n <= 10){
                XCTAssertEqual(scoreManager.getEmoji(score: n), "🤩")
            } else if (n <= 25){
                XCTAssertEqual(scoreManager.getEmoji(score: n), "😱")
            } else if (n <= 50){
                XCTAssertEqual(scoreManager.getEmoji(score: n), "🤯")
            } else {
                XCTAssertEqual(scoreManager.getEmoji(score: n), "👑")
            }
        }
    }
    
    func testGetStrikeMessage() {
        let scoreManager = ScoreManager()
        
        for n in -1...5 {
            if n <= 0 {
                XCTAssertEqual(scoreManager.getStrikeMessage(strikes: n), "Strikes Left: 3/3")
            } else if n == 1 {
                XCTAssertEqual(scoreManager.getStrikeMessage(strikes: n), "Strikes Left: 2/3")
            } else if n == 2 {
                XCTAssertEqual(scoreManager.getStrikeMessage(strikes: n), "Strikes Left: 1/3")
            } else {
                XCTAssertEqual(scoreManager.getStrikeMessage(strikes: n), "Strikes Left: 0/3")
            }
        }
    }

}
