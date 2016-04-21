//
//  TableLayoutSection.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 4/20/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

private let sectionSeparatorTop = 0
private let sectionSeparatorBottom = 1

public struct TableLayoutSection: LayoutSection, LayoutSectionBaseComposite {
	
	static let hairline: CGFloat = 1.0 / UIScreen.mainScreen().scale
	
	public var layoutSectionBase = LayoutSectionBase()
	
	public var metrics = TableSectionMetrics()
	
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
	
	public var items: [LayoutItem] {
		return rows.reduce([]) { (items, row) in
			items + row.items
		}
	}
	
	public func item(at index: Int) -> LayoutItem {
		var searchIndex = 0
		
		for row in rows {
			let itemCount = row.items.count
			
			if searchIndex + itemCount <= index {
				searchIndex += itemCount
				continue
			}
			
			let itemIndex = index - searchIndex
			return row.items[itemIndex]
		}
		
		preconditionFailure("We should find an item at \(index).")
	}
	
	public func setItem(item: LayoutItem, at index: Int) {
		var searchIndex = 0
		
		for rowIndex in rows.indices {
			var row = rows[rowIndex]
			let itemCount = row.items.count
			
			if searchIndex + itemCount <= index {
				searchIndex += itemCount
				continue
			}
			
			let itemIndex = index - searchIndex
			row.items[itemIndex] = item
		}
	}
	
	public func add(item: LayoutItem) {
		
	}
	
	public var rows: [LayoutRow] = []
	
	public func row(forItemAt itemIndex: Int) -> LayoutRow? {
		guard let index = rowIndex(forItemAt: itemIndex) else {
			return nil
		}
		
		return rows[index]
	}
	
	public func rowIndex(forItemAt itemIndex: Int) -> Int? {
		var searchIndex = 0
		
		for (index, row) in rows.enumerate() {
			let itemCount = row.items.count
			
			if searchIndex + itemCount < itemIndex {
				searchIndex += itemCount
				continue
			}
			
			return index
		}
		
		return nil
	}
	
	public var phantomCellIndex: Int?
	public var phantomCellSize = CGSizeZero
	
