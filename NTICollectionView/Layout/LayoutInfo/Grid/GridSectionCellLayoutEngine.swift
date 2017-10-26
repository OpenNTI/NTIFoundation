//
//  GridSectionCellLayoutEngine.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/25/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

// TODO: Write test that ensures items have width before their height is measured
open class GridSectionCellLayoutEngine: NSObject, LayoutEngine {
	
	public init(layoutSection: GridLayoutSection) {
		self.layoutSection = layoutSection
		super.init()
	}
	
	open var layoutSection: GridLayoutSection
	
	fileprivate var metrics: GridSectionMetricsProviding {
		return layoutSection.metrics
	}
	fileprivate var margins: UIEdgeInsets {
		return metrics.padding
	}
	fileprivate var numberOfColumns: Int {
		return metrics.numberOfColumns
	}
	fileprivate var numberOfItems: Int {
		return layoutSection.items.count
	}
	
	fileprivate var width: CGFloat! {
		return layoutSizing.width
	}
	
	fileprivate var columnWidth: CGFloat {
		return layoutSection.columnWidth
	}
	fileprivate var fixedColumnWidth: CGFloat? {
		return metrics.fixedColumnWidth
	}
	fileprivate var phantomCellIndex: Int? {
		return layoutSection.phantomCellIndex
	}
	fileprivate var phantomCellSize: CGSize {
		return layoutSection.phantomCellSize
	}
	
	fileprivate var shouldLayoutItems: Bool {
		return layoutSection.placeholderInfo == nil && numberOfItems > 0
	}
	
	fileprivate var origin: CGPoint!
	fileprivate var position: CGPoint!
	fileprivate var columnIndex: Int = 0
	fileprivate var rowHeight: CGFloat!
	fileprivate var row: LayoutRow!
	fileprivate var height: CGFloat = 0
	
	fileprivate var layoutSizing: LayoutSizing!
	fileprivate var layoutMeasure: CollectionViewLayoutMeasuring!
	fileprivate var invalidationContext: UICollectionViewLayoutInvalidationContext?
	
	open func layoutWithOrigin(_ start: CGPoint, layoutSizing: LayoutSizing, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) -> CGPoint {
		guard let layoutMeasure = layoutSizing.layoutMeasure else {
				return CGPoint.zero
		}
		self.layoutSizing = layoutSizing
		self.layoutMeasure = layoutMeasure
		self.invalidationContext = invalidationContext
		
		reset()
		origin = start
		position = start
		
		layoutRows()
		
		return position
	}
	
	fileprivate func layoutRows() {
		guard shouldLayoutItems else {
			return
		}
		applyLeadingMargins()
		startNewRow()
		updateRowFrame()
		layoutItems()
		
		if rowContainsItems {
			commitCurrentRow()
		}
		
		advancePositionForBottomMargin()
	}
	
	fileprivate func applyLeadingMargins() {
		applyTopMargin()
		applyLeadingHorizontalMargin()
	}
	
	fileprivate func applyTopMargin() {
		position.y += margins.top
	}
	
	fileprivate func applyLeadingHorizontalMargin() {
		switch metrics.cellLayoutOrder {
		case .LeadingToTrailing:
			position.x += margins.left
		case .TrailingToLeading:
			position.x -= margins.right
		}
	}
	
	fileprivate func startNewRow() {
		row = LayoutRow()
		row.metrics.applyValues(from: metrics)
	}
	
	fileprivate func updateRowFrame() {
		row.frame = CGRect(x: origin.x + margins.left, y: position.y, width: width - margins.width, height: rowHeight)
	}
	
	fileprivate func layoutItems() {
		for (index, item) in layoutSection.items.enumerated() {
			var item = item
			layout(&item, at: index)
		}
	}
	
	fileprivate func layout(_ item: inout LayoutItem, at itemIndex: Int) {
		checkForPhantomCell(at: itemIndex)
		updateHeight(with: item)
		if item.isDragging {
			layout(&item, isInColumn: false)
			return
		}
		checkEstimatedHeight(of: &item)
		layout(&item, isInColumn: true)
		invalidate(item)
		nextColumn()
	}
	
