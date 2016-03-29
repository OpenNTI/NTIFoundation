//
//  LayoutRow.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/17/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

/// Layout information about a row.
public protocol LayoutRow: NSObjectProtocol {
	
	var frame: CGRect { get set }
	
	var items: [LayoutItem] { get }
	
	var section: LayoutSection? { get set }
	
	var rowSeparatorLayoutAttributes: UICollectionViewLayoutAttributes? { get set }
	
	func add(item: LayoutItem)
	
	func setFrame(frame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext?)
	
	func columnWidth(forNumberOfColumns columns: Int) -> CGFloat
	
}

extension LayoutRow {
	
	public func columnWidth(forNumberOfColumns columns: Int) -> CGFloat {
		let layoutWidth = frame.width
		let columnWidth = layoutWidth / CGFloat(columns)
		return columnWidth
	}
	
}

public class GridLayoutRow: NSObject, LayoutRow, NSCopying {
	
	public var frame = CGRectZero
	
	public private(set) var items: [LayoutItem] = []
	
	public weak var section: LayoutSection?
	
	public var rowSeparatorLayoutAttributes: UICollectionViewLayoutAttributes?
	
	public func add(item: LayoutItem) {
		items.append(item)
		item.row = self
	}
	
	public func setFrame(frame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) {
		guard frame != self.frame else {
			return
		}
		// Setting the frame on a row needs to update the items within the row and the row separator
		if let rowSeparatorLayoutAttributes = self.rowSeparatorLayoutAttributes {
			var separatorFrame = rowSeparatorLayoutAttributes.frame
			separatorFrame.origin.y = frame.maxY
			rowSeparatorLayoutAttributes.frame = separatorFrame
			invalidateLayoutAttributes(rowSeparatorLayoutAttributes, invalidationContext: invalidationContext)
		}
		
		for itemInfo in items {
			var itemFrame = itemInfo.frame
			itemFrame.origin.y = frame.origin.y
			itemInfo.setFrame(itemFrame, invalidationContext: invalidationContext)
		}
		
		self.frame = frame
	}
	
	public func copyWithZone(zone: NSZone) -> AnyObject {
		let copy = GridLayoutRow()
		copy.section = section
		copy.frame = frame
		copy.items = items.map { $0.copy() as! LayoutItem }
		return copy
	}
	
}
