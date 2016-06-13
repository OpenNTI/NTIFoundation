//
//  TableLayoutSupplementaryItem.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 5/24/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public struct TableSupplementaryItem : SupplementaryItemWrapper {
	
	public var layoutMargins = UIEdgeInsetsZero
	
	public var backgroundColor: UIColor?
	
	public var selectedBackgroundColor: UIColor?
	
	public var pinnedBackgroundColor: UIColor?
	
	public var showsSeparator = false
	
	public var separatorColor: UIColor?
	
	public var pinnedSeparatorColor: UIColor?
	
	public var simulatesSelection = false
	
	public var supplementaryItem: SupplementaryItem
	
	public init(elementKind: String) {
		supplementaryItem = BasicSupplementaryItem(elementKind: elementKind)
	}
	
	public mutating func applyValues(from metrics: LayoutMetrics) {
		supplementaryItem.applyValues(from: metrics)
		
		guard let metrics = metrics as? TableSectionMetrics else {
			return
		}
		
		if backgroundColor == nil {
			backgroundColor = metrics.backgroundColor
		}
		
		if separatorColor == nil && metrics.definesMetric("separatorColor") {
			separatorColor = metrics.separatorColor
		}
		
		if pinnedBackgroundColor == nil {
			pinnedBackgroundColor = metrics.backgroundColor
		}
		
		if pinnedSeparatorColor == nil && metrics.definesMetric("separatorColor") {
			pinnedSeparatorColor = metrics.separatorColor
		}
	}
	
	public func configureValues(of attributes: CollectionViewLayoutAttributes) {
		supplementaryItem.configureValues(of: attributes)
		
		attributes.layoutMargins = layoutMargins
		attributes.backgroundColor = backgroundColor
		attributes.selectedBackgroundColor = selectedBackgroundColor
		attributes.pinnedBackgroundColor = pinnedBackgroundColor
		attributes.showsSeparator = showsSeparator
		attributes.separatorColor = separatorColor
		attributes.pinnedSeparatorColor = pinnedSeparatorColor
		attributes.simulatesSelection = simulatesSelection
	}
	
	public func isEqual(to other: SupplementaryItem) -> Bool {
		guard let other = other as? TableSupplementaryItem else {
			return false
		}
		
		return supplementaryItem.isEqual(to: other.supplementaryItem)
			&& layoutMargins == other.layoutMargins
			&& backgroundColor == other.backgroundColor
			&& selectedBackgroundColor == other.selectedBackgroundColor
			&& pinnedBackgroundColor == other.pinnedBackgroundColor
			&& showsSeparator == other.showsSeparator
			&& separatorColor == other.separatorColor
			&& pinnedSeparatorColor == other.pinnedSeparatorColor
			&& simulatesSelection == other.simulatesSelection
	}
	
}

public struct TableLayoutSupplementaryItem : LayoutSupplementaryItemWrapper {
	
	public init(supplementaryItem: SupplementaryItem) {
		layoutSupplementaryItem = BasicLayoutSupplementaryItem(supplementaryItem: supplementaryItem)
	}
	
	public init(elementKind: String) {
		layoutSupplementaryItem = BasicLayoutSupplementaryItem(supplementaryItem: BasicSupplementaryItem(elementKind: elementKind))
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
		layoutSupplementaryItem.setFrame(frame, invalidationContext: invalidationContext)
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
