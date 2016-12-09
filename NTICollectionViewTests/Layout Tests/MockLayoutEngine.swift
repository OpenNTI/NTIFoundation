//
//  MockLayoutEngine.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 3/10/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

class MockLayoutEngine: NSObject, LayoutEngine {
	
	init(mockHeight: CGFloat) {
		layoutHeight = mockHeight
		super.init()
	}
	
	var layoutHeight: CGFloat
	
	func layoutWithOrigin(_ origin: CGPoint, layoutSizing: LayoutSizing, invalidationContext: UICollectionViewLayoutInvalidationContext?) -> CGPoint {
		return CGPoint(x: origin.x + layoutSizing.width, y: origin.y + layoutHeight)
	}
	
}

class MockSupplementaryLayoutEngine: NSObject, SupplementaryLayoutEngine {
	
	init(supplementaryItems: [LayoutSupplementaryItem]) {
		self.supplementaryItems = supplementaryItems
	}
	
	var mockHeight: CGFloat = 20
	
	var supplementaryItems: [LayoutSupplementaryItem]
	
	var pinnableHeaders: [LayoutSupplementaryItem] = []
	var nonPinnableHeaders: [LayoutSupplementaryItem] = []
	
	var position: CGPoint!
	var sizing: LayoutSizing!

	func layoutWithOrigin(_ origin: CGPoint, layoutSizing: LayoutSizing, invalidationContext: UICollectionViewLayoutInvalidationContext?) -> CGPoint {
		position = origin
		sizing = layoutSizing
		for index in supplementaryItems.indices {
			layout(&supplementaryItems[index])
		}
		position.x += sizing.width
		return position
	}
	
	fileprivate func layout(_ supplementaryItem: inout LayoutSupplementaryItem) {
		let size = self.size(of: &supplementaryItem)
		supplementaryItem.frame = CGRect(origin: position, size: size)
		position.y += size.height
	}
	
	fileprivate func size(of supplementaryItem: inout LayoutSupplementaryItem) -> CGSize {
		let w = sizing.width
		let h = sizing.layoutMeasure?.measuredSizeForSupplementaryItem(supplementaryItem).height ?? mockHeight
		return CGSize(width: w, height: h)
	}
	
}
