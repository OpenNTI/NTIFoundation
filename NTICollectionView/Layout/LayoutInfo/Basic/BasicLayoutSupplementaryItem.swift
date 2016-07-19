//
//  BasicLayoutSupplementaryItem.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 4/18/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public struct BasicLayoutSupplementaryItem: LayoutSupplementaryItem, SupplementaryItemWrapper {
	
	public init(supplementaryItem: SupplementaryItem) {
		self.supplementaryItem = supplementaryItem
	}
	
	public init(elementKind: String) {
		supplementaryItem = BasicSupplementaryItem(elementKind: elementKind)
	}
	
	public var supplementaryItem: SupplementaryItem
	
	public var frame = CGRectZero
	
	public var itemIndex = NSNotFound
	
	public var sectionIndex = NSNotFound
	
	public var indexPath: NSIndexPath {
		return sectionIndex == globalSectionIndex ?
			NSIndexPath(index: itemIndex)
			: NSIndexPath(forItem: itemIndex, inSection: sectionIndex)
	}
	
	public mutating func setFrame(frame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		
	}
	
	public func isEqual(to other: SupplementaryItem) -> Bool {
		guard let other = other as? BasicLayoutSupplementaryItem else {
			return false
		}
		
		return supplementaryItem.isEqual(to: other.supplementaryItem)
			&& frame == other.frame
			&& itemIndex == other.itemIndex
			&& sectionIndex == other.sectionIndex
	}
	
	public mutating func resetLayoutAttributes() {
		
	}
	
	public mutating func applyValues(from metrics: LayoutMetrics) {
		supplementaryItem.applyValues(from: metrics)
	}
	
	public func configureValues(of attributes: CollectionViewLayoutAttributes) {
		supplementaryItem.configureValues(of: attributes)
		
		attributes.frame = frame
	}
	
}
