//
//  TSAOTests.swift
//  TSAOTests
//
//  Created by Kevin Ballard on 11/30/15.
//  Copyright © 2015 Kevin Ballard. All rights reserved.
//

import XCTest
@testable import TSAO

let intMap = AssocMap<Int>()
let strMap = AssocMap<NSString>(copyAtomic: false)
let aryMap = AssocMap<[String]>()
let tupleMap = AssocMap<(Int, CGRect)>()

let objectRetainMap = AssocMap<NSObject>()
let objectAssignMap = AssocMap<NSObject>(assign: ())

class TSAOTests: XCTestCase {
    var helper: NSObject!
    
    override func setUp() {
        super.setUp()
        helper = NSObject()
    }
    
    override func tearDown() {
        helper = nil
        super.tearDown()
    }
    
    func testSettingAssociatedObjects() {
        intMap[helper] = 42
        strMap[helper] = "this is an NSString"
        aryMap[helper] = ["array", "of", "String", "values"]
        
        XCTAssertEqual(intMap[helper], 42)
        XCTAssertEqual(strMap[helper], "this is an NSString")
        XCTAssertEqual(aryMap[helper] ?? [], ["array", "of", "String", "values"])
    }
    
    func testUnbridgeableValue() {
        let rect = CGRect(x: 5, y: 10, width: 15, height: 20)
        tupleMap[helper] = (5, rect)
        if let value = tupleMap[helper] {
            XCTAssertEqual(value.0, 5)
            XCTAssertEqual(value.1, rect)
        } else {
            XCTFail("tupleMap[helper] returned nil")
        }
    }
    
    func testOverwritingAssociatedObjects() {
        intMap[helper] = 42
        XCTAssertEqual(intMap[helper], 42)
        intMap[helper] = 1
        XCTAssertEqual(intMap[helper], 1)
        intMap[helper] = nil
        XCTAssertNil(intMap[helper])
    }
    
    func testGettingUnsetAssociatedObject() {
        XCTAssertNil(intMap[helper])
        intMap[helper] = 42
        XCTAssertEqual(intMap[helper], 42)
        intMap[helper] = nil
        XCTAssertNil(intMap[helper])
    }
    
    func testCopyingAssociatedValue() {
        let s = NSMutableString(string: "mutable string")
        strMap[helper] = s
        s.appendString("was changed")
        XCTAssertEqual(strMap[helper], "mutable string")
    }
    
    func testReleaseValue() {
        weak var object: NSObject?
        autoreleasepool {
            let obj = NSObject()
            objectRetainMap[helper] = obj
            object = obj
        }
        autoreleasepool {
            XCTAssertNotNil(object)
        }
        autoreleasepool {
            objectRetainMap[helper] = nil
        }
        XCTAssertNil(object)
    }
    
    func testAssignValue() {
        weak var object: NSObject?
        autoreleasepool {
            let obj = NSObject()
            objectAssignMap[helper] = obj
            object = obj
        }
        XCTAssertNil(object)
    }
}
