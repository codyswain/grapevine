//
//  UITest.swift
//  Grapevine-130UITests
//
//  Created by Ning Hu on 2/20/20.
//  Copyright © 2020 Anthony Humay. All rights reserved.
//

import XCTest

class UITest: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testMainScreen() {
        let app = XCUIApplication()
        
        XCTAssert(app.staticTexts["Posts Near You"].exists)
        XCTAssert(app.buttons["postsRange"].exists)
        XCTAssert(app.staticTexts[" Points"].exists)
        XCTAssert(app.buttons[" Add Post"].exists)
    }
    
    func testNewPostScreen() {
        let app = XCUIApplication()
        
        app.buttons[" Add Post"].tap()
        
        XCTAssert(app.staticTexts["Add New Post"].exists)
        XCTAssert(app.staticTexts["newPostVisibility"].exists)
        XCTAssert(app.buttons[" Text"].exists)
        XCTAssert(app.textViews.element.exists)
        XCTAssert(app.buttons[" Draw"].exists)
        XCTAssert(app.buttons[" Back"].exists)
        XCTAssert(app.buttons["Add"].exists)
        XCTAssertFalse(app.buttons[" Clear"].exists)
        
        app.buttons[" Draw"].tap()
        XCTAssert(app.otherElements["newPostCanvas"].exists)
        XCTAssert(app.buttons[" Draw"].exists)
        XCTAssert(app.buttons[" Back"].exists)
        XCTAssert(app.buttons["Add"].exists)
        XCTAssert(app.buttons[" Text"].exists)
        XCTAssert(app.buttons[" Clear"].exists)
    }
    
    func testTextPost() {
        let app = XCUIApplication()
        
        app.buttons[" Add Post"].tap()
        app.textViews["newPostTextView"].tap()
        app.keys["H"].tap()
        app.keys["i"].tap()
        app.buttons["Add"].tap()
        
        // Automatic swipe down. Apple's is too gentle.
        sleep(5)
        let firstCell = app.tables.element(boundBy: 0)
        let start = firstCell.coordinate(withNormalizedOffset: (CGVector(dx: 0, dy: 0)))
        let finish = firstCell.coordinate(withNormalizedOffset: (CGVector(dx: 0, dy: 2)))
        start.press(forDuration: 0.1, thenDragTo: finish)
        
        XCUIApplication().tables.cells["Hi, 0"].waitForExistence(timeout: 10)
        XCTAssert(XCUIApplication().tables.cells["Hi, 0"].exists)
        XCTAssert(XCUIApplication().tables.cells["Hi, 0"].images["arrowtriangle.down.circle.fill"].exists)
        XCTAssert(XCUIApplication().tables.cells["Hi, 0"].images["arrowtriangle.up.circle.fill"].exists)
        XCTAssert(XCUIApplication().tables.cells["Hi, 0"].images["flag.circle.fill"].exists)
        
        // Verify that post changes on downvote
        // - Downvoting changes post score by -1
        // - Flag button is still visible
        // - Upvote button is no longer visible
        XCUIApplication().tables.cells["Hi, 0"].images["arrowtriangle.down.circle.fill"].tap()
        XCTAssert(XCUIApplication().tables.cells["Hi, -1"].exists)
        XCTAssert(XCUIApplication().tables.cells["Hi, -1"].images["flag.circle.fill"].exists)
        XCTAssertFalse(XCUIApplication().tables.cells["Hi, 0"].images["arrowtriangle.up.circle.fill"].exists)
        
        // Verify that retapping downvote restores visibility of all
        XCUIApplication().tables.cells["Hi, -1"].images["arrowtriangle.down.circle.fill"].tap()
        XCTAssert(XCUIApplication().tables.cells["Hi, 0"].exists)
        XCTAssert(XCUIApplication().tables.cells["Hi, 0"].images["arrowtriangle.down.circle.fill"].exists)
        XCTAssert(XCUIApplication().tables.cells["Hi, 0"].images["arrowtriangle.up.circle.fill"].exists)
        XCTAssert(XCUIApplication().tables.cells["Hi, 0"].images["flag.circle.fill"].exists)
        
        // Verify that post changes on upvote
        // - Upvoting changes post score by +1
        // - Flag button is still visible
        // - Downvote button is no longer visible
        XCUIApplication().tables.cells["Hi, 0"].images["arrowtriangle.up.circle.fill"].tap()
        XCTAssert(XCUIApplication().tables.cells["Hi, 1"].exists)
        XCTAssertFalse(XCUIApplication().tables.cells["Hi, 0"].images["arrowtriangle.down.circle.fill"].exists)
        XCTAssert(XCUIApplication().tables.cells["Hi, 1"].images["flag.circle.fill"].exists)
        
        // Verify that retapping upvote restores visibility of all
        XCUIApplication().tables.cells["Hi, 1"].images["arrowtriangle.up.circle.fill"].tap()
        XCTAssert(XCUIApplication().tables.cells["Hi, 0"].exists)
        XCTAssert(XCUIApplication().tables.cells["Hi, 0"].images["arrowtriangle.down.circle.fill"].exists)
        XCTAssert(XCUIApplication().tables.cells["Hi, 0"].images["arrowtriangle.up.circle.fill"].exists)
        XCTAssert(XCUIApplication().tables.cells["Hi, 0"].images["flag.circle.fill"].exists)

        // Delete the new post and verify that it has been deleted.
        XCTAssert(XCUIApplication().tables.cells["Hi, 0"].images["Close"].exists)
        XCUIApplication().tables.cells["Hi, 0"].images["Close"].tap()
        XCTAssertFalse(XCUIApplication().tables.cells["Hi, 0"].exists)
    }
    
    func testScoreScreen() {
        let app = XCUIApplication()
        
        app.buttons[" Points"].tap()
        
        XCTAssert(app.staticTexts["My Points"].exists)
        XCTAssert(app.staticTexts[" Use Points"].exists)
        XCTAssert(app.buttons["info.circle"].exists)
        XCTAssert(app.staticTexts["scoreEmoji"].exists)
        XCTAssert(app.staticTexts["scorePoints"].exists)
        XCTAssert(app.staticTexts["scoreStrikes"].exists)
        
        app.swipeDown()
        XCTAssert(app.staticTexts["Posts Near You"].exists)
    }
    
    func testScoreInfo() {
        let app = XCUIApplication()
        
        app.buttons[" Points"].tap()
        app.buttons["info.circle"].tap()
        
        XCTAssert(app.staticTexts[" More Info"].exists)
        XCTAssert(app.staticTexts["Strikes & Bans"].exists)
        XCTAssert(app.staticTexts["Points"].exists)
        
        app.swipeDown()
        XCTAssert(app.staticTexts["My Points"].exists)
    }
    
    func testScoreUsePoints() {
        let app = XCUIApplication()
        
        app.buttons[" Points"].tap()
        app.staticTexts[" Use Points"].tap()
        
        let elementsQuery = app.alerts["Spend Points"]
        XCTAssert(elementsQuery.exists)
        
        elementsQuery.tap()
        XCTAssert(elementsQuery.buttons["Enter Ban Chamber (20 Points)"].exists)
        XCTAssert(elementsQuery.buttons["Cancel"].exists)
    }

}
