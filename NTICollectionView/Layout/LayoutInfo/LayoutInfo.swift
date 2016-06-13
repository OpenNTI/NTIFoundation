//
//  LayoutInfo.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/11/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public protocol LayoutAttributesResolving {
	
	func layoutAttributesForSupplementaryElementOfKind(kind: String, at indexPath: NSIndexPath) -> CollectionViewLayoutAttributes?
	
	func layoutAttributesForDecorationViewOfKind(kind: String, at indexPath: NSIndexPath) -> CollectionViewLayoutAttributes?
	
	func layoutAttributesForCell(at indexPath: NSIndexPath) -> CollectionViewLayoutAttributes?
	
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

public struct LayoutData : Equatable {
	
	public static let blank = LayoutData()
	
	public var layoutSize = CGSizeZero
	
	public var viewBounds = CGRectZero
	
	public var contentOffset = CGPointZero
	
	public var contentInset = UIEdgeInsetsZero
	
	public var sections: [LayoutSection] = []
	
	public var globalSection: LayoutSection?
	
	public var numberOfPlaceholders: Int = 0
	
	public var isEditing = false
	
}

public func ==(lhs: LayoutData, rhs: LayoutData) -> Bool {
	return lhs.layoutSize == rhs.layoutSize
		&& lhs.viewBounds == rhs.viewBounds
		&& lhs.contentOffset == rhs.contentOffset
		&& lhs.contentInset == rhs.contentInset
		&& lhs.numberOfPlaceholders == rhs.numberOfPlaceholders
		&& lhs.isEditing == rhs.isEditing
		&& lhs.sections.elementsEqual(rhs.sections, isEquivalent: { (lSection, rSection) -> Bool in
			lSection.isEqual(to: rSection)
		})
		&& ((lhs.globalSection == nil && rhs.globalSection == nil)
			|| (lhs.globalSection != nil && rhs.globalSection != nil && lhs.globalSection!.isEqual(to: rhs.globalSection!)))
}

extension LayoutData {
	
	public var allSections: [LayoutSection] {
		return [globalSection].flatMap{$0} + sections
	}
	
}

public protocol LayoutSectionProviding {
	
	var numberOfSections: Int { get }
	
	var hasGlobalSection: Bool { get }
	
	func section(atIndex index: Int) -> LayoutSection?
	
}

extension LayoutData : LayoutSectionProviding {
	
	public var numberOfSections: Int {
		return sections.count
	}
	
	public var hasGlobalSection: Bool {
		return globalSection != nil
	}
	
	public func section(atIndex index: Int) -> LayoutSection? {
		if index == globalSectionIndex {
			return globalSection
		}
		
		guard (0..<sections.count).contains(index) else {
			return nil
		}
		
		return sections[index]
	}
	
}

/// Provides layout dynamics.
public protocol LayoutStrategy {
	
	/// Creates a new placeholder covering the specified range of sections.
	func makePlaceholder(startingAtSectionIndex index: Int, inout for data: LayoutData) -> LayoutPlaceholder
	
	/// Finalizes the layout.
	func finalizeLayout(inout for data: LayoutData)
	
	/// Updates and invalidates the size of an item, also adjusting the position of any content affected by the size change.
	func setSize(size: CGSize, forItemAt indexPath: NSIndexPath, inout in data: LayoutData, invalidationContext: UICollectionViewLayoutInvalidationContext?)
	
	/// Updates and invalidates the size of a supplementary item, also adjusting the position of any content affected by the size change.
	func setSize(size: CGSize, forElementOfKind kind: String, at indexPath: NSIndexPath, inout in data: LayoutData, invalidationContext: UICollectionViewLayoutInvalidationContext?)
	
	func targetLayoutHeight(forProposedLayoutHeight proposed: CGFloat, using data: LayoutData) -> CGFloat
	
	/// Updates any items whose behavior is dependent on the content offset.
	func updateSpecialItems(withContentOffset offset: CGPoint, inout in data: LayoutData, invalidationContext: UICollectionViewLayoutInvalidationContext?)
	
}

public protocol LayoutInfo: LayoutSizing, LayoutAttributesResolving, LayoutSectionProvider {
	
	var collectionViewSize: CGSize { get set }
	
	var height: CGFloat { get set }
	
	/// The additional height that's available to placeholders.
	var heightAvailableForPlaceholders: CGFloat { get set }
	
	var contentOffset: CGPoint { get set }
	
	var contentInset: UIEdgeInsets { get set }
	
	var bounds: CGRect { get set }
	
	var isEditing: Bool { get set }
	
	var sections: [LayoutSection] { get }
	
	func mutateSection(at index: Int, using mutator: (inout LayoutSection) -> Void)
	
	func mutateItem(at indexPath: NSIndexPath, using mutator: (inout LayoutItem) -> Void)
	
