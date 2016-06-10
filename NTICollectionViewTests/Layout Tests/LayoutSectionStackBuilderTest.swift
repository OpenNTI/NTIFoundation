//
//  LayoutSectionStackBuilderTest.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 6/9/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import XCTest

class LayoutSectionStackBuilderTest: XCTestCase {
    
	func testMakeLayoutSection() {
		let inset = UIEdgeInsets(uniformInset: 5)
		var metrics = BasicSectionMetrics()
		metrics.contentInset = inset
		
		let sectionCount = 2
		
		let descriptions: [SectionDescription] = (0..<sectionCount).map { (sectionIndex) in
			var desc = SectionDescription(metrics: metrics)
			desc.sectionIndex = sectionIndex
			return desc
		}
		
		let sectionBuilder = MockLayoutSectionBuilder()
		
		let origin = CGPoint(x: 5, y: 5)
		let width: CGFloat = 100
		let bounds = LayoutAreaBounds(origin: origin, width: width)
		
		let builder = LayoutSectionStackBuilder()
		
		let sections = builder.makeLayoutSections(with: descriptions, using: sectionBuilder, in: bounds)
		
		XCTAssertEqual(sections.count, sectionCount, "Incorrect number of sections created")
		
		let expectedX = origin.x + inset.left
		let expectedW = width - inset.width
		let expectedH = sectionBuilder.sectionHeight
		
		let expectedFrame0 = CGRect(x: expectedX, y: origin.y + inset.top, width: expectedW, height: expectedH)
		XCTAssertEqual(sections[0].frame, expectedFrame0, "Incorrect frame for section 0")
		
		let expectedFrame1 = CGRect(x: expectedX, y: expectedFrame0.maxY + inset.height, width: expectedW, height: expectedH)
		XCTAssertEqual(expectedFrame1, sections[1].frame, "Incorrect frame for section 1")
	}
	
}

struct MockLayoutSectionBuilder : LayoutSectionBuilder {
	
	var sectionHeight: CGFloat = 100
	
	func makeLayoutSection(using description: SectionDescription, in layoutBounds: LayoutAreaBounds) -> LayoutSection {
		var section = BasicLayoutSection(metrics: description.metrics)
		let size = CGSize(width: layoutBounds.width, height: sectionHeight)
		section.frame = CGRect(origin: layoutBounds.origin, size: size)
		return section
	}
	
}
