//
//  GridLayoutSection.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/16/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

private let sectionSeparatorTop = 0
private let sectionSeparatorBottom = 1

let separatorZIndex = 100
let sectionSeparatorZIndex = 2000

public let collectionElementKindLeftAuxiliaryItem = "collectionElementKindLeftAuxiliaryItem"
public let collectionElementKindRightAuxiliaryItem = "collectionElementKindRightAuxiliaryItem"

public protocol GridLayoutSection: LayoutSection {
	
	var metrics: GridSectionMetrics { get }
	
	var rows: [LayoutRow] { get }
	var leftAuxiliaryItems: [LayoutSupplementaryItem] { get }
	var rightAuxiliaryItems: [LayoutSupplementaryItem] { get }
	
	/// The width used to size each column.
	///
	/// When `fixedColumnWidth` from `metrics` is `nil`, the value returned will maximize the width of each column.
	/// Otherwise, `fixedColumnWidth` is returned.
	var columnWidth: CGFloat { get }
	var leftAuxiliaryColumnWidth: CGFloat { get }
	var rightAuxiliaryColumnWidth: CGFloat { get }
	
	var hasTopSectionSeparator: Bool { get }
	var hasBottomSectionSeparator: Bool { get }
	
	var shouldShowColumnSeparator: Bool { get }
	
	var phantomCellIndex: Int? { get set }
	var phantomCellSize: CGSize { get set }

	func add(row: LayoutRow)
	func removeAllRows()
	
}

public class BasicGridLayoutSection: NSObject, GridLayoutSection {
	
	static let hairline: CGFloat = 1.0 / UIScreen.mainScreen().scale
	
	public var frame = CGRectZero
	
	public var sectionIndex = 0
	
	public var isGlobalSection: Bool {
		return sectionIndex == GlobalSectionIndex
	}
	
	public weak var layoutInfo: LayoutInfo?
	
	public var items: [LayoutItem] = []
	
	public var supplementaryItems: [LayoutSupplementaryItem] {
		var allItems: [LayoutSupplementaryItem] = []
		for items in supplementaryItemsByKind.values {
			allItems += items
		}
		return allItems
	}
	
	public var supplementaryItemsByKind: [String: [LayoutSupplementaryItem]] = [:]
	
	public var headers: [LayoutSupplementaryItem] {
		return supplementaryItems(of: UICollectionElementKindSectionHeader)
	}
	
	public var footers: [LayoutSupplementaryItem] {
		return supplementaryItems(of: UICollectionElementKindSectionFooter)
	}
	
