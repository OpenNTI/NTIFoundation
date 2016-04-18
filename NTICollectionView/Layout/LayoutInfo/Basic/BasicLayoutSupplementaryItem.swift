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
	
	public var layoutAttributes: CollectionViewLayoutAttributes {
		let attributes = CollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind, withIndexPath: indexPath)
		
		applyValues(to: attributes)
		
		return attributes
	}
	
	public mutating func setFrame(frame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		
	}
	
	public mutating func applyValues(from metrics: SupplementaryItem) {
		
	}
	
	public func definesMetric(metric: String) -> Bool {
		return false
	}
	
	public func isEqual(to other: SupplementaryItem) -> Bool {
		return supplementaryItem.isEqual(to: other)
	}
	
	public mutating func resetLayoutAttributes() {
		
	}
	
	public func applyValues(to attributes: CollectionViewLayoutAttributes) {
		supplementaryItem.applyValues(to: attributes)
		
		attributes.frame = frame
	}
	
}
