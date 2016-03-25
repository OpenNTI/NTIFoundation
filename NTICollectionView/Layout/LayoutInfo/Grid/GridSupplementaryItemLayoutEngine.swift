//
//  GridSupplementaryItemLayoutEngine.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 3/10/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public protocol SupplementaryLayoutEngine: LayoutEngine {
	var pinnableHeaders: [LayoutSupplementaryItem] { get }
	var nonPinnableHeaders: [LayoutSupplementaryItem] { get }
}

public typealias SupplementaryLayoutEngineFactory = (layoutSection: LayoutSection, supplementaryItems: [LayoutSupplementaryItem]) -> SupplementaryLayoutEngine

public class GridSupplementaryItemLayoutEngine: NSObject, SupplementaryLayoutEngine {

	public init(layoutSection: GridLayoutSection, innerLayoutEngine: LayoutEngine) {
		self.layoutSection = layoutSection
		self.innerLayoutEngine = innerLayoutEngine
		super.init()
	}
	
	public var layoutSection: GridLayoutSection
	public var innerLayoutEngine: LayoutEngine
	
	public var factory: SupplementaryLayoutEngineFactory?
	
	public var pinnableHeaders: [LayoutSupplementaryItem] = []
	public var nonPinnableHeaders: [LayoutSupplementaryItem] = []
	
	private var metrics: GridSectionMetrics {
		return layoutSection.metrics
	}
	private var contentInset: UIEdgeInsets {
		return metrics.contentInset
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
	
	private var columnWidth: CGFloat {
		return layoutSection.columnWidth
	}
	private var phantomCellIndex: Int? {
		return layoutSection.phantomCellIndex
	}
	private var phantomCellSize: CGSize {
		return layoutSection.phantomCellSize
	}
	
	private var origin = CGPointZero
	private var position = CGPointZero
	private var insetOrigin = CGPointZero
	
	private var headerFooterMinX: CGFloat = 0
	
	private var headersMinX: CGFloat = 0
	private var footersMinX: CGFloat = 0
	
	private var headersMaxX: CGFloat = 0
	private var footersMaxX: CGFloat = 0
	
	private var headersWidth: CGFloat {
		return headersMaxX - headersMinX
	}
	private var footersWidth: CGFloat {
		return footersMaxX - footersMinX
	}
	
	private var headersMaxY: CGFloat = 0
	
	private var footersMinY: CGFloat = 0
	private var footersMaxY: CGFloat = 0
	
	private var leftAuxiliaryItemsMinY: CGFloat = 0
	private var rightAuxiliaryItemsMinY: CGFloat = 0
	
	private var leftAuxiliaryItemsMaxX: CGFloat {
		return insetOrigin.x + leftAuxiliaryColumnWidth
	}
	private var leftAuxiliaryItemsMaxY: CGFloat = 0
	
	private var rightAuxiliaryItemsMaxY: CGFloat = 0
	
	var layoutSizing: LayoutSizing!
	var layoutMeasure: CollectionViewLayoutMeasuring!
	var invalidationContext: UICollectionViewLayoutInvalidationContext?
	
	private var width: CGFloat! {
		return layoutSizing.width - contentInset.width
	}
	
	private var leftAuxiliaryColumnWidth: CGFloat {
		return layoutSection.leftAuxiliaryColumnWidth
	}
	
	private var rightAuxiliaryColumnWidth: CGFloat {
		return layoutSection.rightAuxiliaryColumnWidth
	}
	
	private var supplementaryOrdering: Set<GridSectionSupplementaryItemOrder> {
		return metrics.supplementaryOrdering
	}
	
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
		
		applyLeadingContentInset()
		insetOrigin = position
		
		planLayout()
		
		layoutHeaders()
		
		layoutLeftAuxiliaryItems()
		
		layoutRightAuxiliaryItems()
		
		layoutSectionPlaceholder()
		
		layoutInnerContent()
		
		layoutFooters()
		
		layoutSection.pinnableHeaders = pinnableHeaders
		layoutSection.nonPinnableHeaders = nonPinnableHeaders
		
		position.x = origin.x + layoutSizing.width
		position.y = max(footersMaxY, leftAuxiliaryItemsMaxY, rightAuxiliaryItemsMaxY)
		applyBottomContentInset()
		
		return position
	}
	
	private func reset() {
		position = CGPoint(x: 0, y: 0)
		pinnableHeaders = []
		nonPinnableHeaders = []
	}
	
	private func applyLeadingContentInset() {
		position.x += contentInset.left
		position.y += contentInset.top
	}
	
	private func applyBottomContentInset() {
		position.y += contentInset.bottom
	}
	
	private var supplementaryOrders: (headers: Int, footers: Int, leftAux: Int, rightAux: Int) {
		var orders = (headers: Int.max, footers: Int.max, leftAux: Int.max, rightAux: Int.max)
		for order in supplementaryOrdering {
			switch order {
			case .header(order: let order):
				orders.headers = order
			case .footer(order: let order):
				orders.footers = order
			case .leftAuxiliary(order: let order):
				orders.leftAux = order
			case .rightAuxiliary(order: let order):
				orders.rightAux = order
			}
		}
		return orders
	}
	
	private func planLayout() {
		let orders = supplementaryOrders
		
		let insetX = insetOrigin.x
		headersMinX = orders.leftAux < orders.headers ? insetX + leftAuxiliaryColumnWidth : insetX
		footersMinX = orders.leftAux < orders.footers ? insetX + leftAuxiliaryColumnWidth : insetX
		
		let maxX = insetX + width
		headersMaxX = orders.rightAux < orders.headers ? maxX - rightAuxiliaryColumnWidth : maxX
		footersMaxX = orders.rightAux < orders.footers ? maxX - rightAuxiliaryColumnWidth : maxX
	}
	