	public var layoutAttributes: [CollectionViewLayoutAttributes] {
		var layoutAttributes: [CollectionViewLayoutAttributes] = []
		
		if let backgroundAttribute = self.backgroundAttribute {
			layoutAttributes.append(backgroundAttribute)
		}
		
		for (_, attributes) in sectionSeparatorLayoutAttributes {
			layoutAttributes.append(attributes)
		}
		
		layoutAttributes += columnSeparatorLayoutAttributes
		
		layoutAttributes += decorations.map {$0.layoutAttributes}
		
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
	
	public var columnWidth: CGFloat {
		let layoutWidth = frame.width
		let margins = metrics.padding
		let numberOfColumns = metrics.numberOfColumns
		let columnWidth = (layoutWidth - margins.width) / CGFloat(numberOfColumns)
		return columnWidth
	}
	
	public var shouldShowColumnSeparator: Bool {
		return metrics.numberOfColumns > 1
			&& metrics.separatorColor != nil
			&& metrics.showsColumnSeparator
			&& items.count > 0
	}
	
	private var columnSeparatorLayoutAttributes: [CollectionViewLayoutAttributes] = []
	
	private var sectionSeparatorLayoutAttributes: [Int: CollectionViewLayoutAttributes] = [:]
	
	public var hasTopSectionSeparator: Bool {
		return sectionSeparatorLayoutAttributes[sectionSeparatorTop] != nil
	}
	
	public var hasBottomSectionSeparator: Bool {
		return sectionSeparatorLayoutAttributes[sectionSeparatorBottom] != nil
	}
	
	public var backgroundAttribute: CollectionViewLayoutAttributes? {
		// Only have background attribute on global section
		guard sectionIndex == globalSectionIndex else {
			return nil
		}
		
		guard let backgroundColor = metrics.backgroundColor else {
			return nil
		}
		
		let indexPath = NSIndexPath(index: 0)
		let backgroundAttribute = CollectionViewLayoutAttributes(forDecorationViewOfKind: collectionElementKindGlobalHeaderBackground, withIndexPath: indexPath)
		
		// This will be updated by -updateSpecialItemsWithContentOffset
		backgroundAttribute.frame = backgroundFrame
		backgroundAttribute.unpinnedOrigin = backgroundFrame.origin
		backgroundAttribute.zIndex = defaultZIndex
		backgroundAttribute.isPinned = false
		backgroundAttribute.hidden = false
		backgroundAttribute.backgroundColor = backgroundColor
		
		return backgroundAttribute
	}
	
	private var backgroundFrame = CGRectZero
	
	public mutating func add(row: LayoutRow) {
		var row = row
		
		// Create the row separator if there isn't already one
		if metrics.showsRowSeparator && row.rowSeparatorDecoration == nil {
			var separatorDecoration = HorizontalSeparatorDecoration(elementKind: collectionElementKindRowSeparator, position: .bottom)
			separatorDecoration.itemIndex = rows.count
			separatorDecoration.sectionIndex = sectionIndex
			separatorDecoration.color = metrics.separatorColor
			separatorDecoration.zIndex = separatorZIndex
			let separatorInsets = metrics.separatorInsets
			separatorDecoration.leftMargin = separatorInsets.left
			separatorDecoration.rightMargin = separatorInsets.right
			var rowFrame = row.frame
			separatorDecoration.setContainerFrame(rowFrame, invalidationContext: nil)
			
			row.rowSeparatorDecoration = separatorDecoration
			rowFrame.size.height += separatorDecoration.thickness
			row.frame = rowFrame
		}
		
		rows.append(row)
	}
	
	public mutating func removeAllRows() {
		rows.removeAll(keepCapacity: true)
	}
	
	public mutating func reset() {
		supplementaryItemsByKind = [:]
		removeAllRows()
		columnSeparatorLayoutAttributes.removeAll(keepCapacity: true)
	}
	
	public var decorations: [LayoutDecoration] {
		return decorationsByKind.contents
	}
	
	public var decorationsByKind: [String: [LayoutDecoration]] {
		get {
			return metrics.decorationsByKind
		}
		set {
			metrics.decorationsByKind = newValue
		}
	}
	
	public mutating func mutateItems(using mutator: (item: inout LayoutItem, index: Int) -> Void) {
		mutateRows { (row, _) in
			for itemIndex in row.items.indices {
				mutator(item: &row.items[itemIndex], index: itemIndex)
			}
		}
	}
	
	public mutating func mutateRows(using mutator: (row: inout LayoutRow, index: Int) -> Void) {
		for index in rows.indices {
			mutator(row: &rows[index], index: index)
		}
	}
	
	public mutating func mutateDecorations(using mutator: (inout LayoutDecoration) -> Void) {
		for (kind, decorations) in decorationsByKind {
			var decorations = decorations
			for index in decorations.indices {
				mutator(&decorations[index])
			}
			decorationsByKind[kind] = decorations
		}
	}
	
	public mutating func setFrame(frame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		guard frame != self.frame else {
			return
		}
		
		let offset = CGPoint(x: frame.origin.x - self.frame.origin.x, y: frame.origin.y - self.frame.origin.y)
		
		for index in rows.indices {
			self.offset(&rows[index], by: offset, invalidationContext: invalidationContext)
		}
		
		for attributes in columnSeparatorLayoutAttributes {
			offsetDecorationElement(with: attributes, by: offset, invalidationContext: invalidationContext)
		}
		
		for attributes in sectionSeparatorLayoutAttributes.values {
			offsetDecorationElement(with: attributes, by: offset, invalidationContext: invalidationContext)
		}
		
		mutateDecorations { (inout decoration: LayoutDecoration) in
			decoration.setContainerFrame(frame, invalidationContext: invalidationContext)
		}
		
		// FIXME: Make sure this works
		if let backgroundAttribute = self.backgroundAttribute {
			let backgroundRect = CGRectOffset(backgroundAttribute.frame, offset.x, offset.y)
			backgroundAttribute.frame = backgroundRect
			invalidationContext?.invalidateDecorationElementsOfKind(backgroundAttribute.representedElementKind!, atIndexPaths: [backgroundAttribute.indexPath])
		}
		
		mutateSupplementaryItems { (supplementaryItem, _, _) in
			let supplementaryFrame = CGRectOffset(supplementaryItem.frame, offset.x, offset.y)
			supplementaryItem.setFrame(supplementaryFrame, invalidationContext: invalidationContext)
		}
		
		self.frame = frame
	}
	
	public mutating func setSize(size: CGSize, forItemAt index: Int, invalidationContext: UICollectionViewLayoutInvalidationContext?) -> CGPoint {
		var itemInfo: LayoutItem = item(at: index)
		var itemFrame = itemInfo.frame
		
		guard size != itemFrame.size else {
			return CGPointZero
		}
		
		itemFrame.size = size
		itemInfo.setFrame(itemFrame, invalidationContext: invalidationContext)
		setItem(itemInfo, at: index)
		
		guard let rowIndex = rowIndex(forItemAt: index) else {
			return CGPointZero
		}
		
		var rowInfo = rows[rowIndex]
		
		// Items in a row are always the same height
		var rowFrame = rowInfo.frame
		let originalRowHeight = rowFrame.height
		var newRowHeight: CGFloat = 0
		
		// Calculate the max row height based on the current collection of items
		for rowItemInfo in rowInfo.items {
			newRowHeight = max(newRowHeight, rowItemInfo.frame.height)
		}
		
		// If the height of the row hasn't changed, then nothing else needs to move
		if newRowHeight == originalRowHeight {
			return CGPointZero
		}
		
		let offsetPosition = CGPoint(x: 0, y: rowFrame.maxY)
		let sizeDelta = CGPoint(x: 0, y: newRowHeight - originalRowHeight)
		
		rowFrame.size.height += sizeDelta.y
		rowInfo.frame = rowFrame
		rows[rowIndex] = rowInfo
		
		offsetContentAfterPosition(offsetPosition, offset: sizeDelta, invalidationContext: invalidationContext)
		updateColumnSeparators(with: invalidationContext)
		
		return sizeDelta
	}
	
	public mutating func setSize(size: CGSize, forHeaderAt index: Int, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) -> CGPoint {
		return setSize(size, forSupplementaryElementOfKind: UICollectionElementKindSectionHeader, at: index, invalidationContext: invalidationContext)
	}
	
	public mutating func setSize(size: CGSize, forFooterAt index: Int, invalidationContext: UICollectionViewLayoutInvalidationContext?) -> CGPoint {
		return setSize(size, forSupplementaryElementOfKind: UICollectionElementKindSectionFooter, at: index, invalidationContext: invalidationContext)
	}
	
	public mutating func setSize(size: CGSize, forSupplementaryElementOfKind kind: String, at index: Int, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) -> CGPoint {
		var supplementaryItems = self.supplementaryItems(of: kind)
		let delta = setSize(size, of: &supplementaryItems[index], invalidationContext: invalidationContext)
		supplementaryItemsByKind[kind] = supplementaryItems
		return delta
	}
	
	mutating func setSize(size: CGSize, inout of supplementaryItem: LayoutSupplementaryItem, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) -> CGPoint {
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
	
	mutating func offsetContentAfterPosition(origin: CGPoint, offset: CGPoint, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		func shouldOffsetElement(with frame: CGRect) -> Bool {
			return frame.minY >= origin.y
		}
		
		mutateSupplementaryItems { (supplementaryItem, _, _) in
			var supplementaryFrame = supplementaryItem.frame
			if supplementaryFrame.minX < origin.x || supplementaryFrame.minY < origin.y {
				return
			}
			supplementaryFrame = CGRectOffset(supplementaryFrame, offset.x, offset.y)
			supplementaryItem.setFrame(supplementaryFrame, invalidationContext: invalidationContext)
		}
		
		mutateItems { (item, _) in
			var itemFrame = item.frame
			if itemFrame.minX < origin.x || itemFrame.minY < origin.y {
				return
			}
			itemFrame = CGRectOffset(itemFrame, offset.x, offset.y)
			item.setFrame(itemFrame, invalidationContext: invalidationContext)
		}
		
		for attributes in columnSeparatorLayoutAttributes where shouldOffsetElement(with: attributes.frame) {
			offsetDecorationElement(with: attributes, by: offset, invalidationContext: invalidationContext)
		}
		
		for attributes in sectionSeparatorLayoutAttributes.values where shouldOffsetElement(with: attributes.frame) {
			offsetDecorationElement(with: attributes, by: offset, invalidationContext: invalidationContext)
		}
		
		for index in rows.indices where shouldOffsetElement(with: rows[index].frame) {
			self.offset(&rows[index], by: offset, invalidationContext: invalidationContext)
		}
	}
	
	private func offsetDecorationElement(with attributes: CollectionViewLayoutAttributes, by offset: CGPoint, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		attributes.frame = CGRectOffset(attributes.frame, offset.x, offset.y)
		invalidationContext?.invalidateDecorationElement(with: attributes)
	}
	
	private func offset(inout row: LayoutRow, by offset: CGPoint, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		let offsetFrame = CGRectOffset(row.frame, offset.x, offset.y)
		row.setFrame(offsetFrame, invalidationContext: invalidationContext)
	}
	
	mutating func updateColumnSeparators(with invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) {
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

	/// Creates any additional layout attributes, given the sections that have content.
	public mutating func finalizeLayoutAttributesForSectionsWithContent(sectionsWithContent: [LayoutSection]) {
		let shouldShowSectionSeparators = metrics.showsSectionSeparator && items.count > 0
		
		// Hide the row separator for the last row in the section
		if metrics.showsRowSeparator && !rows.isEmpty {
			rows[rows.count - 1].rowSeparatorDecoration?.isHidden = true
		}
		
		if shouldShowSectionSeparators {
			updateSectionSeparatorsForSectionsWithContent(sectionsWithContent)
		}
		
		updateColumnSeparators()
	}
	
	private mutating func updateSectionSeparatorsForSectionsWithContent(sectionsWithContent: [LayoutSection]) {
		// Show the section separators
		sectionSeparatorLayoutAttributes = [:]
		
		if shouldCreateTopSectionSeparatorForSectionsWithContent(sectionsWithContent) {
			updateSectionSeparatorAttributes(sectionSeparatorTop)
		}
		
		if shouldCreateBottomSectionSeparatorForSectionsWithContent(sectionsWithContent) {
			updateSectionSeparatorAttributes(sectionSeparatorBottom)
		}
	}
	
	private func shouldCreateTopSectionSeparatorForSectionsWithContent(sectionsWithContent: [LayoutSection]) -> Bool {
		guard let previousSectionWithContent = sectionsWithContent.filter({$0.sectionIndex < self.sectionIndex}).last else {
			// This is the first section with content
			return false
		}
		
		// Only if the previous section isn't showing a bottom separator
		if let previousGridSectionWithContent = previousSectionWithContent as? GridLayoutSection {
			return !previousGridSectionWithContent.hasBottomSectionSeparator
		}
		
		return true
	}
	
	private func shouldCreateBottomSectionSeparatorForSectionsWithContent(sectionsWithContent: [LayoutSection]) -> Bool {
		guard let nextSectionWithContent = sectionsWithContent.filter({$0.sectionIndex > self.sectionIndex}).first else {
			// This is the last section with content
			return metrics.showsSectionSeparatorWhenLastSection
		}
		
		// Only if the next section isn't showing a top separator
		if let nextGridSectionWithContent = nextSectionWithContent as? GridLayoutSection {
			return !nextGridSectionWithContent.hasTopSectionSeparator
		}
		
		return true
	}
	
	private mutating func updateSectionSeparatorAttributes(sectionSeparator: Int) {
		let separatorAttributes = createSectionSeparatorAttributes(sectionSeparator)
		sectionSeparatorLayoutAttributes[sectionSeparator] = separatorAttributes
	}
	
	private func createSectionSeparatorAttributes(sectionSeparator: Int) -> CollectionViewLayoutAttributes {
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
	
	public func layoutAttributesForCell(at indexPath: NSIndexPath) -> CollectionViewLayoutAttributes? {
		let itemIndex = indexPath.itemIndex
		guard placeholderInfo != nil || itemIndex < items.count else {
			return nil
		}
		let itemInfo = item(at: itemIndex)
		return itemInfo.layoutAttributes
	}
	
	public func layoutAttributesForSupplementaryElementOfKind(kind: String, at indexPath: NSIndexPath) -> CollectionViewLayoutAttributes? {
		if kind == collectionElementKindPlaceholder {
			return placeholderInfo?.layoutAttributes
		}
		
		let itemIndex = indexPath.itemIndex
		let items = supplementaryItems(of: kind)
		
		guard itemIndex < items.count else {
			return nil
		}
		
		let supplementaryItem = items[itemIndex]
		
		// There's no layout attributes if this section isn't the global section, there are no items and the supplementary item shouldn't be shown when the placeholder is visible (e.g. no items)
		guard isGlobalSection || items.count > 0 || supplementaryItem.isVisibleWhileShowingPlaceholder else {
			return nil
		}
		
		return supplementaryItem.layoutAttributes
	}
	
	public func layoutAttributesForDecorationViewOfKind(kind: String, at indexPath: NSIndexPath) -> CollectionViewLayoutAttributes? {
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
			guard let decorations = decorationsByKind[kind] else {
				return nil
			}
			return decorations[indexPath.item].layoutAttributes
		}
	}
	
	public func additionalLayoutAttributesToInsertForInsertionOfItem(at indexPath: NSIndexPath) -> [CollectionViewLayoutAttributes] {
		return []
	}
	
	public func additionalLayoutAttributesToDeleteForDeletionOfItem(at indexPath: NSIndexPath) -> [CollectionViewLayoutAttributes] {
		var attributes: [CollectionViewLayoutAttributes] = []
		
		if let rowSeparator = rowSeparatorAttributesToDeleteForDeletionOfItem(at: indexPath) {
			attributes.append(rowSeparator)
		}
		
		return attributes
	}
	
	private func rowSeparatorAttributesToDeleteForDeletionOfItem(at indexPath: NSIndexPath) -> CollectionViewLayoutAttributes? {
		guard metrics.showsRowSeparator else {
			return nil
		}
		
		let itemIndex = indexPath.item
		
		guard let rowInfo = row(forItemAt: itemIndex),
			rowSeparatorAttributes = rowInfo.rowSeparatorLayoutAttributes else {
				return nil
		}
		
		if rowInfo.items.count == 1 {
			return rowSeparatorAttributes
		} else {
			return nil
		}
	}
	
	public func prepareForLayout() {
		
	}
	
	public func targetLayoutHeightForProposedLayoutHeight(proposedHeight: CGFloat, layoutInfo: LayoutInfo) -> CGFloat {
		guard isGlobalSection else {
			return proposedHeight
		}
		
		let height = layoutInfo.height
		
		let globalNonPinningHeight = heightOfNonPinningHeaders
		
		if layoutInfo.contentOffset.y >= globalNonPinningHeight
			&& proposedHeight - globalNonPinningHeight < height {
			return height + globalNonPinningHeight
		}
		
		return proposedHeight
	}
	
	public func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint, firstInsertedSectionMinY: CGFloat) -> CGPoint {
		guard isGlobalSection else {
			return proposedContentOffset
		}
		
		var targetContentOffset = proposedContentOffset
		
		let globalNonPinnableHeight = heightOfNonPinningHeaders
		let globalPinnableHeight = heightOfPinningHeaders
		
		let isFirstInsertedSectionHidden = targetContentOffset.y + globalPinnableHeight > firstInsertedSectionMinY
		
		if isFirstInsertedSectionHidden {
			// Need to scroll the section into view
			targetContentOffset.y = max(globalNonPinnableHeight, firstInsertedSectionMinY - globalPinnableHeight)
		}
		
		return targetContentOffset
	}
	
	public mutating func updateSpecialItemsWithContentOffset(contentOffset: CGPoint, layoutInfo: LayoutInfo, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) {
		var pinnableY = contentOffset.y + layoutInfo.contentInset.top
		var nonPinnableY = pinnableY
		
		resetHeaders(pinnable: true, invalidationContext: invalidationContext)
		
		// Pin the headers as appropriate
		guard self.isGlobalSection else {
			return
		}
		
		pinnableY = applyTopPinningToPinnableHeaders(minY: pinnableY, invalidationContext: invalidationContext)
		
		finalizePinningForHeaders(pinnable: true, zIndex: pinnedHeaderZIndex)
		
		let nonPinnableHeaders = self.nonPinnableHeaders
		
		resetHeaders(pinnable: false, invalidationContext: invalidationContext)
		
		nonPinnableY = applyBottomPinningToNonPinnableHeaders(maxY: nonPinnableY, invalidationContext: invalidationContext)
		
		finalizePinningForHeaders(pinnable: false, zIndex: pinnedHeaderZIndex)
		
		if let backgroundAttributes = self.backgroundAttribute {
			var frame = backgroundAttributes.frame
			frame.origin.y = min(nonPinnableY, layoutInfo.bounds.origin.y)
			
			// FIXME: Make sure bottomY is computed using correct headers
			let bottomY = max(pinnableHeaders.last?.frame.maxY ?? 0, nonPinnableHeaders.last?.frame.maxY ?? 0)
			frame.size.height = bottomY - frame.origin.y
			
			backgroundAttributes.frame = frame
		}
		
		mutateFirstSectionOverlappingYOffset(pinnableY, from: layoutInfo) { overlappingSection in
			overlappingSection.applyTopPinningToPinnableHeaders(minY: pinnableY, invalidationContext: invalidationContext)
			
			// FIXME: Magic number
			overlappingSection.finalizePinningForHeaders(pinnable: true, zIndex: pinnedHeaderZIndex - 100)
		}
	}
	
	private mutating func resetHeaders(pinnable pinnable: Bool, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		func resetter(inout header: GridLayoutSupplementaryItem, index: Int) {
			var frame = header.frame
			
			if frame.minY != header.unpinnedY {
				invalidationContext?.invalidate(header)
			}
			
			header.isPinned = false
			
			frame.origin.y = header.unpinnedY
			header.frame = frame
		}
		
		pinnable ?
			mutatePinnableHeaders(using: resetter)
			: mutateNonPinnableHeaders(using: resetter)
	}
	
	private mutating func applyBottomPinningToNonPinnableHeaders(maxY maxY: CGFloat, invalidationContext: UICollectionViewLayoutInvalidationContext?) -> CGFloat {
		var maxY = maxY
		
		mutateNonPinnableHeaders(inReverse: true) { (nonPinnableHeader, index) in
			var frame = nonPinnableHeader.frame
			
			guard frame.maxY < maxY else {
				return
			}
			
			maxY -= frame.height
			frame.origin.y = maxY
			nonPinnableHeader.frame = frame
			
			invalidationContext?.invalidate(nonPinnableHeader)
		}
		
		return maxY
	}
	
	/// Pins the pinnable headers starting at `minY` -- as long as they don't cross `minY` -- and returns the new `minY`.
	private mutating func applyTopPinningToPinnableHeaders(minY minY: CGFloat, invalidationContext: UICollectionViewLayoutInvalidationContext?) -> CGFloat {
		var minY = minY
		
		mutatePinnableHeaders { (pinnableHeader, index) in
			var frame = pinnableHeader.frame
			
			guard frame.minY < minY else {
				return
			}
			
			// We have a new pinning offset
			frame.origin.y = minY
			minY = frame.maxY
			pinnableHeader.frame = frame
			
			invalidationContext?.invalidate(pinnableHeader)
		}
		
		return minY
	}
	
	private mutating func finalizePinningForHeaders(pinnable pinnable: Bool, zIndex: Int) {
		func finalizer(inout header: GridLayoutSupplementaryItem, index: Int) {
			header.isPinned = header.frame.minY != header.unpinnedY
			
			let depth = index + 1
			header.zIndex = zIndex - depth
		}
		
		pinnable ?
			mutatePinnableHeaders(using: finalizer)
			: mutateNonPinnableHeaders(using: finalizer)
	}
	
	private mutating func mutateFirstSectionOverlappingYOffset(yOffset: CGFloat, from layoutInfo: LayoutInfo, using mutator: (inout TableLayoutSection) -> Void) {
		layoutInfo.enumerateSections { (sectionIndex, sectionInfo, stop) in
			guard sectionIndex != globalSectionIndex else {
				return
			}
			
			let frame = sectionInfo.frame
			if frame.minY <= yOffset && yOffset <= frame.maxY,
				var tableSectionInfo = sectionInfo as? TableLayoutSection {
				mutator(&tableSectionInfo)
				sectionInfo = tableSectionInfo
				stop = true
			}
		}
	}
	
	public mutating func mutatePinnableHeaders(using mutator: (inout pinnableHeader: GridLayoutSupplementaryItem, index: Int) -> Void) {
		var headers = self.headers
		
		for index in headers.indices {
			guard var header = headers[index] as? GridLayoutSupplementaryItem
				where header.shouldPin else {
					continue
			}
			
			mutator(pinnableHeader: &header, index: index)
			headers[index] = header
		}
		
		self.headers = headers
	}
	
	public mutating func mutateNonPinnableHeaders(inReverse inReverse: Bool = false, using mutator: (inout nonPinnableHeader: GridLayoutSupplementaryItem, index: Int) -> Void) {
		var headers = self.headers
		
		let headerIndices = inReverse ?
			AnyForwardCollection<Int>(headers.indices.reverse())
			: AnyForwardCollection<Int>(headers.indices)
		
		for index in headerIndices {
			guard var header = headers[index] as? GridLayoutSupplementaryItem
				where !header.shouldPin else {
					continue
			}
			
			mutator(nonPinnableHeader: &header, index: index)
			headers[index] = header
		}
		
		self.headers = headers
	}
	
	public mutating func applyValues(from metrics: LayoutMetrics) {
		self.metrics.applyValues(from: metrics)
	}
	
}

extension TableLayoutSection {
	
	public var headers: [LayoutSupplementaryItem] {
		get {
			return supplementaryItems(of: UICollectionElementKindSectionHeader)
		}
		set {
			setSupplementaryItems(newValue, of: UICollectionElementKindSectionHeader)
		}
	}
	
	public var pinnableHeaders: [LayoutSupplementaryItem] {
		return headers.filter {($0 as? GridLayoutSupplementaryItem)?.shouldPin ?? false}
	}
	
	public var nonPinnableHeaders: [LayoutSupplementaryItem] {
		return headers.filter {!(($0 as? GridLayoutSupplementaryItem)?.shouldPin ?? false)}
	}
	
	public var footers: [LayoutSupplementaryItem] {
		get {
			return supplementaryItems(of: UICollectionElementKindSectionFooter)
		}
		set {
			setSupplementaryItems(newValue, of: UICollectionElementKindSectionFooter)
		}
	}
	
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
	
	public var decorationAttributesByKind: [String: [CollectionViewLayoutAttributes]] {
		var attributes: [String: [CollectionViewLayoutAttributes]] = [:]
		
		attributes[collectionElementKindColumnSeparator] = columnSeparatorLayoutAttributes
		attributes[collectionElementKindSectionSeparator] = Array(sectionSeparatorLayoutAttributes.values)
		attributes[collectionElementKindRowSeparator] = rows.flatMap { $0.rowSeparatorLayoutAttributes }
		attributes[collectionElementKindGlobalHeaderBackground] = [backgroundAttribute].flatMap { $0 }
		
		attributes.appendContents(of: attributesForDecorationsByKind)
		
		return attributes
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
	
}
