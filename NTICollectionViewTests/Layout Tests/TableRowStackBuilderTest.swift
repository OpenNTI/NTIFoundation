//
//  TableRowStackBuilderTest.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 5/25/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import XCTest

class TableRowStackBuilderTest: XCTestCase {
    
	func testMakeLayoutRows() {
		let rowHeight: CGFloat = 20
		var metrics = TableSectionMetrics()
		metrics.numberOfColumns = 2
		metrics.rowHeight = 20
		
		var description = SectionDescription(metrics: metrics)
		description.numberOfItems = 3
		description.sectionIndex = 0
		description.metrics = metrics
		
		let origin = CGPoint(x: 10, y: 10)
		let width: CGFloat = 40
		let bounds = LayoutAreaBounds(origin: origin, width: width)
		
		let expectedColumnWidth = width / CGFloat(metrics.numberOfColumns)
		
		let builder = TableRowStackBuilder()
		
		let rows = builder.makeLayoutRows(using: description, in: bounds)
		
		XCTAssert(rows.count == 2, "Incorrect number of rows: expected \(2) but found \(rows.count)")
		
		do {
			let idx = 0, row = rows[idx]
			
			XCTAssert(row.items.count == 2, "Incorrect number of items in row \(idx): expected \(2) but found \(row.items.count)")
			
			let expectedFrame = CGRect(x: origin.x, y: origin.y, width: bounds.width, height: rowHeight)
			XCTAssert(row.frame == expectedFrame, "Incorrect frame for row \(idx): expected \(expectedFrame) but found \(row.frame)")
			
			let item0 = row.items[0]
			let expectedItem0Frame = CGRect(x: origin.x, y: origin.y, width: expectedColumnWidth, height: rowHeight)
			XCTAssert(item0.frame == expectedItem0Frame, "Incorrect frame for item 0: expected \(expectedItem0Frame) but found \(item0.frame)")
			
			let item1 = row.items[1]
			let expectedItem1Frame = CGRect(x: origin.x + expectedColumnWidth, y: origin.y, width: expectedColumnWidth, height: rowHeight)
			XCTAssert(item1.frame == expectedItem1Frame, "Incorrect frame for item 1: expected \(expectedItem1Frame) but found \(item1.frame)")
		}
		
		do {
			let idx = 1, row = rows[idx]
			
			XCTAssert(row.items.count == 1, "Incorrect number of items in row \(idx): expected \(1) but found \(row.items.count)")
			
			let expectedFrame = CGRect(x: origin.x, y: origin.y + metrics.rowHeight!, width: bounds.width, height: metrics.rowHeight!)
			XCTAssert(row.frame == expectedFrame, "Incorrect frame for row \(idx): expected \(expectedFrame) but found \(row.frame)")
			
			let item0 = row.items[0]
			let expectedItem0Frame = CGRect(x: origin.x, y: origin.y + rowHeight, width: expectedColumnWidth, height: rowHeight)
			XCTAssert(item0.frame == expectedItem0Frame, "Incorrect frame for item 0: expected \(expectedItem0Frame) but found \(item0.frame)")
		}
	}
		
}