	private var otherSupplementaryItems: [LayoutSupplementaryItem] = []
	
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
		return height(of: nonPinnableHeaders)
	}
	
	public var heightOfPinningHeaders: CGFloat {
		return height(of: pinnableHeaders)
	}
	
	private func height(of supplementaryItems: [LayoutSupplementaryItem]) -> CGFloat {
		guard !supplementaryItems.isEmpty else {
			return 0
		}
		var minY = CGFloat.max
		var maxY = CGFloat.min
		
		for supplementaryItem in supplementaryItems {
			let frame = supplementaryItem.frame
			minY = min(minY, frame.minY)
			maxY = max(maxY, frame.maxY)
		}
		
		return maxY - minY
	}
	
	public var decorationViewClassesByKind: [String: AnyClass] {
		return [:]
	}
	
	public let metrics: GridSectionMetrics = BasicGridSectionMetrics()
	
	public var rows: [LayoutRow] = []
	
	public var leftAuxiliaryItems: [LayoutSupplementaryItem] {
		return supplementaryItems(of: collectionElementKindLeftAuxiliaryItem)
	}
	
	public var rightAuxiliaryItems: [LayoutSupplementaryItem] {
		return supplementaryItems(of: collectionElementKindRightAuxiliaryItem)
	}
	
	public var columnWidth: CGFloat {
		return metrics.fixedColumnWidth ?? maximizedColumnWidth
	}
	private var maximizedColumnWidth: CGFloat {
		let layoutWidth = frame.width
		let margins = metrics.padding
		let numberOfColumns = metrics.numberOfColumns
		let columnWidth = (layoutWidth - margins.left - margins.right) / CGFloat(numberOfColumns)
		return columnWidth
	}
	public var leftAuxiliaryColumnWidth: CGFloat = 0
	public var rightAuxiliaryColumnWidth: CGFloat = 0
	
	public var phantomCellIndex: Int?
	public var phantomCellSize = CGSizeZero
	
	public var layoutAttributes: [UICollectionViewLayoutAttributes] {
		var layoutAttributes: [UICollectionViewLayoutAttributes] = []
		
		if let backgroundAttribute = self.backgroundAttribute {
			layoutAttributes.append(backgroundAttribute)
		}
		
		for (_, attributes) in sectionSeparatorLayoutAttributes {
			layoutAttributes.append(attributes)
		}
		
		layoutAttributes += columnSeparatorLayoutAttributes
		
		for supplementaryItem in supplementaryItems {
			// Don't enumerate hidden or 0 height supplementary items
			guard !supplementaryItem.isHidden && (supplementaryItem.height ?? 0) > 0 else {
				continue
			}
			
			// For non-global sections, don't enumerate if there are no items and not marked as visible when showing placeholder
			guard isGlobalSection || numberOfItems > 0 || supplementaryItem.isVisibleWhileShowingPlaceholder else {
				continue
			}
			
			layoutAttributes.append(supplementaryItem.layoutAttributes)
		}
		
		if let placeholderInfo = self.placeholderInfo where placeholderInfo.startingSectionIndex == sectionIndex {
			layoutAttributes.append(placeholderInfo.layoutAttributes)
		}
		
		for row in rows {
			if let attributes = row.rowSeparatorLayoutAttributes {
				layoutAttributes.append(attributes)
			}
			
			layoutAttributes += row.items.map { $0.layoutAttributes }
		}
		
		return layoutAttributes
	}
	
	public var shouldShowColumnSeparator: Bool {
		return metrics.numberOfColumns > 1 && metrics.separatorColor != nil && metrics.showsColumnSeparator && items.count > 0
	}
	
	private var columnSeparatorLayoutAttributes: [UICollectionViewLayoutAttributes] = []
	
	private var sectionSeparatorLayoutAttributes: [Int: UICollectionViewLayoutAttributes] = [:]
	
	public var hasTopSectionSeparator: Bool {
		return sectionSeparatorLayoutAttributes[sectionSeparatorTop] != nil
	}
	
	public var hasBottomSectionSeparator: Bool {
		return sectionSeparatorLayoutAttributes[sectionSeparatorBottom] != nil
	}
	
	public var backgroundAttribute: UICollectionViewLayoutAttributes? {
		if let backgroundAttribute = _backgroundAttribute {
			return backgroundAttribute
		}
		
		// Only have background attribute on global section
		guard sectionIndex == GlobalSectionIndex else {
			return nil
		}
		
		guard let backgroundColor = metrics.backgroundColor else {
			return nil
		}
		
		let indexPath = NSIndexPath(index: 0)
		let backgroundAttribute = CollectionViewLayoutAttributes(forDecorationViewOfKind: collectionElementKindGlobalHeaderBackground, withIndexPath: indexPath)
		
		// This will be updated by -updateSpecialItemsWithContentOffset
		backgroundAttribute.frame = frame
		backgroundAttribute.unpinnedOrigin = frame.origin
		backgroundAttribute.zIndex = defaultZIndex
		backgroundAttribute.isPinned = false
		backgroundAttribute.hidden = false
		backgroundAttribute.backgroundColor = backgroundColor
		
		return _backgroundAttribute
	}
	private var _backgroundAttribute: UICollectionViewLayoutAttributes?
	
	public func add(item: LayoutItem) {
		item.itemIndex = items.count
		items.append(item)
	}
	
	public func add(supplementaryItem: LayoutSupplementaryItem) {
		let kind = supplementaryItem.elementKind
		var items = supplementaryItems(of: kind)
		supplementaryItem.itemIndex = items.count
		supplementaryItem.section = self
		items.append(supplementaryItem)
		supplementaryItemsByKind[kind] = items
	}
	
	public func supplementaryItems(of kind: String) -> [LayoutSupplementaryItem] {
		return supplementaryItemsByKind[kind] ?? []
	}
	
	public func add(row: LayoutRow) {
		row.section = self
		
		let rowIndex = rows.count
		let separatorColor = metrics.separatorColor
		
		// Create the row separator if there isn't already one
		if metrics.showsRowSeparator && row.rowSeparatorLayoutAttributes == nil {
			let indexPath = NSIndexPath(forItem: rowIndex, inSection: sectionIndex)
			var rowFrame = row.frame
			let bottomY = rowFrame.maxY
			
			let separatorAttributes = CollectionViewLayoutAttributes(forDecorationViewOfKind: collectionElementKindRowSeparator, withIndexPath: indexPath)
			let separatorInsets = metrics.separatorInsets
			let hairline = self.dynamicType.hairline
			separatorAttributes.frame = CGRect(x: separatorInsets.left, y: bottomY, width: rowFrame.width - separatorInsets.left - separatorInsets.right, height: hairline)
			separatorAttributes.backgroundColor = separatorColor
			separatorAttributes.zIndex = separatorZIndex
			row.rowSeparatorLayoutAttributes = separatorAttributes
			rowFrame.size.height += hairline
			row.frame = rowFrame
		}
		
		rows.append(row)
	}
	
	public func removeAllRows() {
		rows.removeAll(keepCapacity: true)
	}
	
	public func reset() {
		items.removeAll(keepCapacity: true)
		supplementaryItemsByKind = [:]
		_backgroundAttribute = nil
		rows.removeAll(keepCapacity: true)
		columnSeparatorLayoutAttributes.removeAll(keepCapacity: true)
	}
	
	public func applyValues(from metrics: LayoutMetrics) {
		self.metrics.applyValues(from: metrics)
		if let gridMetrics = metrics as? GridSectionMetrics {
			self.metrics.applyValues(from: gridMetrics)
		} else if let gridSection = metrics as? GridLayoutSection {
			self.metrics.applyValues(from: gridSection.metrics)
		}
	}
	
	public func resolveMissingValuesFromTheme() {
		metrics.resolveMissingValuesFromTheme()
	}
	
	public func layoutWithOrigin(start: CGPoint, layoutSizing: LayoutSizing,  invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) -> CGPoint {
		let layoutEngine = GridSectionLayoutEngine(layoutSection: self)
		let endPoint = layoutEngine.layoutWithOrigin(start, layoutSizing: layoutSizing, invalidationContext: invalidationContext)
		pinnableHeaders = layoutEngine.pinnableHeaders
		nonPinnableHeaders = layoutEngine.nonPinnableHeaders
		return endPoint
	}
	
	public func setFrame(frame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		guard frame != self.frame else {
			return
		}
		
		let offset = CGPoint(x: frame.origin.x - self.frame.origin.x, y: frame.origin.y - self.frame.origin.y)
		
		for row in rows {
			let rowFrame = CGRectOffset(row.frame, offset.x, offset.y)
			row.setFrame(rowFrame, invalidationContext: invalidationContext)
		}
		
		func offsetDecoration(attributes: UICollectionViewLayoutAttributes) {
			attributes.frame = CGRectOffset(attributes.frame, offset.x, offset.y)
			invalidationContext?.invalidateDecorationElement(with: attributes)
		}
		
		for attributes in columnSeparatorLayoutAttributes {
			offsetDecoration(attributes)
		}
		
		for (_, attributes) in sectionSeparatorLayoutAttributes {
			offsetDecoration(attributes)
		}
		
		layoutSection(self, setFrame: frame, invalidationContext: invalidationContext)
	}
	
	public func setSize(size: CGSize, forItemAt index: Int, invalidationContext: UICollectionViewLayoutInvalidationContext?) -> CGPoint {
		let itemInfo = items[index]
		var itemFrame = itemInfo.frame
		guard size != itemFrame.size, let rowInfo = itemInfo.row else {
			return CGPointZero
		}
		
		itemFrame.size = size
		itemInfo.setFrame(itemFrame, invalidationContext: invalidationContext)
		
		// Items in a row are always the same height
		var rowFrame = rowInfo.frame
		let originalRowHeight = rowFrame.height
		var newRowHeight: CGFloat = 0
		
		// Calculate the max row height based on the current collection of items
		for rowItemInfo in rowInfo.items {
			newRowHeight = max(newRowHeight, rowItemInfo.frame.height)
		}
		
		// If the height of the row hasn't changed, then nothing else needs to move
		guard newRowHeight != originalRowHeight else {
			return CGPointZero
		}
		
		let offsetPosition = CGPoint(x: 0, y: rowFrame.maxY)
		let sizeDelta = CGPoint(x: 0, y: newRowHeight - originalRowHeight)
		
		rowFrame.size.height += sizeDelta.y
		rowInfo.frame = rowFrame
		
		offsetContentAfterPosition(offsetPosition, offset: sizeDelta, invalidationContext: invalidationContext)
		updateColumnSeparators(with: invalidationContext)
		
		return sizeDelta
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
	
	func offsetContentAfterPosition(origin: CGPoint, offset: CGPoint, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		func shouldOffsetAttributes(with frame: CGRect) -> Bool {
			return frame.minY >= origin.y
		}
		
		func conditionallyOffsetDecoration(attributes: UICollectionViewLayoutAttributes) {
			let frame = attributes.frame
			guard shouldOffsetAttributes(with: frame),
				let kind = attributes.representedElementKind else {
					return
			}
			attributes.frame = CGRectOffset(frame, offset.x, offset.y)
			invalidationContext?.invalidateDecorationElementsOfKind(kind, atIndexPaths: [attributes.indexPath])
		}
		
		layoutSection(self, offsetContentAfter: origin, with: offset, invalidationContext: invalidationContext)
		
		for attributes in columnSeparatorLayoutAttributes {
			conditionallyOffsetDecoration(attributes)
		}
		
		for attributes in sectionSeparatorLayoutAttributes.values {
			conditionallyOffsetDecoration(attributes)
		}
		
		for row in rows {
			var rowFrame = row.frame
			guard shouldOffsetAttributes(with: rowFrame) else {
				continue
			}
			rowFrame = CGRectOffset(rowFrame, offset.x, offset.y)
			row.setFrame(rowFrame, invalidationContext: invalidationContext)
		}
	}
	
	func updateColumnSeparators(with invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) {
		guard shouldShowColumnSeparator else {
			return
		}
		
		guard let firstRow = rows.first,
			lastRow = rows.last else {
				return
		}
		
		let hairline = self.dynamicType.hairline
		
		let columnWidth = self.columnWidth
	
		let top = firstRow.frame.minY
		let bottom = lastRow.frame.maxY
		let numberOfColumns = metrics.numberOfColumns
		
		columnSeparatorLayoutAttributes = []
		
		for columnIndex in 0..<numberOfColumns {
			let indexPath = NSIndexPath(forItem: columnIndex, inSection: sectionIndex)
			let separatorAttributes = CollectionViewLayoutAttributes(forDecorationViewOfKind: collectionElementKindColumnSeparator, withIndexPath: indexPath)
			let separatorFrame = CGRect(x: columnWidth * CGFloat(columnIndex), y: top, width: hairline, height: bottom - top)
			separatorAttributes.frame = separatorFrame
			separatorAttributes.backgroundColor = metrics.separatorColor
			separatorAttributes.zIndex = separatorZIndex
			
			columnSeparatorLayoutAttributes.append(separatorAttributes)
			
			invalidationContext?.invalidateDecorationElementsOfKind(separatorAttributes.representedElementKind!, atIndexPaths: [separatorAttributes.indexPath])
		}
	}
	
	/// Create any additional layout attributes, this requires knowing what sections actually have any content.
	public func finalizeLayoutAttributesForSectionsWithContent(sectionsWithContent: NSIndexSet) {
		let shouldShowSectionSeparators = metrics.showsSectionSeparator && items.count > 0
		
		// Hide the row separator for the last row in the section
		if metrics.showsRowSeparator, let row = rows.last {
			row.rowSeparatorLayoutAttributes?.hidden = true
		}
		
		if shouldShowSectionSeparators {
			updateSectionSeparatorsForSectionsWithContent(sectionsWithContent)
		}
		
		updateColumnSeparators()
	}
	
	private func updateSectionSeparatorsForSectionsWithContent(sectionsWithContent: NSIndexSet) {
		// Show the section separators
		sectionSeparatorLayoutAttributes = [:]
		
		if shouldCreateTopSectionSeparatorForSectionsWithContent(sectionsWithContent) {
			updateSectionSeparatorAttributes(sectionSeparatorTop)
		}
		
		if shouldCreateBottomSectionSeparatorForSectionsWithContent(sectionsWithContent) {
			updateSectionSeparatorAttributes(sectionSeparatorBottom)
		}
	}
	
	/// Only need to show the top separator when there is a section with content before this one, but it doesn't have a bottom separator already.
	private func shouldCreateTopSectionSeparatorForSectionsWithContent(sectionsWithContent: NSIndexSet) -> Bool {
		let previousSectionIndexWithContent = sectionsWithContent.indexLessThanIndex(sectionIndex)
		let hasPreviousSectionWithContent = previousSectionIndexWithContent != NSNotFound
		if hasPreviousSectionWithContent,
			let previousSectionWithContent = layoutInfo?.sectionAtIndex(previousSectionIndexWithContent) as? GridLayoutSection
			where !previousSectionWithContent.hasBottomSectionSeparator {
				return true
		}
		return false
	}
	
	/// Only need to show the bottom separator when there is another section with content after this one that doesn't have a top separator OR we've been explicitly told to show the section separator when this is the last section.
	private func shouldCreateBottomSectionSeparatorForSectionsWithContent(sectionsWithContent: NSIndexSet) -> Bool {
		let nextSectionIndexWithContent = sectionsWithContent.indexGreaterThanIndex(sectionIndex)
		let hasNextSectionWithContent = nextSectionIndexWithContent != NSNotFound
		if hasNextSectionWithContent,
			let nextSectionWithContent = layoutInfo?.sectionAtIndex(nextSectionIndexWithContent) as? GridLayoutSection
			where !nextSectionWithContent.hasTopSectionSeparator {
				return true
		} else if metrics.showsSectionSeparatorWhenLastSection {
			return true
		}
		return false
	}
	
	private func updateSectionSeparatorAttributes(sectionSeparator: Int) {
		let separatorAttributes = createSectionSeparatorAttributes(sectionSeparator)
		sectionSeparatorLayoutAttributes[sectionSeparator] = separatorAttributes
	}
	
	private func createSectionSeparatorAttributes(sectionSeparator: Int) -> UICollectionViewLayoutAttributes {
		let indexPath = NSIndexPath(forItem: sectionSeparatorTop, inSection: sectionIndex)
		let separatorAttributes = CollectionViewLayoutAttributes(forDecorationViewOfKind: collectionElementKindSectionSeparator, withIndexPath: indexPath)
		separatorAttributes.frame = frameForSectionSeparator(sectionSeparator)
		separatorAttributes.backgroundColor = metrics.sectionSeparatorColor
		separatorAttributes.zIndex = sectionSeparatorZIndex
		return separatorAttributes
	}
	
	private func frameForSectionSeparator(sectionSeparator: Int) -> CGRect {
		let sectionSeparatorInsets = metrics.sectionSeparatorInsets
		let frame = self.frame
		let hairline = self.dynamicType.hairline
		
		let x = sectionSeparatorInsets.left
		let y = (sectionSeparator == sectionSeparatorTop) ? frame.origin.y : frame.maxY
		let width = frame.width - sectionSeparatorInsets.left - sectionSeparatorInsets.right
		let height = hairline
		
		return CGRect(x: x, y: y, width: width, height: height)
	}
	
	public func layoutAttributesForCell(at indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
		let itemIndex = indexPath.itemIndex
		guard placeholderInfo != nil || itemIndex < items.count else {
			return nil
		}
		let itemInfo = items[itemIndex]
		return itemInfo.layoutAttributes
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
	
	public func layoutAttributesForDecorationViewOfKind(kind: String, at indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
		let itemIndex = indexPath.itemIndex
		switch kind {
		case collectionElementKindColumnSeparator:
			guard itemIndex < columnSeparatorLayoutAttributes.count else {
				return nil
			}
			return columnSeparatorLayoutAttributes[itemIndex]
		case collectionElementKindSectionSeparator:
			return sectionSeparatorLayoutAttributes[itemIndex]
		case collectionElementKindRowSeparator:
			guard itemIndex < rows.count else {
				return nil
			}
			let rowInfo = rows[itemIndex]
			return rowInfo.rowSeparatorLayoutAttributes
		case collectionElementKindGlobalHeaderBackground:
			return backgroundAttribute
		default:
			return nil
		}
	}
	
	public func definesMetric(metric: String) -> Bool {
		return metrics.definesMetric(metric)
	}
	
	public func additionalLayoutAttributesToInsertForInsertionOfItem(at indexPath: NSIndexPath) -> [UICollectionViewLayoutAttributes] {
		return []
	}
	
	public func additionalLayoutAttributesToDeleteForDeletionOfItem(at indexPath: NSIndexPath) -> [UICollectionViewLayoutAttributes] {
		var attributes: [UICollectionViewLayoutAttributes] = []
		
		if let rowSeparator = rowSeparatorAttributesToDeleteForDeletionOfItem(at: indexPath) {
			attributes.append(rowSeparator)
		}
		
		return attributes
	}
	
	private func rowSeparatorAttributesToDeleteForDeletionOfItem(at indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
		guard metrics.showsRowSeparator else {
			return nil
		}
		
		let itemInfo = items[indexPath.item]
		
		guard let rowInfo = itemInfo.row,
			rowSeparatorAttributes = rowInfo.rowSeparatorLayoutAttributes
			where rowInfo.items.count == 1 else {
				return nil
		}
		
		return rowSeparatorAttributes
	}
	
}
