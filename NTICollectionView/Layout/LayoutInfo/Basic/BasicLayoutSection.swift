//
//  BasicLayoutSection.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 4/19/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public struct BasicLayoutSection: LayoutSection {
	
	static let hairline: CGFloat = 1.0 / UIScreen.mainScreen().scale
	
	public var frame = CGRectZero
	
	public var sectionIndex = NSNotFound
	
	public var items: [LayoutItem] = []
	
	public var layoutInfo: LayoutInfo?
	
	public var supplementaryItems: [LayoutSupplementaryItem] {
		return supplementaryItemsByKind.contents
	}
	
	public var supplementaryItemsByKind: [String: [LayoutSupplementaryItem]] = [:]
	
	public var decorationAttributesByKind: [String : [CollectionViewLayoutAttributes]] {
		return attributesForDecorationsByKind
	}
	
	// O(n^2)
	private var attributesForDecorationsByKind: [String: [CollectionViewLayoutAttributes]] {
		var attributesByKind: [String: [CollectionViewLayoutAttributes]] = [:]
//		let insetFrame = UIEdgeInsetsInsetRect(frame, metrics.contentInset)
		
		for (kind, decorations) in decorationsByKind {
			for (index, decoration) in decorations.enumerate() {
				var decoration = decoration
				decoration.itemIndex = index
				decoration.sectionIndex = sectionIndex
				decoration.setContainerFrame(frame, invalidationContext: nil)
				let attributes = decoration.layoutAttributes
				attributesByKind.append(attributes, to: kind)
			}
		}
		
		return attributesByKind
	}
	
	public var decorationsByKind: [String : [LayoutDecoration]] = [:]
	
	public var decorations: [LayoutDecoration] {
		return decorationsByKind.contents
	}
	
	// FIXME: Make sure this doesn't trigger when we're mutating the value
	public var placeholderInfo: LayoutPlaceholder? {
		didSet {
			guard let placeholderInfo = self.placeholderInfo else {
				return
			}
			
			if let oldValue = oldValue where placeholderInfo.isEqual(to: oldValue) {
				return
			}
			
			placeholderInfo.wasAddedToSection(self)
		}
	}
	
	public mutating func add(item: LayoutItem) {
		var item = item
		item.sectionIndex = sectionIndex
		items.append(item)
		
	}
	
	public mutating func add(supplementaryItem: LayoutSupplementaryItem) {
		let kind = supplementaryItem.elementKind
		var supplementaryItem = supplementaryItem
		supplementaryItem.itemIndex = supplementaryItems(of: kind).count
		supplementaryItem.sectionIndex = sectionIndex
		supplementaryItemsByKind.append(supplementaryItem, to: kind)
	}
	
	public mutating func mutateItems(using mutator: (item: inout LayoutItem, index: Int) -> Void) {
		for index in items.indices {
			mutator(item: &items[index], index: index)
		}
	}
	
	public mutating func mutateSupplementaryItems(using mutator: (supplementaryItem: inout LayoutSupplementaryItem, kind: String, index: Int) -> Void) {
		for (kind, supplementaryItems) in supplementaryItemsByKind {
			var supplementaryItems = supplementaryItems
			for index in supplementaryItems.indices {
				mutator(supplementaryItem: &supplementaryItems[index], kind: kind, index: index)
			}
			supplementaryItemsByKind[kind] = supplementaryItems
		}
	}
	
	public func supplementaryItems(of kind: String) -> [LayoutSupplementaryItem] {
		return supplementaryItemsByKind[kind] ?? []
	}
	
	public mutating func setSupplementaryItems(supplementaryItems: [LayoutSupplementaryItem], of kind: String) {
		var supplementaryItems = supplementaryItems
		for index in supplementaryItems.indices {
			supplementaryItems[index].itemIndex = index
			supplementaryItems[index].sectionIndex = sectionIndex
		}
		supplementaryItemsByKind[kind] = supplementaryItems
	}
	
	public mutating func reset() {
		items = []
		supplementaryItemsByKind = [:]
		
	}
	
	public mutating func setFrame(frame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		
	}
	
	public mutating func setSize(size: CGSize, forItemAt index: Int, invalidationContext: UICollectionViewLayoutInvalidationContext?) -> CGPoint {
		return CGPointZero
	}
	
	public mutating func setSize(size: CGSize, forSupplementaryElementOfKind kind: String, at index: Int, invalidationContext: UICollectionViewLayoutInvalidationContext?) -> CGPoint {
		return CGPointZero
	}
	
	public mutating func prepareForLayout() {
		
	}
	
	public mutating func finalizeLayoutAttributesForSectionsWithContent(sectionsWithContent: [LayoutSection]) {
		
	}
	
	public func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint, firstInsertedSectionMinY: CGFloat) -> CGPoint {
		return proposedContentOffset
	}
	
	public func targetLayoutHeightForProposedLayoutHeight(proposedHeight: CGFloat, layoutInfo: LayoutInfo) -> CGFloat {
		return proposedHeight
	}
	
	public mutating func updateSpecialItemsWithContentOffset(contentOffset: CGPoint, layoutInfo: LayoutInfo, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		
	}
	
	public mutating func applyValues(from metrics: LayoutMetrics) {
		
	}
	
	public func additionalLayoutAttributesToInsertForInsertionOfItem(at indexPath: NSIndexPath) -> [CollectionViewLayoutAttributes] {
		return []
	}
	
	public func additionalLayoutAttributesToDeleteForDeletionOfItem(at indexPath: NSIndexPath) -> [CollectionViewLayoutAttributes] {
		return []
	}
	
	public func layoutAttributesForCell(at indexPath: NSIndexPath) -> CollectionViewLayoutAttributes? {
		return nil
	}
	
	public func layoutAttributesForSupplementaryElementOfKind(kind: String, at indexPath: NSIndexPath) -> CollectionViewLayoutAttributes? {
		return nil
	}
	
	public func layoutAttributesForDecorationViewOfKind(kind: String, at indexPath: NSIndexPath) -> CollectionViewLayoutAttributes? {
		return nil
	}
	
}
