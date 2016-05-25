//
//  TableLayoutSectionBuilder.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 4/19/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public struct TableLayoutSectionBuilder: LayoutSectionBuilder {
	
	public init?(metrics: SectionMetrics) {
		guard let tableMetrics = metrics as? TableSectionMetricsProviding else {
			return nil
		}
		self.metrics = tableMetrics
	}
	
	private let metrics: TableSectionMetricsProviding
	
	public func makeLayoutSection(using description: SectionDescription, in layoutBounds: LayoutAreaBounds) -> LayoutSection {
		var section = TableLayoutSection()
		
		let numberOfItems = description.numberOfItems
		let origin = layoutBounds.origin
		let width = layoutBounds.width
		let sectionIndex = description.sectionIndex
		let margins = metrics.padding
		
		section.frame.origin = layoutBounds.origin
		section.frame.size.width = layoutBounds.width
		
		var positionBounds = layoutBounds
		
		// Layout headers
		if let headers = description.supplementaryItemsByKind[UICollectionElementKindSectionHeader] {
			let layoutItems = SupplementaryItemStackBuilder().makeLayoutItems(for: headers, using: description, in: positionBounds)
			
			for layoutItem in layoutItems {
				positionBounds.origin.y += layoutItem.fixedHeight
				section.add(layoutItem)
			}
		}
		
		// Layout content area
		if var placeholder = description.placeholder where placeholder.startingSectionIndex == sectionIndex {
			// Layout placeholder
			placeholder.frame = CGRect(x: origin.x, y: origin.y, width: width, height: placeholder.height)
			
			if placeholder.hasEstimatedHeight, let sizing = description.sizingInfo {
				let measuredSize = sizing.measuredSizeForPlaceholder(placeholder)
				placeholder.height = measuredSize.height
				placeholder.frame.size.height = placeholder.height
				placeholder.hasEstimatedHeight = false
			}
			
			positionBounds.origin.y += placeholder.height
			section.placeholderInfo = placeholder
		}
		else if numberOfItems > 0 {
			// Layout items
			positionBounds.origin.y += margins.top
			
			var cellBounds = positionBounds
			cellBounds.origin.x += margins.left
			cellBounds.width -= margins.width
			
			let rows = TableRowStackBuilder().makeLayoutRows(using: description, in: cellBounds)
			
			for row in rows {
				positionBounds.origin.y += row.frame.height
				section.add(row)
			}
			
			positionBounds.origin.y += margins.bottom
		}
		
		// Layout footers
		if let footers = description.supplementaryItemsByKind[UICollectionElementKindSectionFooter] {
			let layoutItems = SupplementaryItemStackBuilder().makeLayoutItems(for: footers, using: description, in: positionBounds)
			
			for layoutItem in layoutItems {
				positionBounds.origin.y += layoutItem.fixedHeight
				section.add(layoutItem)
			}
		}
		
		let sectionHeight = positionBounds.origin.y - origin.y
		section.frame = CGRect(x: origin.x, y: origin.x, width: width, height: sectionHeight)
		
		return section
	}
	
}

public struct SupplementaryItemStackBuilder {
	
	func makeLayoutItems(for supplementaryItems: [SupplementaryItem], using description: SectionDescription, in layoutBounds: LayoutAreaBounds) -> [LayoutSupplementaryItem] {
		var layoutItems = [LayoutSupplementaryItem]()
		
		var positionBounds = layoutBounds
		
		for supplementaryItem in supplementaryItems {
			guard let layoutItem = makeLayoutItem(for: supplementaryItem, using: description, in: positionBounds) else {
				continue
			}
			
			positionBounds.origin.y += layoutItem.fixedHeight
			layoutItems.append(layoutItem)
		}
		
		return layoutItems
	}
	
	func makeLayoutItem(for supplementaryItem: SupplementaryItem, using description: SectionDescription, in layoutBounds: LayoutAreaBounds) -> LayoutSupplementaryItem? {
		guard description.numberOfItems > 0 || supplementaryItem.isVisibleWhileShowingPlaceholder else {
			return nil
		}
		
		var height = supplementaryItem.fixedHeight
		
		guard height > 0 && !supplementaryItem.isHidden else {
			return nil
		}
		
		var layoutItem = TableLayoutSupplementaryItem(supplementaryItem: supplementaryItem)
		
		let origin = layoutBounds.origin

		layoutItem.frame = CGRect(x: origin.x, y: origin.y, width: layoutBounds.width, height: height)
		
		if supplementaryItem.hasEstimatedHeight, let sizing = description.sizingInfo {
			let measuredSize = sizing.measuredSizeForSupplementaryItem(layoutItem)
			height = measuredSize.height
			layoutItem.height = height
			layoutItem.frame.size.height = height
		}
		
		return layoutItem
	}
	
}

