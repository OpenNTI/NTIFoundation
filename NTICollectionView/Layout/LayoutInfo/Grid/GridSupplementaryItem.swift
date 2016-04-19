//
//  GridSupplementaryItem.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/19/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

// MARK: - GridSupplementaryItem

private let defaultEstimatedHeight: CGFloat = 44

public struct GridSupplementaryItem: SupplementaryItemWrapper, GridSupplementaryAttributesWrapper {
	
	public init(elementKind: String) {
		supplementaryItem = BasicSupplementaryItem(elementKind: elementKind)
	}
	
	public var supplementaryItem: SupplementaryItem
	
	public var gridSupplementaryAttributes = GridSupplementaryAttributes()
	
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
	
	public mutating func applyValues(from metrics: LayoutMetrics) {
		supplementaryItem.applyValues(from: metrics)
		gridSupplementaryAttributes.applyValues(from: metrics)
	}
	
	public mutating func setFrame(frame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		
	}
	
	public mutating func resetLayoutAttributes() {
		
	}
	
	public func isEqual(to other: SupplementaryItem) -> Bool {
		guard let other = other as? GridSupplementaryItem else {
			return false
		}
		
		return supplementaryItem.isEqual(to: other)
			&& gridSupplementaryAttributes == other.gridSupplementaryAttributes
	}
	
}
