//
//  LayoutSection.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/11/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public protocol LayoutSection: LayoutMetrics, LayoutEngine, LayoutAttributesResolving {
	
	var frame: CGRect { get set }
	var sectionIndex: Int { get set }
	
	var isGlobalSection: Bool { get }
	
	var layoutInfo: LayoutInfo? { get set }
	
	var items: [LayoutItem] { get }
	var supplementaryItems: [LayoutSupplementaryItem] { get }
	var headers: [LayoutSupplementaryItem] { get }
	var footers: [LayoutSupplementaryItem] { get }
	
	var backgroundAttribute: UICollectionViewLayoutAttributes? { get }
	
	var placeholderInfo: LayoutPlaceholder? { get set }
	
	var pinnableHeaders: [LayoutSupplementaryItem] { get set }
	var nonPinnableHeaders: [LayoutSupplementaryItem] { get set }
	
	var heightOfNonPinningHeaders: CGFloat { get }
	
	/// All the layout attributes associated with this section.
	var layoutAttributes: [UICollectionViewLayoutAttributes] { get }
	
	var decorationViewClassesByKind: [String: AnyClass] { get }
	
	func add(supplementaryItem: LayoutSupplementaryItem)
	func add(item: LayoutItem)
	
	/// Update the frame of this grouped object and any child objects. Use the invalidation context to mark layout objects as invalid.
	func setFrame(frame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext?)
	
	/// Reset the content of this section.
	func reset()
	
	func finalizeLayoutAttributesForSectionsWithContent(sectionsWithContent: NSIndexSet)
	
	func setSize(size: CGSize, forItemAt index: Int, invalidationContext: UICollectionViewLayoutInvalidationContext?) -> CGPoint
	
	func setSize(size: CGSize, forSupplementaryElementOfKind kind: String, at index: Int, invalidationContext: UICollectionViewLayoutInvalidationContext?) -> CGPoint
	
	func setSize(size: CGSize, forHeaderAt index: Int, invalidationContext: UICollectionViewLayoutInvalidationContext?) -> CGPoint
	
	func setSize(size: CGSize, forFooterAt index: Int, invalidationContext: UICollectionViewLayoutInvalidationContext?) -> CGPoint
	
}

extension LayoutSection {
	
	public var numberOfItems: Int {
		return items.count
	}
	
}

public protocol LayoutEngine: NSObjectProtocol {
	
	/// Layout this section with the given starting origin and using the invalidation context to record cells and supplementary views that should be redrawn.
	func layoutWithOrigin(origin: CGPoint, layoutSizing: LayoutSizing, invalidationContext: UICollectionViewLayoutInvalidationContext?) -> CGPoint
	
}

// TODO: This logic should go in a protocol extension once that feature stabilizes.
public class AbstractLayoutSection: NSObject, LayoutSection {
	
	public var frame = CGRectZero
	
	public var sectionIndex = 0
	
	public var isGlobalSection: Bool {
		return sectionIndex == GlobalSectionIndex
	}
	
	public weak var layoutInfo: LayoutInfo?
	
	public var items: [LayoutItem] = []
	
	public var supplementaryItems: [LayoutSupplementaryItem] {
		return headers + footers + otherSupplementaryItems
	}
	
	public var headers: [LayoutSupplementaryItem] = []
	
	public var footers: [LayoutSupplementaryItem] = []
	
	private var otherSupplementaryItems: [LayoutSupplementaryItem] = []
	
	public var backgroundAttribute: UICollectionViewLayoutAttributes? {
		if let backgroundAttribute = _backgroundAttribute {
			return backgroundAttribute
		}
		
		// Only have background attribute on global section
		guard sectionIndex == GlobalSectionIndex else {
			return nil
		}
		
		let indexPath = NSIndexPath(index: 0)
		let backgroundAttribute = CollectionViewLayoutAttributes(forDecorationViewOfKind: collectionElementKindGlobalHeaderBackground, withIndexPath: indexPath)
		
		// This will be updated by -filterSpecialAttributes
		backgroundAttribute.frame = frame
		backgroundAttribute.unpinnedOffset.y = frame.minY
		backgroundAttribute.zIndex = defaultZIndex
		backgroundAttribute.isPinned = false
		backgroundAttribute.hidden = false
		
		_backgroundAttribute = backgroundAttribute
		return _backgroundAttribute
	}
	
	private var _backgroundAttribute: UICollectionViewLayoutAttributes?
	
