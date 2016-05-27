//
//  GridSectionCellLayoutEngine.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/25/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

// TODO: Write test that ensures items have width before their height is measured
public class GridSectionCellLayoutEngine: NSObject, LayoutEngine {
	
	public init(layoutSection: GridLayoutSection) {
		self.layoutSection = layoutSection
		super.init()
	}
	
	public var layoutSection: GridLayoutSection
	
	private var metrics: GridSectionMetricsProviding {
		return layoutSection.metrics
	}
	private var margins: UIEdgeInsets {
		return metrics.padding
	}
	private var numberOfColumns: Int {
		return metrics.numberOfColumns
	}
	private var numberOfItems: Int {
		return layoutSection.items.count
	}
	
	private var width: CGFloat! {
		return layoutSizing.width
	}
	
	private var columnWidth: CGFloat {
		return layoutSection.columnWidth
	}
	private var fixedColumnWidth: CGFloat? {
		return metrics.fixedColumnWidth
	}
	private var phantomCellIndex: Int? {
		return layoutSection.phantomCellIndex
	}
	private var phantomCellSize: CGSize {
		return layoutSection.phantomCellSize
	}
	
	private var shouldLayoutItems: Bool {
		return layoutSection.placeholderInfo == nil && numberOfItems > 0
	}
	
	private var origin: CGPoint!
	private var position: CGPoint!
	private var columnIndex: Int = 0
	private var rowHeight: CGFloat!
	private var row: LayoutRow!
	private var height: CGFloat = 0
	
	private var layoutSizing: LayoutSizing!
	private var layoutMeasure: CollectionViewLayoutMeasuring!
	private var invalidationContext: UICollectionViewLayoutInvalidationContext?
	
	public func layoutWithOrigin(start: CGPoint, layoutSizing: LayoutSizing, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) -> CGPoint {
		guard let layoutMeasure = layoutSizing.layoutMeasure else {
				return CGPointZero
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
	
	private func layoutRows() {
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
	
	private func applyLeadingMargins() {
		applyTopMargin()
		applyLeadingHorizontalMargin()
	}
	
	private func applyTopMargin() {
		position.y += margins.top
	}
	
	private func applyLeadingHorizontalMargin() {
		switch metrics.cellLayoutOrder {
		case .LeadingToTrailing:
			position.x += margins.left
		case .TrailingToLeading:
			position.x -= margins.right
		}
	}
	
	private func startNewRow() {
		row = LayoutRow()
		row.metrics.applyValues(from: metrics)
	}
	
	private func updateRowFrame() {
		row.frame = CGRect(x: origin.x + margins.left, y: position.y, width: width - margins.width, height: rowHeight)
	}
	
	private func layoutItems() {
		for (index, item) in layoutSection.items.enumerate() {
			var item = item
			layout(&item, at: index)
		}
	}
	
	private func layout(inout item: LayoutItem, at itemIndex: Int) {
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
	
	private func checkForPhantomCell(at itemIndex: Int) {
		let isPhantomCell = itemIndex == phantomCellIndex
		if isPhantomCell {
			updateForPhantomCell()
		}
	}
	
	private func updateForPhantomCell() {
		height = phantomCellSize.height
		nextColumn()
	}
	
	private func updateHeight(with item: LayoutItem) {
		height = item.frame.height
	}
	
	private func layout(inout item: LayoutItem, isInColumn: Bool) {
		updateFrame(of: &item)
		item.columnIndex = isInColumn ? columnIndex : NSNotFound
		row.add(item)
	}
	
	private func updateFrame(inout of item: LayoutItem) {
		let columnWidth = fixedColumnWidth ?? row.columnWidth(forNumberOfColumns: numberOfColumns)
		item.frame = CGRect(x: position.x, y: position.y, width: columnWidth, height: height)
	}
	
	private func checkEstimatedHeight(inout of item: LayoutItem) {
		if item.hasEstimatedHeight {
			measureHeight(of: &item)
		}
	}
	
	private func measureHeight(inout of item: LayoutItem) {
		updateFrame(of: &item)
		let measuredSize = layoutMeasure.measuredSizeForItem(item)
		height = measuredSize.height
		updateFrame(of: &item)
		item.hasEstimatedHeight = false
	}
	
	private func invalidate(item: LayoutItem) {
		invalidationContext?.invalidateItemsAtIndexPaths([item.indexPath])
	}
	
	private func advancePositionForBottomMargin() {
		position.y += margins.bottom
	}
	
	// Advance to the next column and if necessary the next row. Takes into account the phantom cell index.
	private func nextColumn() {
		updateRowHeight()
		advanceToNextColumn()
		checkForNextRow()
	}
	
	private func updateRowHeight() {
		fitRowHeightToItemHeight()
		updateRowFrameHeight()
	}
	
	private func fitRowHeightToItemHeight() {
		if rowHeight < height {
			rowHeight = height
		}
	}
	
	private func advanceToNextColumn() {
		advanceLayoutPositionToNextColumn()
		advanceColumnIndex()
	}
	
	private func advanceLayoutPositionToNextColumn() {
		switch metrics.cellLayoutOrder {
		case .LeadingToTrailing:
			position.x += columnWidth + metrics.minimumInteritemSpacing
		case .TrailingToLeading:
			position.x -= columnWidth + metrics.minimumInteritemSpacing
		}
	}
	
	private func advanceColumnIndex() {
		columnIndex += 1
	}
	
	private func updateRowFrameHeight() {
		row.frame.size.height = rowHeight
	}
	
	private func checkForNextRow() {
		if columnIndexStartsNewRow {
			nextRow()
		}
	}
	
	private var columnIndexStartsNewRow: Bool {
		return columnIndex == numberOfColumns
	}
	
	private func nextRow() {
		adjustPositionForNextRow()
		reset()
		processNextRow()
		updateRowFrame()
	}
	
	private func adjustPositionForNextRow() {
		advanceYPositionToNextRow()
		resetXPositionToColumnStart()
	}
	
	private func advanceYPositionToNextRow() {
		position.y += metrics.rowSpacing + rowHeight
	}
	
	private func resetXPositionToColumnStart() {
		switch metrics.cellLayoutOrder {
		case .LeadingToTrailing:
			position.x = origin.x + margins.left
		case .TrailingToLeading:
			position.x = width - margins.right - columnWidth
		}
	}
	
	private func reset() {
		height = 0
		rowHeight = 0
		columnIndex = 0
	}
	
	private func processNextRow() {
		if rowContainsItems {
			commitCurrentRow()
			startNewRow()
		}
	}
	
	private var rowContainsItems: Bool {
		return row.items.count > 0
	}
	
	private func commitCurrentRow() {
		var row: LayoutRow = self.row
		layoutSection.add(&row)
		self.row = row
		// Update the origin based on the actual frame of the row
		position.y = row.frame.maxY + metrics.rowSpacing
	}
	
}
