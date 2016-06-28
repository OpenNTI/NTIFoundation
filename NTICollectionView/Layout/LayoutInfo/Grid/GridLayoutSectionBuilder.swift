//
//  GridLayoutSectionBuilder.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 4/19/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public struct GridLayoutSectionBuilder: LayoutSectionBuilder {
	
	public init() {}
	
	public func makeLayoutSection(using description: SectionDescription, in layoutBounds: LayoutAreaBounds) -> LayoutSection {
		var section = GridLayoutSection()
		
		var description = description
		description.metrics.resolveMissingValuesFromTheme()
		
		guard var metrics = description.metrics as? GridSectionMetricsProviding else {
			return section
		}
		
		let numberOfItems = description.numberOfItems
		let origin = layoutBounds.origin
		let width = layoutBounds.width
		let sectionIndex = description.sectionIndex
		let margins = metrics.padding
		
		section.sectionIndex = sectionIndex
		section.frame.origin = origin
		section.frame.size.width = layoutBounds.width
		
		section.applyValues(from: description.metrics)
		
		let plan = GridLayoutPlanBuilder().makeLayoutItems(using: description, in: layoutBounds)
		
		for header in plan.headers {
			section.add(header)
		}
		
		for leftItem in plan.leftItems {
			section.add(leftItem)
		}
		
		for rightItem in plan.rightItems {
			section.add(rightItem)
		}
		
		var positionBounds = plan.contentBounds
		
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
			var cellBounds = positionBounds
			cellBounds.origin.x += margins.left + metrics.leftAuxiliaryColumnWidth
			cellBounds.width -= margins.width + metrics.leftAuxiliaryColumnWidth + metrics.rightAuxiliaryColumnWidth
			
			let rows = GridRowStackBuilder().makeLayoutRows(using: description, in: cellBounds)
			
			for row in rows {
				section.add(row)
			}
			
			if let lastRow = rows.last {
				positionBounds.origin.y = lastRow.frame.maxY
			}
			
			positionBounds.origin.y += margins.bottom
		}
		
		// Layout footers
		if let footers = description.supplementaryItemsByKind[UICollectionElementKindSectionFooter] {
			let layoutItems = GridLayoutPlanBuilder().makeLayoutItems(for: footers, using: description, in: positionBounds)
			
			for layoutItem in layoutItems {
				positionBounds.origin.y += layoutItem.fixedHeight
				section.add(layoutItem)
			}
		}
		
		let sectionHeight = positionBounds.origin.y - origin.y
		section.frame.size.height = sectionHeight
		
		return section
	}
	
}

public typealias GridLayoutPlan = (headers: [GridLayoutSupplementaryItem], leftItems: [GridLayoutSupplementaryItem], rightItems: [GridLayoutSupplementaryItem], contentBounds: LayoutAreaBounds)

public struct GridLayoutPlanBuilder {
	