	private func layoutHeaders() {
		position = headersOrigin
		headerFooterMinX = position.x
		let headersSizing = LayoutSizingInfo(width: headersWidth, layoutMeasure: layoutMeasure)
		layout(layoutSection.headers, using: headersSizing)
		headersMaxY = position.y
	}
	private var headersOrigin: CGPoint {
		return CGPoint(x: headersMinX, y: insetOrigin.y)
	}
	
	private func layoutLeftAuxiliaryItems() {
		defer {
			leftAuxiliaryItemsMaxY = position.y
		}
		guard leftAuxiliaryColumnWidth > 0 else {
			return
		}
		position = leftAuxiliaryItemsOrigin
		let sizing = LayoutSizingInfo(width: leftAuxiliaryColumnWidth, layoutMeasure: layoutMeasure)
		layout(layoutSection.leftAuxiliaryItems, using: sizing, spacing: metrics.auxiliaryColumnSpacing)
	}
	private var leftAuxiliaryItemsOrigin: CGPoint {
		let orders = supplementaryOrders
		let y = orders.headers < orders.leftAux ? headersMaxY : insetOrigin.y
		return CGPoint(x: insetOrigin.x, y: y)
	}
	
	private func layoutRightAuxiliaryItems() {
		defer {
			rightAuxiliaryItemsMaxY = position.y
		}
		guard rightAuxiliaryColumnWidth > 0 else {
			return
		}
		position = rightAuxiliaryItemsOrigin
		let sizing = LayoutSizingInfo(width: rightAuxiliaryColumnWidth, layoutMeasure: layoutMeasure)
		layout(layoutSection.rightAuxiliaryItems, using: sizing, spacing: metrics.auxiliaryColumnSpacing)
	}
	private var rightAuxiliaryItemsOrigin: CGPoint {
		let x = insetOrigin.x + width - rightAuxiliaryColumnWidth
		let orders = supplementaryOrders
		let y = orders.headers < orders.rightAux ? headersMaxY : insetOrigin.y
		return CGPoint(x: x, y: y)
	}
	
	private func layoutFooters() {
		position = footersOrigin
		let sizing = LayoutSizingInfo(width: width, layoutMeasure: layoutMeasure)
		layout(layoutSection.footers, using: sizing)
		footersMaxY = position.y
	}
	private var footersOrigin: CGPoint {
		return CGPoint(x: footersMinX, y: footersMinY)
	}
	
	private func layout(supplementaryItems: [LayoutSupplementaryItem], using sizing: LayoutSizing, spacing: CGFloat = 0) {
		let engine = makeSupplementaryLayoutEngine(for: layoutSection, with: supplementaryItems, spacing: spacing)
		position = engine.layoutWithOrigin(position, layoutSizing: sizing, invalidationContext: invalidationContext)
		pinnableHeaders += engine.pinnableHeaders
		nonPinnableHeaders += engine.nonPinnableHeaders
	}
	
	private func makeSupplementaryLayoutEngine(`for` layoutSection: GridLayoutSection, with supplementaryItems: [LayoutSupplementaryItem], spacing: CGFloat = 0) -> SupplementaryLayoutEngine {
		if let factory = self.factory {
			return factory(layoutSection: layoutSection, supplementaryItems: supplementaryItems)
		}
		let engine = GridSectionColumnLayoutEngine(layoutSection: layoutSection, supplementaryItems: supplementaryItems)
		engine.spacing = spacing
		return engine
	}
	
	private func layoutSectionPlaceholder() {
		guard let placeholderInfo = layoutSection.placeholderInfo
			where placeholderInfo.startsAt(layoutSection) else {
				return
		}
		layout(placeholderInfo)
	}
	private func layout(placeholderInfo: LayoutPlaceholder) {
		updateFrame(of: placeholderInfo)
		checkEstimatedHeight(of: placeholderInfo)
		updateOrigin(with: placeholderInfo)
	}
	private func updateFrame(of placeholderInfo: LayoutPlaceholder) {
		placeholderInfo.frame = CGRect(x: 0, y: position.y, width: width, height: placeholderInfo.height)
	}
	private func checkEstimatedHeight(of placeholderInfo: LayoutPlaceholder) {
		guard placeholderInfo.hasEstimatedHeight else {
			return
		}
		measureHeight(of: placeholderInfo)
		updateFrame(of: placeholderInfo)
	}
	private func measureHeight(of placeholderInfo: LayoutPlaceholder) {
		let measuredSize = layoutMeasure.measuredSizeForPlaceholder(placeholderInfo)
		// We'll add in the shared height in `finalizeLayout`
		placeholderInfo.height = measuredSize.height
		placeholderInfo.hasEstimatedHeight = false
	}
	private func updateOrigin(with placeholderInfo: LayoutPlaceholder) {
		position.y += placeholderInfo.height
	}
	
	private func layoutInnerContent() {
		let innerSizing = LayoutSizingInfo(width: innerContentWidth, layoutMeasure: layoutMeasure)
		position = innerContentOrigin
		position = innerLayoutEngine.layoutWithOrigin(position, layoutSizing: innerSizing, invalidationContext: invalidationContext)
		footersMinY = position.y + metrics.padding.bottom
	}
	private var innerContentWidth: CGFloat {
		return width - leftAuxiliaryColumnWidth - rightAuxiliaryColumnWidth - metrics.padding.width
	}
	private var innerContentOrigin: CGPoint {
		return CGPoint(x: innerContentMinX, y: innerContentMinY)
	}
	private var innerContentMinX: CGFloat {
		return leftAuxiliaryItemsMaxX + metrics.padding.left
	}
	private var innerContentMinY: CGFloat {
		return headersMaxY + metrics.padding.top
	}
	
}
