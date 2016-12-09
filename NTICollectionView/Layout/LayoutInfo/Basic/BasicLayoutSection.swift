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
	fileprivate var attributesForDecorationsByKind: [String: [CollectionViewLayoutAttributes]] {
		var attributesByKind: [String: [CollectionViewLayoutAttributes]] = [:]
		let insetFrame = UIEdgeInsetsInsetRect(frame, metrics.contentInset)
		
		for (kind, decorations) in decorationsByKind {
			for (index, decoration) in decorations.enumerated() {
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
			
			if let oldValue = oldValue, placeholderInfo.isEqual(to: oldValue) {
				return
			}
			
			placeholderInfo.wasAddedToSection(self)
		}
	}
	
	public var shouldResizePlaceholder: Bool {
		return metrics.shouldResizePlaceholder
	}
	
	public mutating func add(_ item: LayoutItem) {
		var item = item
		item.sectionIndex = sectionIndex
		items.append(item)
		
	}
	
	public mutating func setItem(_ item: LayoutItem, at index: Int) {
		var item = item
		item.sectionIndex = sectionIndex
		items[index] = item
	}
	
	public mutating func mutateItem(at index: Int, using mutator: (inout LayoutItem) -> Void) {
		var item = items[index]
		mutator(&item)
		items[index] = item
	}
	
	public mutating func mutateItems(using mutator: (_ item: inout LayoutItem, _ index: Int) -> Void) {
		for index in items.indices {
			mutator(&items[index], index)
		}
	}
	
	public func shouldShow(_ supplementaryItem: SupplementaryItem) -> Bool {
		return isGlobalSection || numberOfItems > 0 || supplementaryItem.isVisibleWhileShowingPlaceholder
	}
	
	public mutating func reset() {
		items = []
		supplementaryItemsByKind = [:]
		
	}
	
	public mutating func setFrame(_ frame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		
	}
	
	public mutating func setSize(_ size: CGSize, forItemAt index: Int, invalidationContext: UICollectionViewLayoutInvalidationContext?) -> CGPoint {
		return CGPoint.zero
	}
	
	public mutating func setSize(_ size: CGSize, forSupplementaryElementOfKind kind: String, at index: Int, invalidationContext: UICollectionViewLayoutInvalidationContext?) -> CGPoint {
		return CGPoint.zero
	}
	
	public mutating func prepareForLayout() {
		
	}
	
	public mutating func finalizeLayoutAttributesForSectionsWithContent(_ sectionsWithContent: [LayoutSection]) {
		
	}
	
	public func targetContentOffsetForProposedContentOffset(_ proposedContentOffset: CGPoint, firstInsertedSectionMinY: CGFloat) -> CGPoint {
		return proposedContentOffset
	}
	
	public func targetLayoutHeightForProposedLayoutHeight(_ proposedHeight: CGFloat, layoutInfo: LayoutInfo) -> CGFloat {
		return proposedHeight
	}
	
	public mutating func updateSpecialItemsWithContentOffset(_ contentOffset: CGPoint, layoutInfo: LayoutInfo, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		
	}
	
	public mutating func applyValues(from metrics: LayoutMetrics) {
		
	}
	
	public func additionalLayoutAttributesToInsertForInsertionOfItem(at indexPath: IndexPath) -> [CollectionViewLayoutAttributes] {
		return []
	}
	
	public func additionalLayoutAttributesToDeleteForDeletionOfItem(at indexPath: IndexPath) -> [CollectionViewLayoutAttributes] {
		return []
	}
	
	public func layoutAttributesForCell(at indexPath: IndexPath) -> CollectionViewLayoutAttributes? {
		return nil
	}
	
	public func layoutAttributesForSupplementaryElementOfKind(_ kind: String, at indexPath: IndexPath) -> CollectionViewLayoutAttributes? {
		return nil
	}
	
	public func layoutAttributesForDecorationViewOfKind(_ kind: String, at indexPath: IndexPath) -> CollectionViewLayoutAttributes? {
		return nil
	}
	
	public func isEqual(to other: LayoutSection) -> Bool {
		guard let other = other as? BasicLayoutSection else {
			return false
		}
		
		return sectionIndex == other.sectionIndex
	}
	
}
