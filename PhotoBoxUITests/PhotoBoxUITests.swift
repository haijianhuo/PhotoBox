//
//  PhotoBoxUITests.swift
//  PhotoBoxUITests
//
//  Created by Haijian Huo on 3/30/17.
//  Copyright © 2017 Haijian Huo. All rights reserved.
//

import XCTest

class PhotoBoxUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let app = XCUIApplication()
        app.navigationBars["Cloud Photos"].buttons["Add"].tap()
        app.collectionViews.children(matching: .cell).matching(identifier: "Photo").element(boundBy: 0).tap()
        app.buttons["Upload"].tap()
        sleep(2)
        
        app.collectionViews.children(matching: .cell).element(boundBy: 0).children(matching: .other).element.tap()
        
        let scrollView = app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .scrollView).element
        scrollView.tap()
        app.otherElements.containing(.navigationBar, identifier:"Cloud Photos").children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .image).element.tap()
        scrollView.tap()
        sleep(2)
        
        app.navigationBars["Cloud Photos"].buttons["Delete"].tap()
        app.children(matching: .window).element(boundBy: 0).children(matching: .other).element(boundBy: 1).buttons["Delete"].tap()
        sleep(2)
        
        XCUIDevice.shared.orientation = .portrait
        XCUIDevice.shared.orientation = .landscapeLeft
        
        app.collectionViews.children(matching: .cell).element(boundBy: 1).children(matching: .other).element.tap()
        
        scrollView.tap()
        
        let element = app.otherElements.containing(.navigationBar, identifier:"Cloud Photos").children(matching: .other).element.children(matching: .other).element.children(matching: .other).element
        element.children(matching: .image).element.tap()
        scrollView.tap()
        
        let collectionView = element.children(matching: .collectionView).element
        collectionView.swipeDown()
        sleep(2)
        XCUIDevice.shared.orientation = .portrait
        collectionView.swipeDown()
        sleep(2)

        
    }

}
