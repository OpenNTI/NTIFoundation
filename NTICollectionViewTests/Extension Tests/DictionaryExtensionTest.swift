//
//  DictionaryExtensionTest.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 3/17/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import XCTest

class DictionaryExtensionTest: XCTestCase {
	
	let testDict = [
		"a": [1, 2],
		"c": [4]
	]
	
	var dict: [String: [Int]] = [:]
    
    override func setUp() {
        super.setUp()
        dict = testDict
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testAppendToExisting() {
		dict.append(3, to: "a")
		let expected = [1, 2, 3]
		XCTAssert(dict["a"] ?? [] == expected, "Incorrect result appending item to existing container: expected \(expected) but found \(dict["a"])")
    }
	
	func testAppendToNew() {
		dict.append(0, to: "b")
		let expected = [0]
		XCTAssert(dict["b"] ?? [] == expected, "Incorrect result appending item to new container: expected \(expected) but found \(dict["b"])")
	}
	
	func testAppendContentsOfToExisting() {
		dict.appendContentsOf([3, 4], to: "a")
		let expected = [1, 2, 3, 4]
		XCTAssert(dict["a"] ?? [] == expected, "Incorrect result appending contents to existing container: expected \(expected) but found \(dict["a"])")
	}
	
	func testAppendContentsOfToNew() {
		dict.appendContentsOf([0, 1], to: "b")
		let expected = [0, 1]
		XCTAssert(dict["b"] ?? [] == expected, "Incorrect result appending contents to new container: expected \(expected) but found \(dict["b"])")
	}
	
	func testAppendContentsOfEmptyToNew() {
		dict.appendContentsOf([], to: "b")
		let expected: [Int] = []
		XCTAssert(dict["b"] ?? [-1] == expected, "Incorrect result appending contents to new container: expected \(expected) but found \(dict["b"])")
	}
	
	func testAppendContentsOf() {
		dict.appendContents(of: ["a": [3, 4], "b": [0]])
		let expected = ["a": [1, 2, 3, 4], "b": [0], "c": [4]]
		let aIsCorrect = dict["a"] ?? [] == expected["a"] ?? [-1]
		let bIsCorrect = dict["b"] ?? [] == expected["b"] ?? [-1]
		let cIsCorrect = dict["c"] ?? [] == expected["c"] ?? [-1]
		XCTAssert(aIsCorrect && bIsCorrect && cIsCorrect, "Incorrect result appending contents of dictionary: expected \(expected) but found \(dict)")
	}
    
}
