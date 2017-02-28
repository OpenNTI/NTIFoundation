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
	
	var metrics: GridSectionMetricsProviding { get set }
	
	var headers: [LayoutSupplementaryItem] { get set }
	var footers: [LayoutSupplementaryItem] { get set }
	
	var pinnableHeaders: [LayoutSupplementaryItem] { get set }
	var nonPinnableHeaders: [LayoutSupplementaryItem] { get set }
	
	var heightOfNonPinningHeaders: CGFloat { get }
	var heightOfPinningHeaders: CGFloat { get }
	
	var rows: [LayoutRow] { get set }
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
	
	var backgroundAttributesForReading: CollectionViewLayoutAttributes? { get }
	var backgroundAttributesForWriting: CollectionViewLayoutAttributes? { mutating get }

	mutating func add(_ row: inout LayoutRow)
	mutating func removeAllRows()
	
	func item(at index: Int) -> LayoutItem
	mutating func setItem(_ item: LayoutItem, at index: Int)
	
	mutating func setSize(_ size: CGSize, forHeaderAt index: Int, invalidationContext: UICollectionViewLayoutInvalidationContext?) -> CGPoint
	
	mutating func setSize(_ size: CGSize, forFooterAt index: Int, invalidationContext: UICollectionViewLayoutInvalidationContext?) -> CGPoint
}

extension GridLayoutSection {
	
	public var headers: [LayoutSupplementaryItem] {
		get {
			return supplementaryItems(of: UICollectionElementKindSectionHeader)
		}
		set {
			setSupplementaryItems(newValue, of: UICollectionElementKindSectionHeader)
		}
	}
	
	public var footers: [LayoutSupplementaryItem] {
		get {
			return supplementaryItems(of: UICollectionElementKindSectionFooter)
		}
		set {
			setSupplementaryItems(newValue, of: UICollectionElementKindSectionFooter)
		}
	}
	
	public var leftAuxiliaryItems: [LayoutSupplementaryItem] {
		get {
			return supplementaryItems(of: collectionElementKindLeftAuxiliaryItem)
		}
		set {
			setSupplementaryItems(newValue, of: collectionElementKindLeftAuxiliaryItem)
		}
	}
	
	public var rightAuxiliaryItems: [LayoutSupplementaryItem] {
		get {
			return supplementaryItems(of: collectionElementKindRightAuxiliaryItem)
		}
		set {
			setSupplementaryItems(newValue, of: collectionElementKindRightAuxiliaryItem)
		}
	}
	
}

public struct BasicGridLayoutSection: GridLayoutSection, RowAlignedLayoutSectionBaseComposite {
	
	public var rowAlignedLayoutSectionBase = RowAlignedLayoutSectionBase()
	
	public var items: [LayoutItem] = []
	
	// FIXME: Make sure this doesn't trigger when we're mutating the value
	public var placeholderInfo: LayoutPlaceholder? {
		didSet {
			guard let placeholderInfo = self.placeholderInfo else {
				return
			}
			
			if let oldValue = oldValue, placeholderInfo.isEqual(to: oldValue) {
				return
			}
			
			self.placeholderInfo?.wasAddedToSection(self)
		}
	}
	
	public var shouldResizePlaceholder: Bool {
		return metrics.shouldResizePlaceholder
	}
	
	public var pinnableHeaders: [LayoutSupplementaryItem] = []
	
	public var nonPinnableHeaders: [LayoutSupplementaryItem] = []
	
	public var heightOfNonPinningHeaders: CGFloat {
		return height(of: nonPinnableHeaders)
	}
	
	public var heightOfPinningHeaders: CGFloat {
		return height(of: pinnableHeaders)
	}
	
