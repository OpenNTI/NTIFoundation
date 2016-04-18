//
//  GridLayoutSupplementaryItem.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 4/18/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public struct GridLayoutSupplementaryItem: LayoutSupplementaryItemWrapper {
	
	public init(supplementaryItem: SupplementaryItem) {
		layoutSupplementaryItem = BasicLayoutSupplementaryItem(supplementaryItem: supplementaryItem)
	}
	
	public var layoutSupplementaryItem: LayoutSupplementaryItem
	
	public var supplementaryItem: SupplementaryItem {
		get {
			return layoutSupplementaryItem.supplementaryItem
		}
		set {
			layoutSupplementaryItem.supplementaryItem = newValue
		}
	}
	
	/// Y-origin when not pinned.
	public var unpinnedY: CGFloat = 0
	
	// Whether `self` is pinned in place.
	public var isPinned = false
	
	public mutating func setFrame(frame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		
	}
	
	public func isEqual(to other: SupplementaryItem) -> Bool {
		return supplementaryItem.isEqual(to: other)
	}
	
	public mutating func resetLayoutAttributes() {
		
	}
	
	public mutating func applyValues(from metrics: LayoutMetrics) {
		layoutSupplementaryItem.applyValues(from: metrics)
	}
	
	public func configureValues(of attributes: CollectionViewLayoutAttributes) {
		layoutSupplementaryItem.configureValues(of: attributes)
	}
	
}
