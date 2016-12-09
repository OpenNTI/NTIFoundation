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
	
	public init(elementKind: String) {
		layoutSupplementaryItem = BasicLayoutSupplementaryItem(supplementaryItem: GridSupplementaryItem(elementKind: elementKind))
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
	
	public mutating func setFrame(_ frame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		
	}
	
	public func isEqual(to other: SupplementaryItem) -> Bool {
		guard let other = other as? GridLayoutSupplementaryItem else {
			return false
		}
		
		return layoutSupplementaryItem.isEqual(to: other.layoutSupplementaryItem)
			&& unpinnedY == other.unpinnedY
			&& isPinned == other.isPinned
	}
	
	public mutating func resetLayoutAttributes() {
		
	}
	
	public mutating func applyValues(from metrics: LayoutMetrics) {
		layoutSupplementaryItem.applyValues(from: metrics)
	}
	
	public func configureValues(of attributes: CollectionViewLayoutAttributes) {
		layoutSupplementaryItem.configureValues(of: attributes)
		
		attributes.unpinnedOrigin = CGPoint(x: frame.minX, y: unpinnedY)
		attributes.isPinned = isPinned
	}
	
}