public struct TableRowStackBuilder {
	
	typealias RowContext = (row: LayoutRow, position: CGPoint, rowHeight: CGFloat, itemHeight: CGFloat, columnIndex: Int)
	
	static let hairline = 1 / UIScreen.mainScreen().scale

	public func makeLayoutRows(using description: SectionDescription, in layoutBounds: LayoutAreaBounds) -> [LayoutRow] {
		var rows = [LayoutRow]()
		
		guard let metrics = description.metrics as? TableRowMetricsProviding else {
			return rows
		}
		
		let origin = layoutBounds.origin
		let width = layoutBounds.width
		
		let numberOfColumns = metrics.numberOfColumns
		let columnWidth = width / CGFloat(numberOfColumns)
		
		var position = origin
		var rowHeight: CGFloat = 0
		var itemHeight: CGFloat = 0
		var columnIndex = 0
		
		func makeRow() -> LayoutRow {
			var positionBounds = layoutBounds
			positionBounds.origin = position
			return self.makeRow(using: description, in: positionBounds)
		}
		
		var row = makeRow()
		
		func nextColumn() {
			if rowHeight < itemHeight {
				rowHeight = itemHeight
			}
			
			position.x += columnWidth
			
			columnIndex += 1
			
			row.frame.size.height = rowHeight
			
			guard columnIndex == numberOfColumns else {
				return
			}
			
			position.y += rowHeight
			rowHeight = 0
			columnIndex = 0
			
			position.x = origin.x
			
			if !row.items.isEmpty {
				decorate(&row, atIndex: rows.count, using: metrics)
				position.y = row.frame.maxY
				rows.append(row)
				
				row = makeRow()
			}
		}
		
		for itemIndex in 0..<description.numberOfItems {
			var item = makeItem(atIndex: itemIndex, using: description)
			
			if itemIndex == description.phantomCellIndex {
				itemHeight = description.phantomCellSize.height
				nextColumn()
			}
			
			itemHeight = item.frame.height
			item.frame.origin = position
			item.frame.size.width = columnWidth
			item.columnIndex = columnIndex
			
			if itemIndex == description.draggedItemIndex {
				row.add(item)
				continue
			}
			
			if item.hasEstimatedHeight, let sizing = description.sizingInfo {
				let measuredSize = sizing.measuredSizeForItem(item)
				itemHeight = measuredSize.height
				item.frame.size.height = itemHeight
				item.hasEstimatedHeight = false
			}
			
			row.add(item)
			
			nextColumn()
		}
		
		if !row.items.isEmpty {
			rows.append(row)
		}
		
		return rows
	}
	
	func makeRow(using description: SectionDescription, in layoutBounds: LayoutAreaBounds) -> LayoutRow {
		var row = LayoutRow()
		row.sectionIndex = description.sectionIndex
		
		let origin = layoutBounds.origin
		let size = CGSize(width: layoutBounds.width, height: 0)
		row.frame = CGRect(origin: origin, size: size)
		
		return row
	}
	
	func makeItem(atIndex itemIndex: Int, using description: SectionDescription) -> LayoutItem {
		var item = TableLayoutItem()
		
		item.itemIndex = itemIndex
		item.sectionIndex = description.sectionIndex
		
		if let metrics = description.metrics as? TableSectionMetrics {
			let rowHeight = metrics.rowHeight ?? metrics.estimatedRowHeight
			item.frame.size.height = rowHeight
			
			let isVariableRowHeight = metrics.rowHeight == nil
			item.hasEstimatedHeight = isVariableRowHeight
		}
		
		return item
	}
	
	func decorate(inout row: LayoutRow, atIndex index: Int, using metrics: TableRowMetricsProviding) {
		guard metrics.showsRowSeparator else {
			return
		}
		
		var separatorDecoration = HorizontalSeparatorDecoration(elementKind: collectionElementKindRowSeparator, position: .bottom)
		
		separatorDecoration.itemIndex = index
		separatorDecoration.sectionIndex = row.sectionIndex
		separatorDecoration.color = metrics.separatorColor
		separatorDecoration.zIndex = separatorZIndex
		
		let insets = metrics.separatorInsets
		separatorDecoration.leftMargin = insets.left
		separatorDecoration.rightMargin = insets.right
		
		separatorDecoration.setContainerFrame(row.frame, invalidationContext: nil)
		
		row.rowSeparatorDecoration = separatorDecoration
		row.frame.size.height += separatorDecoration.thickness
	}
	
}