	fileprivate func height(of supplementaryItems: [LayoutSupplementaryItem]) -> CGFloat {
		guard !supplementaryItems.isEmpty else {
			return 0
		}
		var minY = CGFloat.greatestFiniteMagnitude
		var maxY = CGFloat.leastNormalMagnitude
		
		for supplementaryItem in supplementaryItems {
			let frame = supplementaryItem.frame
			minY = min(minY, frame.minY)
			maxY = max(maxY, frame.maxY)
		}
		
		return maxY - minY
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
	
	public var metrics: GridSectionMetricsProviding = GridSectionMetrics()
	
	public var columnWidth: CGFloat {
		return metrics.fixedColumnWidth ?? maximizedColumnWidth
	}
	fileprivate var maximizedColumnWidth: CGFloat {
		let layoutWidth = frame.width
		let margins = metrics.padding
		let numberOfColumns = metrics.numberOfColumns
		let columnWidth = (layoutWidth - margins.left - margins.right) / CGFloat(numberOfColumns)
		return columnWidth
	}
	public var leftAuxiliaryColumnWidth: CGFloat {
		return metrics.leftAuxiliaryColumnWidth
	}
	public var rightAuxiliaryColumnWidth: CGFloat {
		return metrics.rightAuxiliaryColumnWidth
	}
	
	public var layoutAttributes: [CollectionViewLayoutAttributes] {
		var layoutAttributes: [CollectionViewLayoutAttributes] = []
		
		if let backgroundAttributes = backgroundAttributesForReading {
			layoutAttributes.append(backgroundAttributes)
		}
		
		if let contentBackgroundAttributes = self.contentBackgroundAttributes {
			layoutAttributes.append(contentBackgroundAttributes)
		}
		
		for (_, attributes) in sectionSeparatorLayoutAttributes {
			layoutAttributes.append(attributes)
		}
		
		layoutAttributes += columnSeparatorLayoutAttributes
		
		for attributes in attributesForDecorationsByKind.values {
			layoutAttributes += attributes
		}
		
		for supplementaryItem in supplementaryItems {
			// Don't enumerate hidden or 0 height supplementary items
			guard !supplementaryItem.isHidden && (supplementaryItem.height ?? 0) > 0 else {
				continue
			}
			
			// For non-global sections, don't enumerate if there are no items and not marked as visible when showing placeholder
			guard shouldShow(supplementaryItem) else {
				continue
			}
			
			layoutAttributes.append(supplementaryItem.layoutAttributes)
		}
		
		if let placeholderInfo = self.placeholderInfo, placeholderInfo.startingSectionIndex == sectionIndex {
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
	
	public func shouldShow(_ supplementaryItem: SupplementaryItem) -> Bool {
		return isGlobalSection || numberOfItems > 0 || supplementaryItem.isVisibleWhileShowingPlaceholder
	}
	
	public var shouldShowColumnSeparator: Bool {
		return metrics.numberOfColumns > 1
			&& metrics.separatorColor != nil
			&& metrics.showsColumnSeparator
			&& items.count > 0
	}
	
	fileprivate var columnSeparatorLayoutAttributes: [CollectionViewLayoutAttributes] = []
	
	fileprivate var sectionSeparatorLayoutAttributes: [Int: CollectionViewLayoutAttributes] = [:]
	
	public var hasTopSectionSeparator: Bool {
		return sectionSeparatorLayoutAttributes[sectionSeparatorTop] != nil
	}
	
	public var hasBottomSectionSeparator: Bool {
		return sectionSeparatorLayoutAttributes[sectionSeparatorBottom] != nil
	}
	
	fileprivate var _backgroundAttributes = CollectionViewLayoutAttributes(forDecorationViewOfKind: collectionElementKindGlobalHeaderBackground, with: IndexPath(index: 0))
	
	public var backgroundAttributesForReading: CollectionViewLayoutAttributes? {
		guard shouldShowBackground else {
			return nil
		}
		
		return _backgroundAttributes
	}
	
	// This is updated by `updateSpecialItemsWithContentOffset`
	public var backgroundAttributesForWriting: CollectionViewLayoutAttributes? {
		mutating get {
			guard shouldShowBackground else {
				return nil
			}
			
			if needsConfigureBackgroundAttributes {
				_backgroundAttributes.frame = frame
				_backgroundAttributes.unpinnedOrigin = frame.origin
				_backgroundAttributes.zIndex = defaultZIndex
				_backgroundAttributes.isPinned = false
				_backgroundAttributes.isHidden = false
				_backgroundAttributes.backgroundColor = metrics.backgroundColor
				needsConfigureBackgroundAttributes = false
			}
			
			_backgroundAttributes = _backgroundAttributes.copy() as! CollectionViewLayoutAttributes
			
			return _backgroundAttributes
		}
	}
	
	fileprivate var needsConfigureBackgroundAttributes = true
	
	
	fileprivate var shouldShowBackground: Bool {
		// Only have background attribute on global section
		return sectionIndex == globalSectionIndex && metrics.backgroundColor != nil
	}
	
	public var contentBackgroundAttributes: CollectionViewLayoutAttributes? {
//		if let attributes = _contentBackgroundAttributes {
//			return attributes
//		}
		
		guard metrics.contentBackgroundAttributes.color != nil else {
			return nil
		}
		
		let indexPath = isGlobalSection ? IndexPath(index: 0) : IndexPath(item: 0, section: sectionIndex)
		let attributes = CollectionViewLayoutAttributes(forDecorationViewOfKind: collectionElementKindContentBackground, with: indexPath)
		
		attributes.frame = contentFrame
		attributes.zIndex = defaultZIndex
		attributes.isHidden = false
		attributes.backgroundColor = metrics.contentBackgroundAttributes.color
		attributes.cornerRadius = metrics.contentBackgroundAttributes.cornerRadius
		
//		_contentBackgroundAttributes = attributes
		return attributes
	}
	
	fileprivate var _contentBackgroundAttributes: CollectionViewLayoutAttributes?
	
	public var contentFrame: CGRect {
		let frame = UIEdgeInsetsInsetRect(self.frame, metrics.contentInset)
		return UIEdgeInsetsInsetRect(frame, contentFrameInset)
	}
	public var contentFrameInset: UIEdgeInsets {
		var t = height(of: headers)
		if t > 0 {
			t += metrics.padding.top
		}
		let l = leftAuxiliaryColumnWidth
			+ (leftAuxiliaryColumnWidth > 0 ? metrics.padding.left : 0)
		let r = rightAuxiliaryColumnWidth
			+ (rightAuxiliaryColumnWidth > 0 ? metrics.padding.right : 0)
		var b = height(of: footers)
		if b > 0 {
			b += metrics.padding.bottom
		}
		return UIEdgeInsets(top: t, left: l, bottom: b, right: r)
	}
	
	public mutating func add(_ item: LayoutItem) {
		var item = item
		item.itemIndex = items.count
		item.sectionIndex = sectionIndex
		item.applyValues(from: metrics)
		items.append(item)
	}
	
	public mutating func enumerateDecorations(using visitor: (inout LayoutDecoration) -> Void) {
		for (kind, decorations) in decorationsByKind {
			var decorations = decorations
			for index in decorations.indices {
				visitor(&decorations[index])
			}
			decorationsByKind[kind] = decorations
		}
	}
	
	public mutating func add(_ row: inout LayoutRow) {
		// Create the row separator if there isn't already one
		if metrics.showsRowSeparator && row.rowSeparatorDecoration == nil {
			var separatorDecoration = HorizontalSeparatorDecoration(elementKind: collectionElementKindRowSeparator, position: .bottom)
			separatorDecoration.itemIndex = rows.count
			separatorDecoration.sectionIndex = sectionIndex
			separatorDecoration.color = metrics.separatorColor
			separatorDecoration.zIndex = separatorZIndex
			separatorDecoration.thickness = metrics.separatorWidth
			let separatorInsets = metrics.separatorInsets
			separatorDecoration.leftMargin = separatorInsets.left
			separatorDecoration.rightMargin = separatorInsets.right
			var rowFrame = row.frame
			separatorDecoration.setContainerFrame(rowFrame, invalidationContext: nil)
			
			row.rowSeparatorDecoration = separatorDecoration
			rowFrame.size.height += separatorDecoration.thickness
			row.frame = rowFrame
		}
		
		rowAlignedLayoutSectionBase.add(row)
	}
	
	public mutating func reset() {
		needsConfigureBackgroundAttributes = true
		items.removeAll(keepingCapacity: true)
		supplementaryItemsByKind = [:]
		rows.removeAll(keepingCapacity: true)
		columnSeparatorLayoutAttributes.removeAll(keepingCapacity: true)
	}
	
	public mutating func applyValues(from metrics: LayoutMetrics) {
		if let gridSection = metrics as? GridLayoutSection {
			self.metrics.applyValues(from: gridSection.metrics)
		}
		else {
			self.metrics.applyValues(from: metrics)
		}
	}
	
	public mutating func resolveMissingValuesFromTheme() {
		metrics.resolveMissingValuesFromTheme()
	}
	
	public mutating func layoutWithOrigin(_ start: CGPoint, layoutSizing: LayoutSizing, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) -> CGPoint {
		let layoutEngine = GridSectionLayoutEngine(layoutSection: self)
		let endPoint = layoutEngine.layoutWithOrigin(start, layoutSizing: layoutSizing, invalidationContext: invalidationContext)
		pinnableHeaders = layoutEngine.pinnableHeaders
		nonPinnableHeaders = layoutEngine.nonPinnableHeaders
		return endPoint
	}
	
	public mutating func setFrame(_ frame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
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
		
		enumerateDecorations { (decoration: inout LayoutDecoration) in
			decoration.setContainerFrame(frame, invalidationContext: invalidationContext)
		}
		
		if let backgroundAttributes = self.backgroundAttributesForReading {
			backgroundAttributes.frame = backgroundAttributes.frame.offsetBy(dx: offset.x, dy: offset.y)
			invalidationContext?.invalidateDecorationElements(ofKind: backgroundAttributes.representedElementKind!, at: [backgroundAttributes.indexPath])
		}
		
		if let contentBackgroundAttributes = self.contentBackgroundAttributes {
			offsetDecorationElement(with: contentBackgroundAttributes, by: offset, invalidationContext: invalidationContext)
		}
		
		mutateSupplementaryItems { (supplementaryItem, _, _) in
			let supplementaryFrame = supplementaryItem.frame.offsetBy(dx: offset.x, dy: offset.y)
			supplementaryItem.setFrame(supplementaryFrame, invalidationContext: invalidationContext)
		}
		
		self.frame = frame
	}
	
	public mutating func setSize(_ size: CGSize, forItemAt index: Int, invalidationContext: UICollectionViewLayoutInvalidationContext?) -> CGPoint {
		var itemInfo: LayoutItem = item(at: index)
		var itemFrame = itemInfo.frame
		
		guard size != itemFrame.size else {
			return CGPoint.zero
		}
		
		itemFrame.size = size
		itemInfo.setFrame(itemFrame, invalidationContext: invalidationContext)
		setItem(itemInfo, at: index)
		
		guard let rowIndex = rowIndex(forItemAt: index) else {
			return CGPoint.zero
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
			return CGPoint.zero
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
	
	public mutating func setSize(_ size: CGSize, forHeaderAt index: Int, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) -> CGPoint {
		return setSize(size, forSupplementaryElementOfKind: UICollectionElementKindSectionHeader, at: index, invalidationContext: invalidationContext)
	}
	
	public mutating func setSize(_ size: CGSize, forFooterAt index: Int, invalidationContext: UICollectionViewLayoutInvalidationContext?) -> CGPoint {
		return setSize(size, forSupplementaryElementOfKind: UICollectionElementKindSectionFooter, at: index, invalidationContext: invalidationContext)
	}
	
	public mutating func setSize(_ size: CGSize, forSupplementaryElementOfKind kind: String, at index: Int, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) -> CGPoint {
		var supplementaryItems = self.supplementaryItems(of: kind)
		let delta = setSize(size, of: &supplementaryItems[index], invalidationContext: invalidationContext)
		supplementaryItemsByKind[kind] = supplementaryItems
		return delta
	}
	
	mutating func setSize(_ size: CGSize, of supplementaryItem: inout LayoutSupplementaryItem, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) -> CGPoint {
		var frame = supplementaryItem.frame
		let after = CGPoint(x: 0, y: frame.maxY)
		
		let sizeDelta = CGPoint(x: 0, y: size.height - frame.height)
		frame.size = size
		supplementaryItem.setFrame(frame, invalidationContext: invalidationContext)
		
		guard sizeDelta != CGPoint.zero else {
			return CGPoint.zero
		}
		
		offsetContentAfterPosition(after, offset: sizeDelta, invalidationContext: invalidationContext)
		return sizeDelta
	}
	
	mutating func offsetContentAfterPosition(_ origin: CGPoint, offset: CGPoint, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		func shouldOffsetElement(with frame: CGRect) -> Bool {
			return frame.minY >= origin.y
		}
		
		mutateSupplementaryItems { (supplementaryItem, _, _) in
			var supplementaryFrame = supplementaryItem.frame
			if supplementaryFrame.minX < origin.x || supplementaryFrame.minY < origin.y {
				return
			}
			supplementaryFrame = supplementaryFrame.offsetBy(dx: offset.x, dy: offset.y)
			supplementaryItem.setFrame(supplementaryFrame, invalidationContext: invalidationContext)
		}
		
		mutateItems { (item, _) in
			var itemFrame = item.frame
			if itemFrame.minX < origin.x || itemFrame.minY < origin.y {
				return
			}
			itemFrame = itemFrame.offsetBy(dx: offset.x, dy: offset.y)
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
	
	fileprivate func offsetDecorationElement(with attributes: CollectionViewLayoutAttributes, by offset: CGPoint, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		attributes.frame = attributes.frame.offsetBy(dx: offset.x, dy: offset.y)
		invalidationContext?.invalidateDecorationElement(with: attributes)
	}
	
	fileprivate func offset(_ row: inout LayoutRow, by offset: CGPoint, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		let offsetFrame = row.frame.offsetBy(dx: offset.x, dy: offset.y)
		row.setFrame(offsetFrame, invalidationContext: invalidationContext)
	}
	
	mutating func updateColumnSeparators(with invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) {
		guard shouldShowColumnSeparator else {
			return
		}
		
		guard let firstRow = rows.first,
			let lastRow = rows.last else {
				return
		}
		
		let thickness = metrics.separatorWidth
		
		let columnWidth = self.columnWidth
	
		let top = firstRow.frame.minY
		let bottom = lastRow.frame.maxY
		let numberOfColumns = metrics.numberOfColumns
		
		columnSeparatorLayoutAttributes = []
		
		for columnIndex in 0..<numberOfColumns {
			let indexPath = IndexPath(item: columnIndex, section: sectionIndex)
			let separatorAttributes = CollectionViewLayoutAttributes(forDecorationViewOfKind: collectionElementKindColumnSeparator, with: indexPath)
			let separatorFrame = CGRect(x: columnWidth * CGFloat(columnIndex), y: top, width: thickness, height: bottom - top)
			separatorAttributes.frame = separatorFrame
			separatorAttributes.backgroundColor = metrics.separatorColor
			separatorAttributes.zIndex = separatorZIndex
			
			columnSeparatorLayoutAttributes.append(separatorAttributes)
			
			invalidationContext?.invalidateDecorationElements(ofKind: separatorAttributes.representedElementKind!, at: [separatorAttributes.indexPath])
		}
	}
	
	/// Creates any additional layout attributes, given the sections that have content.
	public mutating func finalizeLayoutAttributesForSectionsWithContent(_ sectionsWithContent: [LayoutSection]) {
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
	
	fileprivate mutating func updateSectionSeparatorsForSectionsWithContent(_ sectionsWithContent: [LayoutSection]) {
		// Show the section separators
		sectionSeparatorLayoutAttributes = [:]
		
		if shouldCreateTopSectionSeparatorForSectionsWithContent(sectionsWithContent) {
			updateSectionSeparatorAttributes(sectionSeparatorTop)
		}
		
		if shouldCreateBottomSectionSeparatorForSectionsWithContent(sectionsWithContent) {
			updateSectionSeparatorAttributes(sectionSeparatorBottom)
		}
	}
	
	fileprivate func shouldCreateTopSectionSeparatorForSectionsWithContent(_ sectionsWithContent: [LayoutSection]) -> Bool {
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
	
	fileprivate func shouldCreateBottomSectionSeparatorForSectionsWithContent(_ sectionsWithContent: [LayoutSection]) -> Bool {
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
	
	fileprivate mutating func updateSectionSeparatorAttributes(_ sectionSeparator: Int) {
		let separatorAttributes = createSectionSeparatorAttributes(sectionSeparator)
		sectionSeparatorLayoutAttributes[sectionSeparator] = separatorAttributes
	}
	
	fileprivate func createSectionSeparatorAttributes(_ sectionSeparator: Int) -> CollectionViewLayoutAttributes {
		let indexPath = IndexPath(item: sectionSeparatorTop, section: sectionIndex)
		let separatorAttributes = CollectionViewLayoutAttributes(forDecorationViewOfKind: collectionElementKindSectionSeparator, with: indexPath)
		separatorAttributes.frame = frameForSectionSeparator(sectionSeparator)
		separatorAttributes.backgroundColor = metrics.sectionSeparatorColor
		separatorAttributes.zIndex = sectionSeparatorZIndex
		return separatorAttributes
	}
	
	fileprivate func frameForSectionSeparator(_ sectionSeparator: Int) -> CGRect {
		let sectionSeparatorInsets = metrics.sectionSeparatorInsets
		let frame = self.frame
		let thickness = metrics.separatorWidth
		
		let x = sectionSeparatorInsets.left
		let y = (sectionSeparator == sectionSeparatorTop) ? frame.origin.y : frame.maxY
		let width = frame.width - sectionSeparatorInsets.left - sectionSeparatorInsets.right
		let height = thickness
		
		return CGRect(x: x, y: y, width: width, height: height)
	}
	
	public func layoutAttributesForCell(at indexPath: IndexPath) -> CollectionViewLayoutAttributes? {
		let itemIndex = indexPath.itemIndex
		guard placeholderInfo != nil || itemIndex < items.count else {
			return nil
		}
		let itemInfo = item(at: itemIndex)
		return itemInfo.layoutAttributes
	}
	
	public func layoutAttributesForSupplementaryElementOfKind(_ kind: String, at indexPath: IndexPath) -> CollectionViewLayoutAttributes? {
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
		guard shouldShow(supplementaryItem) else {
			return nil
		}
		
		return supplementaryItem.layoutAttributes
	}
	
	public func layoutAttributesForDecorationViewOfKind(_ kind: String, at indexPath: IndexPath) -> CollectionViewLayoutAttributes? {
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
			return backgroundAttributesForReading
		case collectionElementKindContentBackground:
			return contentBackgroundAttributes
		default:
			guard let attributes = attributesForDecorationsByKind[kind] else {
				return nil
			}
			return attributes[indexPath.item]
		}
	}
	
	public var decorationAttributesByKind: [String: [CollectionViewLayoutAttributes]] {
		var attributes: [String: [CollectionViewLayoutAttributes]] = [:]
		
		attributes[collectionElementKindColumnSeparator] = columnSeparatorLayoutAttributes
		attributes[collectionElementKindSectionSeparator] = Array(sectionSeparatorLayoutAttributes.values)
		attributes[collectionElementKindRowSeparator] = rows.flatMap { $0.rowSeparatorLayoutAttributes }
		attributes[collectionElementKindGlobalHeaderBackground] = [backgroundAttributesForReading].flatMap { $0 }
		attributes[collectionElementKindContentBackground] = [contentBackgroundAttributes].flatMap { $0 }
		
		attributes.appendContents(of: attributesForDecorationsByKind)
		
		return attributes
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
	
	public func definesMetric(_ metric: String) -> Bool {
		return metrics.definesMetric(metric)
	}
	
	public func additionalLayoutAttributesToInsertForInsertionOfItem(at indexPath: IndexPath) -> [CollectionViewLayoutAttributes] {
		return []
	}
	
	public func additionalLayoutAttributesToDeleteForDeletionOfItem(at indexPath: IndexPath) -> [CollectionViewLayoutAttributes] {
		var attributes: [CollectionViewLayoutAttributes] = []
		
		if let rowSeparator = rowSeparatorAttributesToDeleteForDeletionOfItem(at: indexPath) {
			attributes.append(rowSeparator)
		}
		
		return attributes
	}
	
	fileprivate func rowSeparatorAttributesToDeleteForDeletionOfItem(at indexPath: IndexPath) -> CollectionViewLayoutAttributes? {
		guard metrics.showsRowSeparator else {
			return nil
		}
		
		let itemIndex = indexPath.item
		
		guard let rowInfo = row(forItemAt: itemIndex),
			let rowSeparatorAttributes = rowInfo.rowSeparatorLayoutAttributes else {
				return nil
		}
		
		if rowInfo.items.count == 1 {
			return rowSeparatorAttributes
		} else {
			return nil
		}
	}
	
	fileprivate var pinnableItems: [LayoutSupplementaryItem] = []
	
	public mutating func prepareForLayout() {
		pinnableItems.removeAll()
	}
	
	public func targetLayoutHeightForProposedLayoutHeight(_ proposedHeight: CGFloat, layoutInfo: LayoutInfo) -> CGFloat {
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
	
	public func targetContentOffsetForProposedContentOffset(_ proposedContentOffset: CGPoint, firstInsertedSectionMinY: CGFloat) -> CGPoint {
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
	
	var supplementaryElementKindsToPin: [String] {
		let orderedKinds = metrics.orderedSupplementaryElementKinds
		var pinnedKinds = [String]()
		for kind in orderedKinds {
			guard kind != UICollectionElementKindSectionFooter else {
				continue
			}
			
			pinnedKinds.append(kind)
			
			if kind == UICollectionElementKindSectionHeader {
				break
			}
		}
		
		return pinnedKinds
	}
	
	public mutating func updateSpecialItemsWithContentOffset(_ contentOffset: CGPoint, layoutInfo: LayoutInfo, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) {
		resetSupplementaryItems(pinnable: true, invalidationContext: invalidationContext)
		pinnableItems.removeAll(keepingCapacity: true)
		
		// Pin the headers as appropriate
		guard self.isGlobalSection else {
			return
		}
		
		var pinnableY = contentOffset.y + layoutInfo.contentInset.top + metrics.contentInset.top
		var nonPinnableY = pinnableY
		
		for kind in [collectionElementKindLeftAuxiliaryItem, collectionElementKindRightAuxiliaryItem] {
			guard supplementaryElementKindsToPin.contains(kind) else {
				continue
			}
			
			applyTopPinningToPinnableSupplementaryItems(ofKind: kind, minY: pinnableY, invalidationContext: invalidationContext)
		}
		
		pinnableY = applyTopPinningToPinnableSupplementaryItems(ofKind: UICollectionElementKindSectionHeader, minY: pinnableY, invalidationContext: invalidationContext)
		
		finalizePinningForSupplementaryItems(pinnable: true, zIndex: pinnedHeaderZIndex)
		
		if let backgroundAttributes = backgroundAttributesForReading {
			let nonPinnableHeaders = self.nonPinnableHeaders
			
			resetSupplementaryItems(pinnable: false, invalidationContext: invalidationContext)
			
			nonPinnableY = applyBottomPinningToNonPinnableSupplementaryItems(ofKind: UICollectionElementKindSectionHeader, maxY: nonPinnableY, invalidationContext: invalidationContext)
			
			finalizePinningForSupplementaryItems(pinnable: false, zIndex: pinnedHeaderZIndex)
			
			var frame = backgroundAttributes.frame
			frame.origin.y = min(nonPinnableY, layoutInfo.bounds.origin.y)
			let bottomY = max(pinnableHeaders.last?.frame.maxY ?? 0, nonPinnableHeaders.last?.frame.maxY ?? 0)
			frame.size.height = bottomY - frame.origin.y
			backgroundAttributes.frame = frame
		}
		
		mutateFirstSectionOverlappingYOffset(pinnableY, from: layoutInfo) { overlappingSection in
			overlappingSection.applyTopPinningToPinnableSupplementaryItems(ofKind: UICollectionElementKindSectionHeader, minY: pinnableY, invalidationContext: invalidationContext)
			
			// FIXME: Magic number
			overlappingSection.finalizePinningForSupplementaryItems(pinnable: true, zIndex: pinnedHeaderZIndex - 100)
		}
	}
	
	fileprivate mutating func resetSupplementaryItems(pinnable: Bool, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		for kind in supplementaryElementKindsToPin {
			resetSupplementaryItems(ofKind: kind, pinnable: pinnable, invalidationContext: invalidationContext)
		}
	}
	
	fileprivate mutating func resetSupplementaryItems(ofKind kind: String, pinnable: Bool, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		func resetter(_ item: GridLayoutSupplementaryItem, index: Int) -> GridLayoutSupplementaryItem {
			var item = item
			var frame = item.frame
			
			if frame.minY != item.unpinnedY {
				invalidationContext?.invalidate(item)
			}
			
			item.isPinned = false
			
			frame.origin.y = item.unpinnedY
			item.frame = frame
			
			return item
		}
		
		pinnable ?
			mutatePinnableSupplementaryItems(ofKind: kind, using: resetter)
			: mutateNonPinnableSupplementaryItems(ofKind: kind, using: resetter)
	}
	
	fileprivate mutating func applyBottomPinningToNonPinnableSupplementaryItems(ofKind kind: String, maxY: CGFloat, invalidationContext: UICollectionViewLayoutInvalidationContext?) -> CGFloat {
		var maxY = maxY
		
		mutateNonPinnableSupplementaryItems(ofKind: kind, inReverse: true) { (nonPinnableItem, index) in
			var frame = nonPinnableItem.frame
			
			guard frame.maxY < maxY else {
				return nonPinnableItem
			}
			
			var nonPinnableItem = nonPinnableItem
			
			maxY -= frame.height
			frame.origin.y = maxY
			nonPinnableItem.frame = frame
			
			invalidationContext?.invalidate(nonPinnableItem)
			return nonPinnableItem
		}
		
		return maxY
	}
	
	/// Pins the pinnable headers starting at `minY` -- as long as they don't cross `minY` -- and returns the new `minY`.
	fileprivate mutating func applyTopPinningToPinnableSupplementaryItems(ofKind kind: String, minY: CGFloat, invalidationContext: UICollectionViewLayoutInvalidationContext?) -> CGFloat {
		var minY = minY
		
		mutatePinnableSupplementaryItems(ofKind: kind) { (pinnableItem, index) in
			var frame = pinnableItem.frame
			
			guard frame.minY < minY else {
				return pinnableItem
			}
			
			var pinnableItem = pinnableItem
			
			// We have a new pinning offset
			frame.origin.y = minY
			minY = frame.maxY
			pinnableItem.frame = frame
			
			invalidationContext?.invalidate(pinnableItem)
			return pinnableItem
		}
		
		return minY
	}
	
	fileprivate mutating func finalizePinningForSupplementaryItems(pinnable: Bool, zIndex: Int) {
		for kind in supplementaryElementKindsToPin {
			finalizePinningForSupplementaryItems(ofKind: kind, pinnable: pinnable, zIndex: zIndex)
		}
	}
	
	fileprivate mutating func finalizePinningForSupplementaryItems(ofKind kind: String, pinnable: Bool, zIndex: Int) {
		func finalizer(_ item: GridLayoutSupplementaryItem, index: Int) -> GridLayoutSupplementaryItem {
			var item = item
			
			item.isPinned = item.frame.minY != item.unpinnedY
			
			let depth = index + 1
			item.zIndex = zIndex - depth
			
			return item
		}
		
		pinnable ?
			mutatePinnableSupplementaryItems(ofKind: kind, using: finalizer)
			: mutateNonPinnableSupplementaryItems(ofKind: kind, using: finalizer)
	}
	
	fileprivate mutating func mutateFirstSectionOverlappingYOffset(_ yOffset: CGFloat, from layoutInfo: LayoutInfo, using mutator: (inout BasicGridLayoutSection) -> Void) {
		layoutInfo.enumerateSections { (sectionIndex, sectionInfo, stop) in
			guard sectionIndex != globalSectionIndex else {
				return
			}
			
			let frame = sectionInfo.frame
			if frame.minY <= yOffset && yOffset <= frame.maxY,
				var gridSectionInfo = sectionInfo as? BasicGridLayoutSection {
				mutator(&gridSectionInfo)
				sectionInfo = gridSectionInfo
				stop = true
			}
		}
	}
	
	public mutating func mutatePinnableSupplementaryItems(ofKind kind: String, using transformer: (_ pinnableItem: GridLayoutSupplementaryItem, _ index: Int) -> GridLayoutSupplementaryItem) {
		var items = supplementaryItems(of: kind)
		
		for index in items.indices {
			guard var item = items[index] as? GridLayoutSupplementaryItem, item.shouldPin else {
					continue
			}
			
			item = transformer(item, index)
			items[index] = item
		}
		
		supplementaryItemsByKind[kind] = items
	}
	
	public mutating func mutateNonPinnableSupplementaryItems(ofKind kind: String, inReverse: Bool = false, using transformer: (_ nonPinnableItem: GridLayoutSupplementaryItem, _ index: Int) -> GridLayoutSupplementaryItem) {
		var items = supplementaryItems(of: kind)
		
		let itemIndices = inReverse ?
			AnyCollection<Int>(items.indices.reversed())
			: AnyCollection<Int>(items.indices)
		
		for index in itemIndices {
			guard var item = items[index] as? GridLayoutSupplementaryItem, !item.shouldPin else {
					continue
			}
			
			item = transformer(item, index)
			items[index] = item
		}
		
		supplementaryItemsByKind[kind] = items
	}
	
	public func isEqual(to other: LayoutSection) -> Bool {
		guard let other = other as? BasicGridLayoutSection else {
			return false
		}
		
		return sectionIndex == other.sectionIndex
	}
	
}
