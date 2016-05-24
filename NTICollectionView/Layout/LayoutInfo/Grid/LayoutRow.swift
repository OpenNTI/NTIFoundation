//
//  LayoutRow.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/17/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

/// Layout information about a row.
public protocol LayoutRow: class {
	
	var frame: CGRect { get set }
	
	var items: [LayoutItem] { get }
	
	var section: LayoutSection? { get set }
	
	var rowSeparatorLayoutAttributes: UICollectionViewLayoutAttributes? { get }
	
	var rowSeparatorDecoration: HorizontalSeparatorDecoration? { get set }
	
	func add(item: LayoutItem)
	
	func setFrame(frame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext?)
	
	func columnWidth(forNumberOfColumns columns: Int) -> CGFloat
	
	func copy() -> LayoutRow
	
}

extension LayoutRow {
	
	public func columnWidth(forNumberOfColumns columns: Int) -> CGFloat {
		let layoutWidth = frame.width
		let columnWidth = layoutWidth / CGFloat(columns)
		return columnWidth
	}
	
}

public class GridLayoutRow: LayoutRow {
	
	public var metrics = BasicGridSectionMetrics()
	
	public var frame = CGRectZero
	
	public private(set) var items: [LayoutItem] = []
	
	public weak var section: LayoutSection?
	
	public var rowSeparatorLayoutAttributes: UICollectionViewLayoutAttributes? {
		return rowSeparatorDecoration?.layoutAttributes
	}
	
	public var rowSeparatorDecoration: HorizontalSeparatorDecoration?
	
	public func add(item: LayoutItem) {
		items.append(item)
		item.row = self
	}
	
	public func setFrame(frame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) {
		guard frame != self.frame else {
			return
		}
		// Setting the frame on a row needs to update the items within the row and the row separator
		rowSeparatorDecoration?.setContainerFrame(frame, invalidationContext: invalidationContext)
		
		for itemInfo in items {
			var itemFrame = itemInfo.frame
			itemFrame.origin.y = frame.origin.y
			itemInfo.setFrame(itemFrame, invalidationContext: invalidationContext)
		}
		
		self.frame = frame
	}
	
	public func columnWidth(forNumberOfColumns columns: Int) -> CGFloat {
		return metrics.fixedColumnWidth ?? maximizedColumnWidth(forNumberOfColumns: columns)
	}
	
	private func maximizedColumnWidth(forNumberOfColumns columns: Int) -> CGFloat {
		let layoutWidth = frame.width
		let spacing = metrics.minimumInteritemSpacing
		let numberOfColumns = CGFloat(columns)
		let totalSpacing = max(numberOfColumns - 1, 0) * spacing
		let columnWidth = (layoutWidth - totalSpacing) / numberOfColumns
		return columnWidth
	}
	
	public func copy() -> LayoutRow {
		let copy = GridLayoutRow()
		copy.section = section
		copy.frame = frame
		copy.items = items.map { $0.copy() }
		copy.metrics = metrics
		return copy
	}
	
}
