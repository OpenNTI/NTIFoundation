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

public protocol GridLayoutSection: LayoutSection {
	
	var metrics: GridSectionMetrics { get }
	
	var rows: [LayoutRow] { get }
	var leftAuxiliaryItems: [LayoutSupplementaryItem] { get set }
	var rightAuxiliaryItems: [LayoutSupplementaryItem] { get set }
	
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

public class BasicGridLayoutSection: AbstractLayoutSection, GridLayoutSection {
	
	static let hairline: CGFloat = 1.0 / UIScreen.mainScreen().scale
	
	public override init() {
		super.init()
		layoutHelper = GridSectionLayoutEngine(layoutSection: self)
	}
	
	var layoutHelper: GridSectionLayoutEngine!
	
	public let metrics: GridSectionMetrics = BasicGridSectionMetrics()
	
	public var rows: [LayoutRow] = []
	public var leftAuxiliaryItems: [LayoutSupplementaryItem] = []
	public var rightAuxiliaryItems: [LayoutSupplementaryItem] = []
	
	public var columnWidth: CGFloat {
		return metrics.fixedColumnWidth ?? maximizedColumnWidth
	}
	private var maximizedColumnWidth: CGFloat {
		let layoutWidth = layoutInfo?.width ?? 0
		let margins = metrics.padding
		let numberOfColumns = metrics.numberOfColumns
		let columnWidth = (layoutWidth - margins.left - margins.right) / CGFloat(numberOfColumns)
		return columnWidth
	}
	public var leftAuxiliaryColumnWidth: CGFloat = 0
	public var rightAuxiliaryColumnWidth: CGFloat = 0
	
	public var phantomCellIndex: Int?
	public var phantomCellSize = CGSizeZero
	
	public override var layoutAttributes: [UICollectionViewLayoutAttributes] {
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
	
	public override var backgroundAttribute: UICollectionViewLayoutAttributes? {
		guard let backgroundColor = metrics.backgroundColor else {
			return nil
		}
		let backgroundAttribute = super.backgroundAttribute
		if let backgroundAttribute = backgroundAttribute as? CollectionViewLayoutAttributes {
			backgroundAttribute.backgroundColor = backgroundColor
		}
		return backgroundAttribute
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
	
	public override func reset() {
		super.reset()
		rows.removeAll(keepCapacity: true)
		columnSeparatorLayoutAttributes.removeAll(keepCapacity: true)
	}
	
	public override func applyValues(from metrics: SectionMetrics) {
		super.applyValues(from: metrics)
		self.metrics.applyValues(from: metrics)
		if let gridMetrics = metrics as? GridSectionMetrics {
			self.metrics.applyValues(from: gridMetrics)
		} else if let gridSection = metrics as? GridLayoutSection {
			self.metrics.applyValues(from: gridSection.metrics)
		}
	}
	
	public override func resolveMissingValuesFromTheme() {
		metrics.resolveMissingValuesFromTheme()
	}
	
	public override func layoutWithOrigin(start: CGPoint, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) -> CGPoint {
		let origin = layoutHelper.layoutWithOrigin(start, invalidationContext: invalidationContext)
		pinnableHeaders = layoutHelper.pinnableHeaders
		nonPinnableHeaders = layoutHelper.nonPinnableHeaders
		return origin
	}
	
	// FIXME: Code duplication with super
	public override func setFrame(frame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		guard frame != self.frame else {
			return
		}
		let offset = CGPoint(x: frame.origin.x - self.frame.origin.x, y: frame.origin.y - self.frame.origin.y)
		
		for row in rows {
			let rowFrame = CGRectOffset(row.frame, offset.x, offset.y)
			row.setFrame(rowFrame, invalidationContext: invalidationContext)
		}
		
		for attributes in columnSeparatorLayoutAttributes {
			attributes.frame = CGRectOffset(attributes.frame, offset.x, offset.y)
			invalidationContext?.invalidateDecorationElementsOfKind(attributes.representedElementKind ?? "", atIndexPaths: [attributes.indexPath])
		}
		
		for (_, attributes) in sectionSeparatorLayoutAttributes {
			attributes.frame = CGRectOffset(attributes.frame, offset.x, offset.y)
			invalidationContext?.invalidateDecorationElementsOfKind(attributes.representedElementKind ?? "", atIndexPaths: [attributes.indexPath])
		}
		
		super.setFrame(frame, invalidationContext: invalidationContext)
	}
	
	public override func setSize(size: CGSize, forItemAt index: Int, invalidationContext: UICollectionViewLayoutInvalidationContext?) -> CGPoint {
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
	
	// FIXME: Code duplication
	override func offsetContentAfterPosition(origin: CGPoint, offset: CGPoint, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		for attributes in columnSeparatorLayoutAttributes {
			let separatorFrame = attributes.frame
			guard separatorFrame.minY >= origin.y else {
				continue
			}
			attributes.frame = CGRectOffset(separatorFrame, offset.x, offset.y)
			invalidationContext?.invalidateDecorationElementsOfKind(attributes.representedElementKind ?? "", atIndexPaths: [attributes.indexPath])
		}
		
		for (_, attributes) in sectionSeparatorLayoutAttributes {
			let separatorFrame = attributes.frame
			guard separatorFrame.minY >= origin.y else {
				continue
			}
			attributes.frame = CGRectOffset(separatorFrame, offset.x, offset.y)
			invalidationContext?.invalidateDecorationElementsOfKind(attributes.representedElementKind ?? "", atIndexPaths: [attributes.indexPath])
		}
		
		for row in rows {
			var rowFrame = row.frame
			guard rowFrame.minY >= origin.y else {
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
	public override func finalizeLayoutAttributesForSectionsWithContent(sectionsWithContent: NSIndexSet) {
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
	
	public override func layoutAttributesForDecorationViewOfKind(kind: String, at indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
		let itemIndex = indexPath.itemIndex
		if kind == collectionElementKindColumnSeparator {
			guard itemIndex < columnSeparatorLayoutAttributes.count else {
				return nil
			}
			return columnSeparatorLayoutAttributes[itemIndex]
		}
		
		if kind == collectionElementKindSectionSeparator {
			return sectionSeparatorLayoutAttributes[itemIndex]
		}
		
		if kind == collectionElementKindRowSeparator {
			guard itemIndex < rows.count else {
				return nil
			}
			let rowInfo = rows[itemIndex]
			return rowInfo.rowSeparatorLayoutAttributes
		}
		
		return nil
	}
	
}
