//
//  LayoutPlaceholder.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/16/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

/// Layout information for a placeholder.
public protocol LayoutPlaceholder: LayoutElement {
	
	var backgroundColor: UIColor? { get }
	
	var height: CGFloat { get set }
	
	var hasEstimatedHeight: Bool { get set }
	
	var shouldFillAvailableHeight: Bool { get set }
	
	/// The first section index of this placeholder.
	var startingSectionIndex: Int { get }
	
	/// The last section index of this placeholder.
	var endingSectionIndex: Int { get }
	
	mutating func wasAddedToSection(_ section: LayoutSection)
	
	func isEqual(to other: LayoutPlaceholder) -> Bool
	
}

extension LayoutPlaceholder {
	
	public func startsAt(_ section: LayoutSection) -> Bool {
		return startingSectionIndex == section.sectionIndex
	}
	
}

public struct BasicLayoutPlaceholder: LayoutPlaceholder {
	
	public init(sectionIndexes: IndexSet) {
		self.sectionIndexes = sectionIndexes
	}
	
	fileprivate var sectionIndexes: IndexSet
	
	public var frame = CGRect.zero
	
	public var itemIndex = 0
	
	public var indexPath: IndexPath {
		return IndexPath(item: itemIndex, section: startingSectionIndex)
	}
	
	public var layoutAttributes: CollectionViewLayoutAttributes {
		let attributes = CollectionViewLayoutAttributes(forSupplementaryViewOfKind: collectionElementKindPlaceholder, with: indexPath)
		
		attributes.frame = frame
		attributes.unpinnedOrigin = frame.origin
		attributes.zIndex = headerZIndex
		attributes.isPinned = false
		attributes.backgroundColor = backgroundColor
		attributes.isHidden = false
		attributes.shouldCalculateFittingSize = hasEstimatedHeight
		
		return attributes
	}
	
	public var backgroundColor: UIColor?
	
	public var height: CGFloat = 0
	
	public var hasEstimatedHeight = false
	
	public var shouldFillAvailableHeight = true
	
	public var startingSectionIndex: Int {
		return sectionIndexes.first ?? NSNotFound
	}
	
	public var endingSectionIndex: Int {
		return sectionIndexes.last ?? NSNotFound
	}
	
	public mutating func setFrame(_ frame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) {
		self.frame = frame
		layoutAttributes.frame = frame
		
		if self.frame.height > 0 {
			invalidationContext?.invalidateSupplementaryElements(ofKind: collectionElementKindPlaceholder, at: [indexPath])
		}
	}
	
	public mutating func wasAddedToSection(_ section: LayoutSection) {
		sectionIndexes.insert(section.sectionIndex)
	}
	
	public mutating func resetLayoutAttributes() {
		
	}
	
	public func isEqual(to other: LayoutPlaceholder) -> Bool {
		guard let other = other as? BasicLayoutPlaceholder else {
			return false
		}
		
		return sectionIndexes == other.sectionIndexes
			&& height == other.height
			&& hasEstimatedHeight == other.hasEstimatedHeight
			&& backgroundColor == other.backgroundColor
		
			&& frame == other.frame
			&& itemIndex == other.itemIndex
	}
	
}
