//
//  GridSupplementaryItemLayoutEngineTest.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 3/10/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import XCTest

class GridSupplementaryItemLayoutEngineTest: XCTestCase {
    
	func testLayout() {
		// H:|-(iL)-[headers]-(iR)-|
		// H:|-(iL)-[leftAux(20)]-(pL)-[inner]-(pR)-[rightAux(20)]-(iR)-|
		// H:|-(iL)-[footers]-(iR)-|
		// V:|-(iT)-[headers]-(pT)-[content]-(pB)-[footers]-(iB)-|
		// V:[headers][leftAux]-(>=0)-[footers]
		// V:[headers][rightAux]-(>=0)-[footers]
		let section = BasicGridLayoutSection()
		section.metrics.contentInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
		section.metrics.leftAuxiliaryColumnWidth = 20
		section.metrics.rightAuxiliaryColumnWidth = 20
		section.metrics.padding = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
		
		let headers = makeItems(of: UICollectionElementKindSectionHeader, count: 1)
		let footers = makeItems(of: UICollectionElementKindSectionFooter, count: 1)
		let leftAuxiliaryItems = makeItems(of: collectionElementKindLeftAuxiliaryItem, count: 2)
		let rightAuxiliaryItems = makeItems(of: collectionElementKindRightAuxiliaryItem, count: 3)
		for items in [headers, footers, leftAuxiliaryItems, rightAuxiliaryItems] {
			for item in items {
				section.add(item)
			}
		}
		
		let innerEngine = MockLayoutEngine(mockHeight: 50)
		
		let engine = GridSupplementaryItemLayoutEngine(layoutSection: section, innerLayoutEngine: innerEngine)
		engine.factory = { (LayoutSection: LayoutSection, supplementaryItems: [LayoutSupplementaryItem]) -> SupplementaryLayoutEngine in
			return MockSupplementaryLayoutEngine(supplementaryItems: supplementaryItems)
		}
		
		let origin = CGPoint(x: 5, y: 5)
		let measure = DummyLayoutMeasure()
		measure.supplementaryItemSize = CGSize(width: 20, height: 20)
		let sizing = LayoutSizingInfo(width: 100, layoutMeasure: measure)
		
		let endPoint = engine.layoutWithOrigin(origin, layoutSizing: sizing)
		// x: 5 + 100
		// y: 5 + 10 + 20 + 5 + 50 + 5 + 20 + 10
		let expectedPoint = CGPoint(x: 105, y: 125)
		XCTAssert(endPoint == expectedPoint, "Incorrect endPoint: \(endPoint)")
		
		for item in headers {
			let expectedWidth: CGFloat = 80
			let headerWidth = item.frame.width
			XCTAssert(headerWidth == expectedWidth, "Incorrect header width: \(headerWidth)")
			
			let expectedOrigin = CGPoint(x: 15, y: 15)
			let headerOrigin = item.frame.origin
			XCTAssert(headerOrigin == expectedOrigin, "Incorrect header origin: \(headerOrigin)")
		}
		
		for item in footers {
			let expectedWidth: CGFloat = 80
			let footerWidth = item.frame.width
			XCTAssert(footerWidth == expectedWidth, "Incorrect footer width: \(footerWidth)")
			
			let expectedOrigin = CGPoint(x: 15, y: 95)
			let footerOrigin = item.frame.origin
			XCTAssert(footerOrigin == expectedOrigin, "Incorrect footer origin: \(footerOrigin)")
		}
		
		for item in leftAuxiliaryItems {
			let expectedX: CGFloat = 15
			let itemX = item.frame.minX
			XCTAssert(itemX == expectedX, "Incorrect left item x: \(itemX)")
		}
		
		for item in rightAuxiliaryItems {
			let expectedX: CGFloat = 75
			let itemX = item.frame.minX
			XCTAssert(itemX == expectedX, "Incorrect right item x: \(itemX)")
		}
	}
	
	private func makeItems(of kind: String, count: Int) -> [GridSupplementaryItem] {
		var items: [GridSupplementaryItem] = []
		for _ in 0..<count {
			var item = BasicGridSupplementaryItem(elementKind: kind)
			item.isVisibleWhileShowingPlaceholder = true
			items.append(item)
		}
		return items
	}
		
}
