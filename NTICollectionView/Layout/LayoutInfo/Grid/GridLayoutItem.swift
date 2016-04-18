//
//  GridLayoutItem.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/25/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public struct GridLayoutItem: LayoutItem {
	
	public var frame = CGRectZero {
		didSet {
			_layoutAttributes?.frame = frame
		}
	}
	
	public var itemIndex = 0
	
	public var hasEstimatedHeight = false
	
	public var isDragging = false
	
	public var indexPath: NSIndexPath {
		guard let sectionInfo = section else {
			preconditionFailure("Items must be assigned to a section to provide an index path.")
		}
		if sectionInfo.isGlobalSection {
			return NSIndexPath(index: itemIndex)
		} else {
			return NSIndexPath(forItem: itemIndex, inSection: sectionInfo.sectionIndex)
		}
	}
	
	public var layoutAttributes: CollectionViewLayoutAttributes {
//		if let layoutAttributes = _layoutAttributes where layoutAttributes.indexPath == indexPath {
//			return layoutAttributes
//		}
		
		let attributes = CollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
		attributes.frame = self.frame
		attributes.zIndex = defaultZIndex
		attributes.columnIndex = columnIndex
		attributes.shouldCalculateFittingSize = hasEstimatedHeight
		attributes.hidden = isDragging
		
		// TODO: Decouple from section
		if let section = self.section as? GridLayoutSection {
			let metrics = section.metrics
			attributes.backgroundColor = metrics.backgroundColor
			attributes.selectedBackgroundColor = metrics.selectedBackgroundColor
			attributes.cornerRadius = metrics.cornerRadius
			attributes.layoutMargins = metrics.layoutMargins
		}
		
//		_layoutAttributes = attributes
		return attributes
	}
	
	private var _layoutAttributes: UICollectionViewLayoutAttributes?
	
	public var columnIndex: Int = NSNotFound
	
	public var section: LayoutSection?
	
	public mutating func setFrame(frame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		guard frame != self.frame else {
			return
		}
		self.frame = frame
		invalidationContext?.invalidateItemsAtIndexPaths([indexPath])
	}
	
	public mutating func resetLayoutAttributes() {
		_layoutAttributes = nil
	}
	
	public func isEqual(to other: LayoutItem) -> Bool {
		guard let other = other as? GridLayoutItem else {
			return false
		}
		
		return itemIndex == other.itemIndex
			&& hasEstimatedHeight == other.hasEstimatedHeight
			&& isDragging == other.isDragging
			&& section === other.section
			&& columnIndex == other.columnIndex
	}
	
}
