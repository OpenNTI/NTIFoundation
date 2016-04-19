//
//  GridSectionColumnLayoutEngineTest.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 3/10/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import XCTest

class GridSectionColumnLayoutEngineTest: XCTestCase {
    
	func testLayout() {
		var section = BasicGridLayoutSection()
		
		let measure = DummyLayoutMeasure()
		measure.supplementaryItemSize = CGSize(width: 20, height: 20)
		
		let sizing = LayoutSizingInfo(width: 20, layoutMeasure: measure)
		
		let kind = UICollectionElementKindSectionHeader
		
		func makeItem() -> LayoutSupplementaryItem {
			var item = GridSupplementaryItem(elementKind: kind)
			item.supplementaryViewClass = CollectionSupplementaryView.self
			item.isVisibleWhileShowingPlaceholder = true
			return GridLayoutSupplementaryItem(supplementaryItem: item)
		}
		
		var item1 = makeItem()
		item1.shouldPin = true
		var item2 = makeItem()
		var item3 = makeItem()
		
		section.add(item1)
		section.add(item2)
		section.add(item3)
		
		let origin = CGPoint(x: 5, y: 5)
		
		let engine = GridSectionColumnLayoutEngine(layoutSection: section, supplementaryItems: [item1, item2, item3])
		
		let endPoint = engine.layoutWithOrigin(origin, layoutSizing: sizing, invalidationContext: nil)
		
		XCTAssert(endPoint == CGPoint(x: 25, y: 65), "Incorrect endPoint: \(endPoint)")
		
		item1 = engine.supplementaryItems[0]
		item2 = engine.supplementaryItems[1]
		item3 = engine.supplementaryItems[2]
		
		var expectedFrame = CGRect(x: 5, y: 5, width: 20, height: 20)
		XCTAssert(item1.frame == expectedFrame, "Incorrect frame for item1: expected \(expectedFrame) but found \(item1.frame)")
		expectedFrame.origin.y += 20
		XCTAssert(item2.frame == expectedFrame, "Incorrect frame for item2: expected \(expectedFrame) but found \(item2.frame)")
		expectedFrame.origin.y += 20
		XCTAssert(item3.frame == expectedFrame, "Incorrect frame for item3: expected \(expectedFrame) but found \(item3.frame)")
		
		XCTAssert(engine.pinnableHeaders[0].isEqual(to: item1), "Expect pinnableHeaders to contain item1 at index 0")
		
		XCTAssert(engine.nonPinnableHeaders[0].isEqual(to: item2), "Expect nonPinnableHeaders to contain item2 at index 0")
		XCTAssert(engine.nonPinnableHeaders[1].isEqual(to: item3), "Expect nonPinnableHeaders to contain item3 at index 1")
	}
	
}
