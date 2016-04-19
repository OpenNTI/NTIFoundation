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
	
	public var sectionIndex = NSNotFound
	
	public var hasEstimatedHeight = false
	
	public var isDragging = false
	
	public var layoutMargins = UIEdgeInsetsZero
	
	public var backgroundColor: UIColor?
	
	public var selectedBackgroundColor: UIColor?
	
	public var cornerRadius: CGFloat = 0
	
	public var indexPath: NSIndexPath {
		return sectionIndex == globalSectionIndex ?
			NSIndexPath(index: itemIndex)
			: NSIndexPath(forItem: itemIndex, inSection: sectionIndex)
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
		
		attributes.backgroundColor = backgroundColor
		attributes.selectedBackgroundColor = selectedBackgroundColor
		attributes.cornerRadius = cornerRadius
		attributes.layoutMargins = layoutMargins
		
//		_layoutAttributes = attributes
		return attributes
	}
	
	private var _layoutAttributes: UICollectionViewLayoutAttributes?
	
	public var columnIndex: Int = NSNotFound
	
	public mutating func setFrame(frame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		guard frame != self.frame else {
			return
		}
		self.frame = frame
		invalidationContext?.invalidateItemsAtIndexPaths([indexPath])
	}
	
	public mutating func applyValues(from metrics: LayoutMetrics) {
		guard let sectionMetrics = metrics as? SectionMetrics else {
			return
		}
		
		cornerRadius = sectionMetrics.cornerRadius
		
		guard let gridMetrics = metrics as? GridSectionMetrics else {
			return
		}
		
		layoutMargins = gridMetrics.layoutMargins
		backgroundColor = gridMetrics.backgroundColor
		selectedBackgroundColor = gridMetrics.selectedBackgroundColor
	}
	
	public mutating func resetLayoutAttributes() {
		_layoutAttributes = nil
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
