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
	
	/// The first section index of this placeholder.
	var startingSectionIndex: Int { get }
	
	/// The last section index of this placeholder.
	var endingSectionIndex: Int { get }
	
	func wasAddedToSection(section: LayoutSection)
	
	func isEqual(to other: LayoutPlaceholder) -> Bool
	
}

extension LayoutPlaceholder {
	
	public func startsAt(section: LayoutSection) -> Bool {
		return startingSectionIndex == section.sectionIndex
	}
	
}

public class BasicLayoutPlaceholder: LayoutPlaceholder {
	
	public init(sectionIndexes: NSIndexSet) {
		self.sectionIndexes = sectionIndexes.mutableCopy() as! NSMutableIndexSet
	}
	
	private let sectionIndexes: NSMutableIndexSet
	
	public var frame = CGRectZero
	
	public var itemIndex = 0
	
	public var indexPath: NSIndexPath {
		return NSIndexPath(forItem: itemIndex, inSection: startingSectionIndex)
	}
	
	public var layoutAttributes: UICollectionViewLayoutAttributes {
		if let layoutAttributes = _layoutAttributes where layoutAttributes.indexPath == indexPath {
			return layoutAttributes
		}
		
		let attributes = CollectionViewLayoutAttributes(forSupplementaryViewOfKind: CollectionElementKindPlaceholder, withIndexPath: indexPath)
		
		attributes.frame = frame
		attributes.unpinnedOrigin = frame.origin
		attributes.zIndex = headerZIndex
		attributes.isPinned = false
		attributes.backgroundColor = backgroundColor
		attributes.hidden = false
		attributes.shouldCalculateFittingSize = hasEstimatedHeight
		
		_layoutAttributes = attributes
		return attributes
	}
	private var _layoutAttributes: CollectionViewLayoutAttributes?
	
	public var backgroundColor: UIColor?
	
	public var height: CGFloat = 0
	
	public var hasEstimatedHeight = false
	
	public var startingSectionIndex: Int {
		return sectionIndexes.firstIndex
	}
	
	public var endingSectionIndex: Int {
		return sectionIndexes.lastIndex
	}
	
	public func setFrame(frame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) {
		self.frame = frame
		layoutAttributes.frame = frame
		
		if self.frame.height > 0 {
			invalidationContext?.invalidateSupplementaryElementsOfKind(CollectionElementKindPlaceholder, atIndexPaths: [indexPath])
		}
	}
	
	public func wasAddedToSection(section: LayoutSection) {
		sectionIndexes.addIndex(section.sectionIndex)
	}
	
	public func resetLayoutAttributes() {
		_layoutAttributes = nil
	}
	
	public func isEqual(to other: LayoutPlaceholder) -> Bool {
		guard let other = other as? BasicLayoutPlaceholder else {
			return false
		}
		
		return self === other
//		return sectionIndexes == other.sectionIndexes
//			&& height == other.height
//			&& hasEstimatedHeight == other.hasEstimatedHeight
//			&& backgroundColor == other.backgroundColor
	}
	
}