	public var placeholderInfo: LayoutPlaceholder? {
		didSet {
			guard placeholderInfo !== oldValue else {
				return
			}
			placeholderInfo?.wasAddedToSection(self)
		}
	}
	
	public var pinnableHeaders: [LayoutSupplementaryItem] = []
	
	public var nonPinnableHeaders: [LayoutSupplementaryItem] = []
	
	public var heightOfNonPinningHeaders: CGFloat {
		guard !nonPinnableHeaders.isEmpty else {
			return 0
		}
		var minY = CGFloat.max
		var maxY = CGFloat.min
		
		for supplementaryItem in nonPinnableHeaders {
			let frame = supplementaryItem.frame
			minY = min(minY, frame.minY)
			maxY = max(maxY, frame.maxY)
		}
		
		return maxY - minY
	}
	
	public var layoutAttributes: [UICollectionViewLayoutAttributes] {
		var layoutAttributes: [UICollectionViewLayoutAttributes] = []
		
//		layoutAttributes += items.map { $0.layoutAttributes }
		
		if let backgroundAttribute = self.backgroundAttribute {
			layoutAttributes.append(backgroundAttribute)
		}
		
		for supplementaryItem in supplementaryItems {
			// Don't enumerate hidden or 0 height supplementary items
			if supplementaryItem.isHidden || (supplementaryItem.fixedHeight ?? -1) == 0 {
				continue
			}
			
			// For non-global sections, don't enumerate if there are no items and not marked as visible when showing placeholder
			if !isGlobalSection && numberOfItems == 0 && !supplementaryItem.isVisibleWhileShowingPlaceholder {
				continue
			}
			
			layoutAttributes.append(supplementaryItem.layoutAttributes)
		}
		
		if let placeholderInfo = self.placeholderInfo where placeholderInfo.startingSectionIndex == sectionIndex {
			layoutAttributes.append(placeholderInfo.layoutAttributes)
		}
		
		return layoutAttributes
	}
	
	public var decorationViewClassesByKind: [String: AnyClass] {
		return [:]
	}
	
	public func add(supplementaryItem: LayoutSupplementaryItem) {
		switch supplementaryItem.elementKind {
		case UICollectionElementKindSectionHeader:
			supplementaryItem.itemIndex = headers.count
			headers.append(supplementaryItem)
		case UICollectionElementKindSectionFooter:
			supplementaryItem.itemIndex = footers.count
			footers.append(supplementaryItem)
		default:
			// TODO: Handle itemIndex
			otherSupplementaryItems.append(supplementaryItem)
		}
		supplementaryItem.section = self
	}
	
	public func add(item: LayoutItem) {
		item.itemIndex = items.count
		items.append(item)
	}
	
	public func setFrame(frame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) {
		guard frame != self.frame else {
			return
		}
		let offset = CGPoint(x: frame.origin.x - self.frame.origin.x, y: frame.origin.y - self.frame.origin.y)
		
		for supplementaryItem in supplementaryItems {
			let supplementaryFrame = CGRectOffset(supplementaryItem.frame, offset.x, offset.y)
			supplementaryItem.setFrame(supplementaryFrame, invalidationContext: invalidationContext)
		}
		
		if let backgroundAttribute = self.backgroundAttribute {
			let backgroundRect = CGRectOffset(backgroundAttribute.frame, offset.x, offset.y)
			backgroundAttribute.frame = backgroundRect
			invalidationContext?.invalidateDecorationElementsOfKind(backgroundAttribute.representedElementKind!, atIndexPaths: [backgroundAttribute.indexPath])
		}
		
		self.frame = frame
	}
	
	public func layoutWithOrigin(origin: CGPoint, layoutSizing: LayoutSizing, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) -> CGPoint {
		// Subclasses should override to layout the section
		return CGPointZero
	}
	
	public func reset() {
		items.removeAll(keepCapacity: true)
		headers.removeAll(keepCapacity: true)
		footers.removeAll(keepCapacity: true)
		_backgroundAttribute = nil
	}
	
	public func applyValues(from metrics: LayoutMetrics) {
		// Subclasses should override
	}
	
	public func resolveMissingValuesFromTheme() {
		
	}
	
	public func definesMetric(metric: String) -> Bool {
		return false
	}
	
	public func layoutAttributesForCell(at indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
		let itemIndex = self.itemIndex(of: indexPath)
		guard placeholderInfo != nil || itemIndex < items.count else {
			return nil
		}
		let itemInfo = items[itemIndex]
		return itemInfo.layoutAttributes
	}
	
