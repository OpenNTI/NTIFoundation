//
//  LayoutInfo.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/11/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public protocol LayoutAttributesResolving: class {
	
	func layoutAttributesForSupplementaryElementOfKind(kind: String, at indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes?
	
	func layoutAttributesForDecorationViewOfKind(kind: String, at indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes?
	
	func layoutAttributesForCell(at indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes?
	
}

func invalidateLayoutAttributes(attributes: UICollectionViewLayoutAttributes, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
	guard let invalidationContext = invalidationContext else {
		return
	}
	let indexPaths = [attributes.indexPath]
	switch attributes.representedElementCategory {
	case .Cell:
		invalidationContext.invalidateItemsAtIndexPaths(indexPaths)
	case .DecorationView:
		invalidationContext.invalidateDecorationElementsOfKind(attributes.representedElementKind!, atIndexPaths: indexPaths)
	case .SupplementaryView:
		invalidationContext.invalidateSupplementaryElementsOfKind(attributes.representedElementKind!, atIndexPaths: indexPaths)
	}
}


public protocol LayoutInfo: LayoutSizing, LayoutAttributesResolving {
	
	var collectionViewSize: CGSize { get set }
	
	var height: CGFloat { get set }
	
	/// The additional height that's available to placeholders.
	var heightAvailableForPlaceholders: CGFloat { get set }
	
	var contentOffset: CGPoint { get set }
	
	var isEditing: Bool { get }
	
	var numberOfSections: Int { get }
	
	var hasGlobalSection: Bool { get }
	
	var sections: [LayoutSection] { get }
	
	func enumerateSections(block: (sectionIndex: Int, sectionInfo: LayoutSection, inout stop: Bool) -> Void)
	
	/// Return the layout section with the given sectionIndex.
	func sectionAtIndex(sectionIndex: Int) -> LayoutSection?
	
	func add(section: LayoutSection, sectionIndex: Int)
	
	/// Creates and adds a new section.
//	func newSection(sectionIndex index: Int) -> LayoutSection
	
	/// Create a new placeholder covering the specified range of sections.
	func newPlaceholderStartingAtSectionIndex(sectionIndex: Int) -> LayoutPlaceholder
	
	/// Remove all sections including the global section, thus invalidating all layout information.
	func invalidate()
	
	/// Finalize the layout. This method adjusts the size of placeholders and calls each section's `finalizeLayoutAttributesForSectionsWithContent(_:)` method.
	func finalizeLayout()
	
	/// Update the size of an item and mark it as invalidated in the given invalidationContext. This is needed for self-sizing view support. This method also adjusts the position of any content affected by the size change.
	func setSize(size: CGSize, forItemAt indexPath: NSIndexPath, invalidationContext: UICollectionViewLayoutInvalidationContext?)
	
	/// Update the size of a supplementary item and mark it as invalidated in the given *invalidationContext*. This is needed for self-sizing view support. This method also adjusts the position of any content affected by the size change.
	func setSize(size: CGSize, forElementOfKind kind: String, at indexPath: NSIndexPath, invalidationContext: UICollectionViewLayoutInvalidationContext?)
	
	/// Invalidate the current size information for the item at the given *indexPath*, update the layout possibly adjusting the position of content that needs to move to make room for or take up room from the item.
	func invalidateMetricsForItemAt(indexPath: NSIndexPath, invalidationContext: UICollectionViewLayoutInvalidationContext?)
	
	/// Invalidate the current size information for the supplementary item with the given *elementKind* and *indexPath*. This also updates the layout to adjust the position of any content that might need to move to make room for or take up room from the adjusted supplementary item.
	func invalidateMetricsForElementOfKind(kind: String, at indexPath: NSIndexPath, invalidationContext: UICollectionViewLayoutInvalidationContext?)
	
}

public protocol LayoutSizing: NSObjectProtocol {
	
	/// The width of the portion of the layout represented by `self`.
	var width: CGFloat { get set }
	
	var layoutMeasure: CollectionViewLayoutMeasuring? { get }
	
}

public class LayoutSizingInfo: NSObject, LayoutSizing {
	
	public init(width: CGFloat, layoutMeasure: CollectionViewLayoutMeasuring?) {
		self.width = width
		self.layoutMeasure = layoutMeasure
		super.init()
	}
	
	public var width: CGFloat
	
	public var layoutMeasure: CollectionViewLayoutMeasuring?
	
}

public protocol LayoutElement: class {
	
	var frame: CGRect { get set }
	
	var itemIndex: Int { get set }
	
	var indexPath: NSIndexPath { get }
	
	var layoutAttributes: UICollectionViewLayoutAttributes { get }
	
	/// Update the frame of this object. If the frame has changed, mark the object as invalid in the invalidation context.
	func setFrame(frame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext?)
	
	func resetLayoutAttributes()
	
}


/// Layout information about a supplementary item.
public protocol LayoutSupplementaryItem: SupplementaryItem, LayoutElement {
	
	var section: LayoutSection? { get set }
	
}