	public func makeLayoutItems(using description: SectionDescription, in layoutBounds: LayoutAreaBounds) -> GridLayoutPlan {
		guard let metrics = description.metrics as? GridSectionMetricsProviding else {
			return (headers: [], leftItems: [], rightItems: [], contentBounds: layoutBounds)
		}
		
		var contentBounds = layoutBounds
		
		// Layout headers
		var layoutHeaders = [GridLayoutSupplementaryItem]()
		if let headers = description.supplementaryItemsByKind[UICollectionElementKindSectionHeader] {
			let layoutItems = makeLayoutItems(for: headers, using: description, in: layoutBounds)
			
			for layoutItem in layoutItems {
				contentBounds.origin.y += layoutItem.frame.height
				layoutHeaders.append(layoutItem)
			}
		}
		
		contentBounds.origin.y += metrics.padding.top
		
		// Layout left auxiliary items
		var layoutLeftItems = [GridLayoutSupplementaryItem]()
		if metrics.leftAuxiliaryColumnWidth > 0, let leftItems = description.supplementaryItemsByKind[collectionElementKindLeftAuxiliaryItem] {
			var leftItemBounds = contentBounds
			leftItemBounds.width = metrics.leftAuxiliaryColumnWidth
			
			let layoutItems = makeLayoutItems(for: leftItems, using: description, in: leftItemBounds)
			
			for layoutItem in layoutItems {
				layoutLeftItems.append(layoutItem)
			}
			
			contentBounds.origin.x += leftItemBounds.width
			contentBounds.width -= leftItemBounds.width
		}
		
		// Layout right auxiliary items
		var layoutRightItems = [GridLayoutSupplementaryItem]()
		if metrics.rightAuxiliaryColumnWidth > 0, let rightItems = description.supplementaryItemsByKind[collectionElementKindRightAuxiliaryItem] {
			var rightItemBounds = contentBounds
			rightItemBounds.width = metrics.rightAuxiliaryColumnWidth
			rightItemBounds.origin.x = layoutBounds.width - rightItemBounds.width
			
			let layoutItems = makeLayoutItems(for: rightItems, using: description, in: rightItemBounds)
			
			for layoutItem in layoutItems {
				layoutRightItems.append(layoutItem)
			}
			
			contentBounds.width -= rightItemBounds.width
		}
		
		contentBounds.origin.x += metrics.padding.left
		contentBounds.width -= metrics.padding.width
		
		return (headers: layoutHeaders, leftItems: layoutLeftItems, rightItems: layoutRightItems, contentBounds: contentBounds)
	}
	
	public func makeLayoutItems(for supplementaryItems: [SupplementaryItem], using description: SectionDescription, in layoutBounds: LayoutAreaBounds) -> [GridLayoutSupplementaryItem] {
		let metrics: LayoutItemStackMetrics = (description.metrics as? GridSectionMetricsProviding)?.makeLayoutItemStackMetrics() ?? .zero
		return SupplementaryItemStackBuilder<GridLayoutSupplementaryItem>().makeLayoutItems(for: supplementaryItems, using: description, in: layoutBounds, metrics: metrics).map {
			var layoutItem = $0
			layoutItem.unpinnedY = layoutItem.frame.minY
			return layoutItem
		}
	}
	
}

extension GridSectionMetricsProviding {
	
	public func makeLayoutItemStackMetrics() -> LayoutItemStackMetrics {
		return LayoutItemStackMetrics(spacing: auxiliaryColumnSpacing)
	}
	
}

public struct GridRowStackBuilder {
	
	typealias RowContext = (row: LayoutRow, position: CGPoint, rowHeight: CGFloat, itemHeight: CGFloat, columnIndex: Int)
	
	static let hairline = 1 / UIScreen.mainScreen().scale
	
	public func makeLayoutRows(using description: SectionDescription, in layoutBounds: LayoutAreaBounds) -> [LayoutRow] {
		var rows = [LayoutRow]()
		
		guard let metrics = description.metrics as? GridRowMetricsProviding else {
			return rows
		}
		
		let origin = layoutBounds.origin
		let width = layoutBounds.width
		
		let numberOfColumns = metrics.numberOfColumns
		let columnWidth = metrics.fixedColumnWidth ?? (width / CGFloat(numberOfColumns))
		
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
				position.y += metrics.rowSpacing
				
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
		} else {
			// Revert the last rowSpacing that was added
			position.y -= metrics.rowSpacing
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
		var item = GridLayoutItem()
		
		item.itemIndex = itemIndex
		item.sectionIndex = description.sectionIndex
		
		if let metrics = description.metrics as? GridSectionMetricsProviding {
			let rowHeight = metrics.rowHeight ?? metrics.estimatedRowHeight
			item.frame.size.height = rowHeight
			
			let isVariableRowHeight = metrics.rowHeight == nil
			item.hasEstimatedHeight = isVariableRowHeight
		}
		
		return item
	}
	
	func decorate(inout row: LayoutRow, atIndex index: Int, using metrics: GridRowMetricsProviding) {
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
