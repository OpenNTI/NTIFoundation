//
//  MockLayoutEngine.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 3/10/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

class MockSupplementaryLayoutEngine: NSObject, SupplementaryLayoutEngine {
	
	init(supplementaryItems: [LayoutSupplementaryItem]) {
		self.supplementaryItems = supplementaryItems
	}
	
	var mockHeight: CGFloat = 20
	
	var supplementaryItems: [LayoutSupplementaryItem]
	
	var pinnableHeaders: [LayoutSupplementaryItem] = []
	var nonPinnableHeaders: [LayoutSupplementaryItem] = []

	func layoutWithOrigin(origin: CGPoint, layoutSizing: LayoutSizing, invalidationContext: UICollectionViewLayoutInvalidationContext?) -> CGPoint {
		let x = origin.x + layoutSizing.width
		let y = origin.y + mockHeight * CGFloat(supplementaryItems.count)
		return CGPoint(x: x, y: y)
	}
	
}
