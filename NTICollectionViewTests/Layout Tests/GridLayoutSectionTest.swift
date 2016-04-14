//
//  GridLayoutSectionTest.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/18/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import XCTest
import UIKit

class GridLayoutSectionTest: XCTestCase {
	
	var layoutInfo: DummyLayoutInfo!
	
	var layoutSection: BasicGridLayoutSection!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
		layoutInfo = DummyLayoutInfo()
		layoutSection = BasicGridLayoutSection()
		layoutSection.layoutInfo = layoutInfo
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
		layoutInfo = nil
		layoutSection = nil
    }
	
	func testLayout1() {
		/*
		Before
		items: 15 instances of GridLayoutItem each with frame (0, 0, 375, 44)
		frame: (0, 0, 0, 0)
		*/
		let width: CGFloat = 375
		let y_0: CGFloat = 50.5
		let h: CGFloat = 50
		let endY: CGFloat = 757.5
		let start = CGPointZero
		let itemCount = 15
		
		let measure = DummyLayoutMeasure()
		measure.itemSize = CGSize(width: 0, height: 50)
		layoutInfo.layoutMeasure = measure
		layoutInfo.width = width
		
		layoutSection.metrics.showsRowSeparator = true
		
		for _ in 0..<itemCount {
			var item = GridLayoutItem()
			item.frame = CGRect(x: 0, y: 0, width: 375, height: 44)
			item.hasEstimatedHeight = true
			layoutSection.add(item)
		}
		
		/*
		After
		rows: 15 instances of BasicGridLayoutRow with respective items with same frames except heights at 50.5
		items: Same but y-coordinates at 50.5 * i, heights at 50
		frame: (0, 0, 375, 757.5)
		*/
		
		let end = layoutSection.layoutWithOrigin(start, layoutSizing: layoutInfo)
		
		XCTAssertEqual(layoutSection.rows.count, itemCount)
		
		for i in 0..<itemCount {
			let row = layoutSection.rows[i]
			let item = layoutSection.items[i]
			XCTAssertEqual(row.items.count, 1)
			XCTAssert(row.items[0].isEqual(to: item), "Row \(i) does not contain correct item")
			XCTAssert(item.row!.isEqual(to: row), "Item \(i) does not reference correct row")
			
			let y: CGFloat = y_0 * CGFloat(i)
			let itemFrame = item.frame
			XCTAssertEqual(itemFrame, CGRect(x: 0, y: y, width: width, height: h))
			
			XCTAssertEqual(row.frame, CGRect(x: itemFrame.origin.x, y: itemFrame.origin.y, width: itemFrame.width, height: y_0))
		}
		
		XCTAssertEqual(layoutSection.frame, CGRect(x: 0, y: 0, width: width, height: endY))
		
		// Return: 757.5
		XCTAssertEqual(end.y, 757.5)
	}
	
}


