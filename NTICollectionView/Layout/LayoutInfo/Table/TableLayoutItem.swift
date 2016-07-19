//
//  TableLayoutItem.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 5/24/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public struct TableLayoutItem : LayoutItem {
	
	public var frame = CGRectZero
	
	public var itemIndex = 0
	
	public var columnIndex = NSNotFound
	
	public var sectionIndex = NSNotFound
	
	public var hasEstimatedHeight = false
	
	public var isDragging = false
	
	public var layoutMargins = UIEdgeInsetsZero
	
	public var backgroundColor: UIColor?
	
	public var selectedBackgroundColor: UIColor?
	
	public var indexPath: NSIndexPath {
		return sectionIndex == globalSectionIndex ?
			NSIndexPath(index: itemIndex)
			: NSIndexPath(forItem: itemIndex, inSection: sectionIndex)
	}
	
	public mutating func applyValues(from metrics: LayoutMetrics) {
		guard let tableMetrics = metrics as? TableSectionMetrics else {
			return
		}
		
		layoutMargins = tableMetrics.layoutMargins
		backgroundColor = tableMetrics.backgroundColor
		selectedBackgroundColor = tableMetrics.selectedBackgroundColor
	}
	
	public var layoutAttributes: CollectionViewLayoutAttributes {
		let attributes = CollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
		attributes.frame = self.frame
		attributes.zIndex = defaultZIndex
		attributes.columnIndex = columnIndex
		attributes.shouldCalculateFittingSize = hasEstimatedHeight
		attributes.hidden = isDragging
		
		attributes.backgroundColor = backgroundColor
		attributes.selectedBackgroundColor = selectedBackgroundColor
		attributes.layoutMargins = layoutMargins
		
		return attributes
	}
	
	public mutating func resetLayoutAttributes() {

	}
	
	public mutating func setFrame(frame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		guard frame != self.frame else {
			return
		}
		self.frame = frame
		invalidationContext?.invalidateItemsAtIndexPaths([indexPath])
	}
	
	public func isEqual(to other: LayoutItem) -> Bool {
		guard let other = other as? GridLayoutItem else {
			return false
		}
		
		return itemIndex == other.itemIndex
			&& sectionIndex == other.sectionIndex
			&& frame == other.frame
			&& hasEstimatedHeight == other.hasEstimatedHeight
			&& isDragging == other.isDragging
			&& columnIndex == other.columnIndex
	}
	
}
