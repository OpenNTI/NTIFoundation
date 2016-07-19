//
//  SectionMetricsTest.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 3/10/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import XCTest
import NTICollectionView

class SectionMetricsTest: XCTestCase {
    
	func testApplyValuesFromGridSectionMetrics() {
		var metrics1 = GridSectionMetrics()
		metrics1.rowHeight = 42
		metrics1.estimatedRowHeight = 42
		metrics1.numberOfColumns = 2
		
		var metrics2 = GridSectionMetrics()
		metrics2.rowHeight = 31.4
		metrics2.showsSectionSeparator = true
		
		metrics1.applyValues(from: metrics2)
		
		XCTAssert(metrics1.rowHeight == 31.4, "Incorrect rowHeight: expected \(31.4)")
		XCTAssert(metrics1.estimatedRowHeight == 42, "Incorrect estimatedRowHeight: expected \(42)")
		XCTAssert(metrics1.numberOfColumns == 2, "Incorrect numberOfColumns: expected \(2)")
		XCTAssert(metrics1.showsSectionSeparator == true, "Incorrect showsSectionSeparator: expected \(true)")
	}
	
}