	fileprivate func checkForPhantomCell(at itemIndex: Int) {
		let isPhantomCell = itemIndex == phantomCellIndex
		if isPhantomCell {
			updateForPhantomCell()
		}
	}
	
	fileprivate func updateForPhantomCell() {
		height = phantomCellSize.height
		nextColumn()
	}
	
	fileprivate func updateHeight(with item: LayoutItem) {
		height = item.frame.height
	}
	
	fileprivate func layout(_ item: inout LayoutItem, isInColumn: Bool) {
		updateFrame(of: &item)
		item.columnIndex = isInColumn ? columnIndex : NSNotFound
		row.add(item)
	}
	
	fileprivate func updateFrame(of item: inout LayoutItem) {
		let columnWidth = fixedColumnWidth ?? row.columnWidth(forNumberOfColumns: numberOfColumns)
		item.frame = CGRect(x: position.x, y: position.y, width: columnWidth, height: height)
	}
	
	fileprivate func checkEstimatedHeight(of item: inout LayoutItem) {
		if item.hasEstimatedHeight {
			measureHeight(of: &item)
		}
	}
	
	fileprivate func measureHeight(of item: inout LayoutItem) {
		updateFrame(of: &item)
		let measuredSize = layoutMeasure.measuredSizeForItem(item)
		height = measuredSize.height
		updateFrame(of: &item)
		item.hasEstimatedHeight = false
	}
	
	fileprivate func invalidate(_ item: LayoutItem) {
		invalidationContext?.invalidateItems(at: [item.indexPath as IndexPath])
	}
	
	fileprivate func advancePositionForBottomMargin() {
		position.y += margins.bottom
	}
	
	// Advance to the next column and if necessary the next row. Takes into account the phantom cell index.
	fileprivate func nextColumn() {
		updateRowHeight()
		advanceToNextColumn()
		checkForNextRow()
	}
	
	fileprivate func updateRowHeight() {
		fitRowHeightToItemHeight()
		updateRowFrameHeight()
	}
	
	fileprivate func fitRowHeightToItemHeight() {
		if rowHeight < height {
			rowHeight = height
		}
	}
	
	fileprivate func advanceToNextColumn() {
		advanceLayoutPositionToNextColumn()
		advanceColumnIndex()
	}
	
	fileprivate func advanceLayoutPositionToNextColumn() {
		switch metrics.cellLayoutOrder {
		case .LeadingToTrailing:
			position.x += columnWidth + metrics.minimumInteritemSpacing
		case .TrailingToLeading:
			position.x -= columnWidth + metrics.minimumInteritemSpacing
		}
	}
	
	fileprivate func advanceColumnIndex() {
		columnIndex += 1
	}
	
	fileprivate func updateRowFrameHeight() {
		row.frame.size.height = rowHeight
	}
	
	fileprivate func checkForNextRow() {
		if columnIndexStartsNewRow {
			nextRow()
		}
	}
	
	fileprivate var columnIndexStartsNewRow: Bool {
		return columnIndex == numberOfColumns
	}
	
	fileprivate func nextRow() {
		adjustPositionForNextRow()
		reset()
		processNextRow()
		updateRowFrame()
	}
	
	fileprivate func adjustPositionForNextRow() {
		advanceYPositionToNextRow()
		resetXPositionToColumnStart()
	}
	
	fileprivate func advanceYPositionToNextRow() {
		position.y += metrics.rowSpacing + rowHeight
	}
	
	fileprivate func resetXPositionToColumnStart() {
		switch metrics.cellLayoutOrder {
		case .LeadingToTrailing:
			position.x = origin.x + margins.left
		case .TrailingToLeading:
			position.x = width - margins.right - columnWidth
		}
	}
	
	fileprivate func reset() {
		height = 0
		rowHeight = 0
		columnIndex = 0
	}
	
	fileprivate func processNextRow() {
		if rowContainsItems {
			commitCurrentRow()
			startNewRow()
		}
	}
	
	fileprivate var rowContainsItems: Bool {
		return row.items.count > 0
	}
	
	fileprivate func commitCurrentRow() {
		var row: LayoutRow = self.row
		layoutSection.add(&row)
		self.row = row
		// Update the origin based on the actual frame of the row
		position.y = row.frame.maxY + metrics.rowSpacing
	}
	
}
