//
//  GridLayoutSectionBuilderTest.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 6/16/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import XCTest

class GridLayoutSectionBuilderTest: XCTestCase {
    
	func testMakeLayoutSection() {
		var metrics = GridSectionMetrics()
		metrics.numberOfColumns = 3
		metrics.rowHeight = 20
		metrics.padding = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
		
		var description = SectionDescription(metrics: metrics)
		description.numberOfItems = 9
		description.sectionIndex = 0
		
		let builder = GridLayoutSectionBuilder()
		
		let origin = CGPoint(x: 10, y: 10)
		let width: CGFloat = 100
		let bounds = LayoutAreaBounds(origin: origin, width: width)
		
		guard let section = builder.makeLayoutSection(using: description, in: bounds) as? GridLayoutSection else {
			XCTFail("Expected an instance of GridLayoutSection")
			return
		}
		
		let expectedSectionSize = CGSize(width: width, height: 70)
		let expectedSectionFrame = CGRect(origin: origin, size: expectedSectionSize)
		XCTAssert(section.frame == expectedSectionFrame, "Incorect section frame: expected \(expectedSectionFrame) but found \(section.frame)")
		
		let expectedRowCount = 3
		XCTAssert(section.rows.count == expectedRowCount, "Incorrect row count: expected \(expectedRowCount) but found \(section.rows.count)")
	}
		
}
