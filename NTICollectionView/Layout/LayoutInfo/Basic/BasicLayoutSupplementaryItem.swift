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
	
	public var supplementaryItem: SupplementaryItem
	
	public var section: LayoutSection?
	
	public var frame = CGRectZero
	
	public var itemIndex = NSNotFound
	
	public var indexPath: NSIndexPath {
		guard let sectionInfo = section else {
			return NSIndexPath()
		}
		if sectionInfo.isGlobalSection {
			return NSIndexPath(index: itemIndex)
		} else {
			return NSIndexPath(forItem: itemIndex, inSection: sectionInfo.sectionIndex)
		}
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
			&& section === other.section
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
