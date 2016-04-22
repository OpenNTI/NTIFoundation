//
//  LayoutRow.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/17/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

/// Layout information about a row.
public protocol LayoutRowProtocol: LayoutArea {
	
	var frame: CGRect { get set }
	
	var items: [LayoutItem] { get set }
	
	var rowSeparatorLayoutAttributes: CollectionViewLayoutAttributes? { get }
	
	var rowSeparatorDecoration: HorizontalSeparatorDecoration? { get set }
	
	mutating func add(item: LayoutItem)
	
	mutating func setFrame(frame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext?)
	
	func columnWidth(forNumberOfColumns columns: Int) -> CGFloat
	
	func isEqual(to other: LayoutRowProtocol) -> Bool
	
}

extension LayoutRowProtocol {
	
	public func columnWidth(forNumberOfColumns columns: Int) -> CGFloat {
		let layoutWidth = frame.width
		let columnWidth = layoutWidth / CGFloat(columns)
		return columnWidth
	}
	
}

public struct LayoutRow: LayoutRowProtocol {
	
	public var metrics = BasicGridSectionMetrics()
	
	public var frame = CGRectZero
	
	public var items: [LayoutItem] = []
	
	public var rowSeparatorLayoutAttributes: CollectionViewLayoutAttributes? {
		return rowSeparatorDecoration?.layoutAttributes
	}
	
	public var rowSeparatorDecoration: HorizontalSeparatorDecoration?
	
	public mutating func add(item: LayoutItem) {
		items.append(item)
	}
	
	public mutating func setFrame(frame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) {
		guard frame != self.frame else {
			return
		}
		// Setting the frame on a row needs to update the items within the row and the row separator
		rowSeparatorDecoration?.setContainerFrame(frame, invalidationContext: invalidationContext)
		
		
		for (index, item) in items.enumerate() {
			var itemInfo = item
			var itemFrame = itemInfo.frame
			itemFrame.origin.y = frame.origin.y
			itemInfo.setFrame(itemFrame, invalidationContext: invalidationContext)
			items[index] = itemInfo
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
	
	public func isEqual(to other: LayoutRowProtocol) -> Bool {
		guard let other = other as? LayoutRow else {
			return false
		}
		
		return frame == other.frame
			&& items.elementsEqual(other.items) { $0.isEqual(to: $1) }
	}
	
}
