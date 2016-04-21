//
//  BasicLayoutSection.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 4/19/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public struct BasicLayoutSection: LayoutSection, LayoutSectionBaseComposite {
	
	public init(metrics: SectionMetrics) {
		self.metrics = metrics
	}
	
	public var layoutSectionBase = LayoutSectionBase()
	
	public var metrics: SectionMetrics
	
	public var items: [LayoutItem] = []
	
	public var decorationAttributesByKind: [String : [CollectionViewLayoutAttributes]] {
		return attributesForDecorationsByKind
	}
	
	// O(n^2)
	private var attributesForDecorationsByKind: [String: [CollectionViewLayoutAttributes]] {
		var attributesByKind: [String: [CollectionViewLayoutAttributes]] = [:]
		let insetFrame = UIEdgeInsetsInsetRect(frame, metrics.contentInset)
		
		for (kind, decorations) in decorationsByKind {
			for (index, decoration) in decorations.enumerate() {
				var decoration = decoration
				decoration.itemIndex = index
				decoration.sectionIndex = sectionIndex
				decoration.setContainerFrame(insetFrame, invalidationContext: nil)
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
	
	public mutating func setItem(item: LayoutItem, at index: Int) {
		var item = item
		item.sectionIndex = sectionIndex
		items[index] = item
	}
	
	public mutating func mutateItems(using mutator: (item: inout LayoutItem, index: Int) -> Void) {
		for index in items.indices {
			mutator(item: &items[index], index: index)
		}
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