	public func layoutAttributesForDecorationViewOfKind(kind: String, at indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
		if kind == collectionElementKindGlobalHeaderBackground {
			return backgroundAttribute
		}
		
		return nil
	}
	
	public func layoutAttributesForSupplementaryElementOfKind(kind: String, at indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
		if kind == CollectionElementKindPlaceholder {
			return placeholderInfo?.layoutAttributes
		}
		
		let itemIndex = indexPath.itemIndex
		let supplementaryItem: LayoutSupplementaryItem
		
		if kind == UICollectionElementKindSectionHeader {
			guard itemIndex < headers.count else {
				return nil
			}
			supplementaryItem = headers[itemIndex]
		} else if kind == UICollectionElementKindSectionFooter {
			guard itemIndex < footers.count else {
				return nil
			}
			supplementaryItem = footers[itemIndex]
		} else {
			// TODO: Handle other kinds
			return nil
		}
		
		// There's no layout attributes if this section isn't the global section, there are no items and the supplementary item shouldn't be shown when the placeholder is visible (e.g. no items)
		guard isGlobalSection || items.count > 0 || supplementaryItem.isVisibleWhileShowingPlaceholder else {
			return nil
		}
		
		return supplementaryItem.layoutAttributes
	}
	
	public func finalizeLayoutAttributesForSectionsWithContent(sectionsWithContent: NSIndexSet) {
		// Subclasses should override
	}
	
	public func setSize(size: CGSize, forItemAt index: Int, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) -> CGPoint {
		// Subclasses should override
		return CGPointZero
	}
	
	public func setSize(size: CGSize, forSupplementaryElementOfKind kind: String, at index: Int, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) -> CGPoint {
		if kind == UICollectionElementKindSectionHeader {
			return setSize(size, forHeaderAt: index, invalidationContext: invalidationContext)
		} else if kind == UICollectionElementKindSectionFooter {
			return setSize(size, forFooterAt: index, invalidationContext: invalidationContext)
		} else {
			return CGPointZero
		}
	}
	
	public func setSize(size: CGSize, forHeaderAt index: Int, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) -> CGPoint {
		let headerInfo = headers[index]
		return setSize(size, of: headerInfo, invalidationContext: invalidationContext)
	}
	
	public func setSize(size: CGSize, forFooterAt index: Int, invalidationContext: UICollectionViewLayoutInvalidationContext?) -> CGPoint {
		let footerInfo = footers[index]
		return setSize(size, of: footerInfo, invalidationContext: invalidationContext)
	}
	
	func setSize(size: CGSize, of supplementaryItem: LayoutSupplementaryItem, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) -> CGPoint {
		var frame = supplementaryItem.frame
		let after = CGPoint(x: 0, y: frame.maxY)
		
		let sizeDelta = CGPoint(x: 0, y: size.height - frame.height)
		frame.size = size
		supplementaryItem.setFrame(frame, invalidationContext: invalidationContext)
		
		guard sizeDelta != CGPointZero else {
			return CGPointZero
		}
		
		offsetContentAfterPosition(after, offset: sizeDelta, invalidationContext: invalidationContext)
		return sizeDelta
	}
	
	func offsetContentAfterPosition(origin: CGPoint, offset: CGPoint, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) {
		for supplementaryItem in supplementaryItems {
			var supplementaryFrame = supplementaryItem.frame
			if supplementaryFrame.minX < origin.x || supplementaryFrame.minY < origin.y {
				continue
			}
			supplementaryFrame = CGRectOffset(supplementaryFrame, offset.x, offset.y)
			supplementaryItem.setFrame(supplementaryFrame, invalidationContext: invalidationContext)
		}
		
		for item in items {
			var itemFrame = item.frame
			if itemFrame.minX < origin.x || itemFrame.minY < origin.y {
				continue
			}
			itemFrame = CGRectOffset(itemFrame, offset.x, offset.y)
			item.setFrame(itemFrame, invalidationContext: invalidationContext)
		}
	}
	
	private func itemIndex(of indexPath: NSIndexPath) -> Int {
		return indexPath.length > 1 ? indexPath.item : indexPath.indexAtPosition(0)
	}
	
}

public protocol SectionLayoutHelper: NSObjectProtocol {
	
	func layoutWithOrigin(start: CGPoint, invalidationContext: UICollectionViewLayoutInvalidationContext?) -> CGPoint
	
}
