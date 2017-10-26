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
	var supplementaryItems: [LayoutSupplementaryItem] { get }
}

public typealias SupplementaryLayoutEngineFactory = (_ layoutSection: LayoutSection, _ supplementaryItems: [LayoutSupplementaryItem]) -> SupplementaryLayoutEngine

open class GridSupplementaryItemLayoutEngine: NSObject, SupplementaryLayoutEngine {

	public init(layoutSection: GridLayoutSection, innerLayoutEngine: LayoutEngine) {
		self.layoutSection = layoutSection
		self.innerLayoutEngine = innerLayoutEngine
		supplementaryItems = layoutSection.supplementaryItems
		super.init()
	}
	
	open var layoutSection: GridLayoutSection
	open var innerLayoutEngine: LayoutEngine
	
	open var factory: SupplementaryLayoutEngineFactory?
	
	open var pinnableHeaders: [LayoutSupplementaryItem] = []
	open var nonPinnableHeaders: [LayoutSupplementaryItem] = []
	open var supplementaryItems: [LayoutSupplementaryItem]
	
	fileprivate var metrics: GridSectionMetricsProviding {
		return layoutSection.metrics
	}
	fileprivate var contentInset: UIEdgeInsets {
		return metrics.contentInset
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
	
	fileprivate var columnWidth: CGFloat {
		return layoutSection.columnWidth
	}
	fileprivate var phantomCellIndex: Int? {
		return layoutSection.phantomCellIndex
	}
	fileprivate var phantomCellSize: CGSize {
		return layoutSection.phantomCellSize
	}
	
	fileprivate var origin = CGPoint.zero
	fileprivate var position = CGPoint.zero
	fileprivate var insetOrigin = CGPoint.zero
	
	fileprivate var headerFooterMinX: CGFloat = 0
	
	fileprivate var headersMinX: CGFloat = 0
	fileprivate var footersMinX: CGFloat = 0
	
	fileprivate var headersMaxX: CGFloat = 0
	fileprivate var footersMaxX: CGFloat = 0
	
	fileprivate var headersWidth: CGFloat {
		return headersMaxX - headersMinX
	}
	fileprivate var footersWidth: CGFloat {
		return footersMaxX - footersMinX
	}
	
	fileprivate var headersMaxY: CGFloat = 0
	
	fileprivate var footersMinY: CGFloat = 0
	fileprivate var footersMaxY: CGFloat = 0
	
	fileprivate var leftAuxiliaryItemsMinY: CGFloat = 0
	fileprivate var rightAuxiliaryItemsMinY: CGFloat = 0
	
	fileprivate var leftAuxiliaryItemsMaxX: CGFloat {
		return insetOrigin.x + leftAuxiliaryColumnWidth
	}
	fileprivate var leftAuxiliaryItemsMaxY: CGFloat = 0
	
	fileprivate var rightAuxiliaryItemsMaxY: CGFloat = 0
	
	var layoutSizing: LayoutSizing!
	var layoutMeasure: CollectionViewLayoutMeasuring!
	var invalidationContext: UICollectionViewLayoutInvalidationContext?
	
	fileprivate var width: CGFloat! {
		return layoutSizing.width - contentInset.width
	}
	
	fileprivate var leftAuxiliaryColumnWidth: CGFloat {
		return layoutSection.leftAuxiliaryColumnWidth
	}
	
	fileprivate var rightAuxiliaryColumnWidth: CGFloat {
		return layoutSection.rightAuxiliaryColumnWidth
	}
	
	fileprivate var supplementaryOrdering: Set<GridSectionSupplementaryItemOrder> {
		return metrics.supplementaryOrdering
	}
	
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
		
		applyLeadingContentInset()
		insetOrigin = position
		
		planLayout()
		
		layoutHeaders()
		
		layoutLeftAuxiliaryItems()
		
		layoutRightAuxiliaryItems()
		
		position = innerContentOrigin
		
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
	
	fileprivate func reset() {
		position = CGPoint(x: 0, y: 0)
		pinnableHeaders = []
		nonPinnableHeaders = []
	}
	
	fileprivate func applyLeadingContentInset() {
		position.x += contentInset.left
		position.y += contentInset.top
	}
	
	fileprivate func applyBottomContentInset() {
		position.y += contentInset.bottom
	}
	
	fileprivate var supplementaryOrders: (headers: Int, footers: Int, leftAux: Int, rightAux: Int) {
		return metrics.supplementaryOrders
	}
	
	fileprivate func planLayout() {
		let orders = metrics.supplementaryOrders
		
		let insetX = insetOrigin.x
		headersMinX = orders.leftAux < orders.headers ? insetX + leftAuxiliaryColumnWidth : insetX
		footersMinX = orders.leftAux < orders.footers ? insetX + leftAuxiliaryColumnWidth : insetX
		
		let maxX = insetX + width
		headersMaxX = orders.rightAux < orders.headers ? maxX - rightAuxiliaryColumnWidth : maxX
		footersMaxX = orders.rightAux < orders.footers ? maxX - rightAuxiliaryColumnWidth : maxX
	}
	
	fileprivate func layoutHeaders() {
		position = headersOrigin
		headerFooterMinX = position.x
		let headersSizing = LayoutSizingInfo(width: headersWidth, layoutMeasure: layoutMeasure)
		var headers = layoutSection.headers
		layout(&headers, using: headersSizing)
		layoutSection.headers = headers
		headersMaxY = position.y
	}
	fileprivate var headersOrigin: CGPoint {
		return CGPoint(x: headersMinX, y: insetOrigin.y)
	}
	
	fileprivate func layoutLeftAuxiliaryItems() {
		defer {
			leftAuxiliaryItemsMaxY = position.y
		}
		guard leftAuxiliaryColumnWidth > 0 else {
			return
		}
		position = leftAuxiliaryItemsOrigin
		let sizing = LayoutSizingInfo(width: leftAuxiliaryColumnWidth, layoutMeasure: layoutMeasure)
		var leftAuxiliaryItems = layoutSection.leftAuxiliaryItems
		layout(&leftAuxiliaryItems, using: sizing, spacing: metrics.auxiliaryColumnSpacing)
		layoutSection.leftAuxiliaryItems = leftAuxiliaryItems
	}
	fileprivate var leftAuxiliaryItemsOrigin: CGPoint {
		let orders = supplementaryOrders
		let y = orders.headers < orders.leftAux ? (headersMaxY + metrics.padding.top) : insetOrigin.y
		return CGPoint(x: insetOrigin.x, y: y)
	}
	
	fileprivate func layoutRightAuxiliaryItems() {
		defer {
			rightAuxiliaryItemsMaxY = position.y
		}
		guard rightAuxiliaryColumnWidth > 0 else {
			return
		}
		position = rightAuxiliaryItemsOrigin
		let sizing = LayoutSizingInfo(width: rightAuxiliaryColumnWidth, layoutMeasure: layoutMeasure)
		var rightAuxiliaryItems = layoutSection.rightAuxiliaryItems
		layout(&rightAuxiliaryItems, using: sizing, spacing: metrics.auxiliaryColumnSpacing)
		layoutSection.rightAuxiliaryItems = rightAuxiliaryItems
	}
	fileprivate var rightAuxiliaryItemsOrigin: CGPoint {
		let x = insetOrigin.x + width - rightAuxiliaryColumnWidth
		let orders = supplementaryOrders
		let y = orders.headers < orders.rightAux ? (headersMaxY + metrics.padding.top) : insetOrigin.y
		return CGPoint(x: x, y: y)
	}
	
	fileprivate func layoutFooters() {
		position = footersOrigin
		let sizing = LayoutSizingInfo(width: footersWidth, layoutMeasure: layoutMeasure)
		var footers = layoutSection.footers
		layout(&footers, using: sizing)
		layoutSection.footers = footers
		footersMaxY = position.y
	}
	fileprivate var footersOrigin: CGPoint {
		return CGPoint(x: footersMinX, y: footersMinY)
	}
	
	fileprivate func layout(_ supplementaryItems: inout [LayoutSupplementaryItem], using sizing: LayoutSizing, spacing: CGFloat = 0) {
		let engine = makeSupplementaryLayoutEngine(for: layoutSection, with: supplementaryItems, spacing: spacing)
		position = engine.layoutWithOrigin(position, layoutSizing: sizing, invalidationContext: invalidationContext)
		supplementaryItems = engine.supplementaryItems
		pinnableHeaders += engine.pinnableHeaders
		nonPinnableHeaders += engine.nonPinnableHeaders
	}
	
	fileprivate func makeSupplementaryLayoutEngine(for layoutSection: GridLayoutSection, with supplementaryItems: [LayoutSupplementaryItem], spacing: CGFloat = 0) -> SupplementaryLayoutEngine {
		if let factory = self.factory {
			return factory(layoutSection, supplementaryItems)
		}
		let engine = GridSectionColumnLayoutEngine(layoutSection: layoutSection, supplementaryItems: supplementaryItems)
		engine.spacing = spacing
		return engine
	}
	
	fileprivate func layoutSectionPlaceholder() {
		guard var placeholderInfo = layoutSection.placeholderInfo, placeholderInfo.startsAt(layoutSection) else {
				return
		}
		layout(&placeholderInfo)
		layoutSection.placeholderInfo = placeholderInfo
	}
	fileprivate func layout(_ placeholderInfo: inout LayoutPlaceholder) {
		updateFrame(of: &placeholderInfo)
		checkEstimatedHeight(of: &placeholderInfo)
		updateOrigin(with: placeholderInfo)
	}
	fileprivate func updateFrame(of placeholderInfo: inout LayoutPlaceholder) {
		placeholderInfo.frame = CGRect(x: innerContentMinX, y: position.y, width: width, height: placeholderInfo.height)
	}
	fileprivate func checkEstimatedHeight(of placeholderInfo: inout LayoutPlaceholder) {
		guard placeholderInfo.hasEstimatedHeight else {
			return
		}
		measureHeight(of: &placeholderInfo)
		updateFrame(of: &placeholderInfo)
	}
	fileprivate func measureHeight(of placeholderInfo: inout LayoutPlaceholder) {
		let measuredSize = layoutMeasure.measuredSizeForPlaceholder(placeholderInfo)
		// We'll add in the shared height in `finalizeLayout`
		placeholderInfo.height = measuredSize.height
		placeholderInfo.hasEstimatedHeight = false
	}
	fileprivate func updateOrigin(with placeholderInfo: LayoutPlaceholder) {
		position.y += placeholderInfo.height
	}
	
	fileprivate func layoutInnerContent() {
		let innerSizing = LayoutSizingInfo(width: innerContentWidth, layoutMeasure: layoutMeasure)
		position = innerLayoutEngine.layoutWithOrigin(position, layoutSizing: innerSizing, invalidationContext: invalidationContext)
		footersMinY = position.y
	}
	fileprivate var innerContentWidth: CGFloat {
		var innerContentWidth = width - leftAuxiliaryColumnWidth - rightAuxiliaryColumnWidth// - metrics.padding.width
		if leftAuxiliaryColumnWidth > 0 {
			innerContentWidth -= metrics.padding.left
		}
		if rightAuxiliaryColumnWidth > 0 {
			innerContentWidth -= metrics.padding.right
		}
		return innerContentWidth
	}
	fileprivate var innerContentOrigin: CGPoint {
		return CGPoint(x: innerContentMinX, y: innerContentMinY)
	}
	fileprivate var innerContentMinX: CGFloat {
		return leftAuxiliaryItemsMaxX
			+ (leftAuxiliaryColumnWidth > 0 ? metrics.padding.left : 0)
	}
	fileprivate var innerContentMinY: CGFloat {
		return headersMaxY + metrics.padding.top
	}
	
}