	/// Create a new placeholder covering the specified range of sections.
	func newPlaceholderStartingAtSectionIndex(sectionIndex: Int) -> LayoutPlaceholder
	
	/// Remove all sections including the global section, thus invalidating all layout information.
	func invalidate()
	
	/// Make any necessary preparations before layout begins.
	func prepareForLayout()
	
	/// Finalize the layout. This method adjusts the size of placeholders and calls each section's `finalizeLayoutAttributesForSectionsWithContent(_:)` method.
	func finalizeLayout()
	
	/// Update the size of an item and mark it as invalidated in the given invalidationContext. This is needed for self-sizing view support. This method also adjusts the position of any content affected by the size change.
	func setSize(size: CGSize, forItemAt indexPath: NSIndexPath, invalidationContext: UICollectionViewLayoutInvalidationContext?)
	
	/// Update the size of a supplementary item and mark it as invalidated in the given *invalidationContext*. This is needed for self-sizing view support. This method also adjusts the position of any content affected by the size change.
	func setSize(size: CGSize, forElementOfKind kind: String, at indexPath: NSIndexPath, invalidationContext: UICollectionViewLayoutInvalidationContext?)
	
	func updateSpecialItemsWithContentOffset(contentOffset: CGPoint, invalidationContext: UICollectionViewLayoutInvalidationContext?)
	
}

public protocol LayoutSectionProvider: class {
	
	var numberOfSections: Int { get }
	
	var hasGlobalSection: Bool { get }
	
	func enumerateSections(block: (sectionIndex: Int, inout sectionInfo: LayoutSection, inout stop: Bool) -> Void)
	
	/// Return the layout section with the given sectionIndex.
	func sectionAtIndex(sectionIndex: Int) -> LayoutSection?
	
	func setSection(section: LayoutSection, at sectionIndex: Int)
	
	func add(section: LayoutSection, sectionIndex: Int)
	
}

public protocol LayoutSizing: class {
	
	/// The width of the portion of the layout represented by `self`.
	var width: CGFloat { get set }
	
	var layoutMeasure: CollectionViewLayoutMeasuring? { get }
	
}

public class LayoutSizingInfo: LayoutSizing {
	
	public init(width: CGFloat, layoutMeasure: CollectionViewLayoutMeasuring?) {
		self.width = width
		self.layoutMeasure = layoutMeasure
	}
	
	public var width: CGFloat
	
	public var layoutMeasure: CollectionViewLayoutMeasuring?
	
}

/// A two-dimensional region in a collection view layout.
///
/// An adopting type may represent a single layout element or a composition of layout elements.
public protocol LayoutArea {
	
	var frame: CGRect { get set }
	
	/// Update the frame of `self` and any child areas. 
	///
	/// If the frame has changed, mark objects as invalid in the invalidation context as necessary.
	mutating func setFrame(frame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext?)
	
}


public protocol LayoutElement: LayoutArea {
	
	var itemIndex: Int { get set }
	
	var indexPath: NSIndexPath { get }
	
	var layoutAttributes: CollectionViewLayoutAttributes { get }
	
	mutating func resetLayoutAttributes()
	
}


/// Layout information about a supplementary item.
public protocol LayoutSupplementaryItem: SupplementaryItemWrapper, LayoutElement {
	
	var sectionIndex: Int { get set }
	
	var supplementaryItem: SupplementaryItem { get set }
	
}

extension LayoutSupplementaryItem {
	
	public var layoutAttributes: CollectionViewLayoutAttributes {
		let attributes = CollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind, withIndexPath: indexPath)
		
		configureValues(of: attributes)
		
		return attributes
	}
	
}

public protocol LayoutSupplementaryItemWrapper: LayoutSupplementaryItem {
	
	var layoutSupplementaryItem: LayoutSupplementaryItem { get set }
	
}

extension LayoutSupplementaryItemWrapper {
	
	public var frame: CGRect {
		get {
			return layoutSupplementaryItem.frame
		}
		set {
			layoutSupplementaryItem.frame = newValue
		}
	}
	
	public var itemIndex: Int {
		get {
			return layoutSupplementaryItem.itemIndex
		}
		set {
			layoutSupplementaryItem.itemIndex = newValue
		}
	}
	
	public var sectionIndex: Int {
		get {
			return layoutSupplementaryItem.sectionIndex
		}
		set {
			layoutSupplementaryItem.sectionIndex = newValue
		}
	}
	
	public var indexPath: NSIndexPath {
		return layoutSupplementaryItem.indexPath
	}
	
	public var layoutAttributes: UICollectionViewLayoutAttributes {
		return layoutSupplementaryItem.layoutAttributes
	}
	
	public mutating func resetLayoutAttributes() {
		layoutSupplementaryItem.resetLayoutAttributes()
	}
	
	public mutating func setFrame(frame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		layoutSupplementaryItem.setFrame(frame, invalidationContext: invalidationContext)
	}
	
}
