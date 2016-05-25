//
//  TableLayoutSectionBuilderTest.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 5/24/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import XCTest
import UIKit

class TableLayoutSectionBuilderTest: XCTestCase {
    
	func testMakeLayoutSection() {
		var metrics = TableSectionMetrics()
		metrics.numberOfColumns = 3
		metrics.rowHeight = 20
		metrics.layoutMargins = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
		
		var description = SectionDescription(metrics: metrics)
		description.numberOfItems = 9
		description.sectionIndex = 0
		
		guard let builder = TableLayoutSectionBuilder(metrics: metrics) else {
			XCTFail("Expected a non-nil builder")
			return
		}
		
		let origin = CGPoint(x: 10, y: 10)
		let width: CGFloat = 100
		let bounds = LayoutAreaBounds(origin: origin, width: width)
		
		guard let section = builder.makeLayoutSection(using: description, in: bounds) as? TableLayoutSection else {
			XCTFail("Expected an instance of TableLayoutSection")
			return
		}
		
		let expectedSectionSize = CGSize(width: width, height: 70)
		let expectedSectionFrame = CGRect(origin: origin, size: expectedSectionSize)
		XCTAssert(section.frame == expectedSectionFrame, "Incorect section frame: expected \(expectedSectionFrame) but found \(section.frame)")
		
		let expectedRowCount = 3
		XCTAssert(section.rows.count == expectedRowCount, "Incorrect row count: expected \(expectedRowCount) but found \(section.rows.count)")
	}
		
}
