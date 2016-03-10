//
//  GridSectionCellLayoutEngine.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/25/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public class GridSectionCellLayoutEngine: NSObject {
	
	public init(layoutSection: GridLayoutSection) {
		self.layoutSection = layoutSection
		super.init()
	}
	
	public weak var layoutSection: GridLayoutSection!
	
	private var metrics: GridSectionMetrics {
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
	private var phantomCellIndex: Int? {
		return layoutSection.phantomCellIndex
	}
	private var phantomCellSize: CGSize {
		return layoutSection.phantomCellSize
	}
	
	private var shouldLayoutItems: Bool {
		return layoutSection.placeholderInfo == nil && numberOfItems > 0
	}
	
	var origin: CGPoint!
	private var columnIndex: Int = 0
	private var rowHeight: CGFloat!
	private var row: GridLayoutRow!
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
		
		layoutRows()
		
		return origin
	}
	
	private func layoutRows() {
		guard shouldLayoutItems else {
			return
		}
		advancePositionForTopMargin()
		startNewRow()
		updateRowFrame()
		layoutItems()
		
		if rowContainsItems {
			commitCurrentRow()
		}
		
		advancePositionForBottomMargin()
	}
	
	private func advancePositionForTopMargin() {
		origin.y += margins.top
	}
	
	private func startNewRow() {
		row = GridLayoutRow()
		row.section = layoutSection
	}
	
	private func updateRowFrame() {
		row.frame = CGRect(x: margins.left, y: origin.y, width: width, height: rowHeight)
	}
	
	private func layoutItems() {
		for (itemIndex, item) in layoutSection.items.enumerate() {
			layout(item, at: itemIndex)
		}
	}
	
	private func layout(item: LayoutItem, at itemIndex: Int) {
		checkForPhantomCell(at: itemIndex)
		updateHeight(with: item)
		if item.isDragging {
			layoutDragging(item)
			return
		}
		layout(item, isInColumn: true)
		checkEstimatedHeight(of: item)
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
	
	private func layoutDragging(item: LayoutItem) {
		layout(item, isInColumn: false)
	}
	
	private func layout(item: LayoutItem, isInColumn: Bool) {
		updateFrame(of: item)
		item.columnIndex = isInColumn ? columnIndex : NSNotFound
		row.add(item)
	}
	
	private func updateFrame(of item: LayoutItem) {
		item.frame = CGRect(x: origin.x, y: origin.y, width: columnWidth, height: height)
	}
	
	private func checkEstimatedHeight(of item: LayoutItem) {
		if item.hasEstimatedHeight {
			measureHeight(of: item)
		}
	}
	
	private func measureHeight(of item: LayoutItem) {
		let measuredSize = layoutMeasure.measuredSizeForItem(item)
		height = measuredSize.height
		updateFrame(of: item)
		item.hasEstimatedHeight = false
	}
	
	private func invalidate(item: LayoutItem) {
		invalidationContext?.invalidateItemsAtIndexPaths([item.indexPath])
	}
	
	private func advancePositionForBottomMargin() {
		origin.y += margins.bottom
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
			origin.x += columnWidth
		case .TrailingToLeading:
			origin.x -= columnWidth
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
		origin.y += rowHeight
	}
	
	private func resetXPositionToColumnStart() {
		switch metrics.cellLayoutOrder {
		case .LeadingToTrailing:
			origin.x = margins.left
		case .TrailingToLeading:
			origin.x = width - margins.right - columnWidth
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
		layoutSection.add(row)
		// Update the origin based on the actual frame of the row
		origin.y = row.frame.maxY
	}
	
}
