//
//  TSAOTests.swift
//  TSAOTests
//
//  Created by Kevin Ballard on 11/30/15.
//  Copyright © 2015 Kevin Ballard. All rights reserved.
//

import XCTest
@testable import TSAO

let intKey = AssocKey<Int>()
let strKey = AssocKey<NSString>(copyAtomic: false)
let aryKey = AssocKey<[String]>()
let tupleKey = AssocKey<(Int, CGRect)>()

let objectRetainKey = AssocKey<NSObject>()
let objectAssignKey = AssocKey<NSObject>(assign: ())

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
        associatedObjects(helper).set(intKey, value: 42)
        associatedObjects(helper).set(strKey, value: "this is an NSString")
        associatedObjects(helper).set(aryKey, value: ["array", "of", "String", "values"])
        
        XCTAssertEqual(associatedObjects(helper).get(intKey), 42)
        XCTAssertEqual(associatedObjects(helper).get(strKey), "this is an NSString")
        XCTAssertEqual(associatedObjects(helper).get(aryKey) ?? [], ["array", "of", "String", "values"])
    }
    
    func testUnbridgeableValue() {
        let rect = CGRect(x: 5, y: 10, width: 15, height: 20)
        associatedObjects(helper).set(tupleKey, value: (5, rect))
        if let value = associatedObjects(helper).get(tupleKey) {
            XCTAssertEqual(value.0, 5)
            XCTAssertEqual(value.1, rect)
        } else {
            XCTFail("associatedObjects(helper).get(tupleKey) returned nil")
        }
    }
    
    func testOverwritingAssociatedObjects() {
        associatedObjects(helper).set(intKey, value: 42)
        XCTAssertEqual(associatedObjects(helper).get(intKey), 42)
        associatedObjects(helper).set(intKey, value: 1)
        XCTAssertEqual(associatedObjects(helper).get(intKey), 1)
        associatedObjects(helper).set(intKey, value: nil)
        XCTAssertNil(associatedObjects(helper).get(intKey))
    }
    
    func testGettingUnsetAssociatedObject() {
        XCTAssertNil(associatedObjects(helper).get(intKey))
        associatedObjects(helper).set(intKey, value: 42)
        XCTAssertEqual(associatedObjects(helper).get(intKey), 42)
        associatedObjects(helper).set(intKey, value: nil)
        XCTAssertNil(associatedObjects(helper).get(intKey))
    }
    
    func testCopyingAssociatedValue() {
        let s = NSMutableString(string: "mutable string")
        associatedObjects(helper).set(strKey, value: s)
        s.appendString("was changed")
        XCTAssertEqual(associatedObjects(helper).get(strKey), "mutable string")
    }
    
    func testReleaseValue() {
        weak var object: NSObject?
        autoreleasepool {
            let obj = NSObject()
            associatedObjects(helper).set(objectRetainKey, value: obj)
            object = obj
        }
        autoreleasepool {
            XCTAssertNotNil(object)
        }
        autoreleasepool {
            associatedObjects(helper).set(objectRetainKey, value: nil)
        }
        XCTAssertNil(object)
    }
    
    func testAssignValue() {
        weak var object: NSObject?
        autoreleasepool {
            let obj = NSObject()
            associatedObjects(helper).set(objectAssignKey, value: obj)
            object = obj
        }
        XCTAssertNil(object)
    }
}
