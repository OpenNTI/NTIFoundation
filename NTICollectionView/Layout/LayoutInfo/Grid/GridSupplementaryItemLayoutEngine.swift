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
	
	private var origin: CGPoint!
	private var position: CGPoint!
	private var insetOrigin: CGPoint!
	
	private var headerFooterMinX: CGFloat!
	
	private var headersMaxY: CGFloat!
	
	private var footersMinY: CGFloat!
	private var footersMaxY: CGFloat!
	
	private var leftAuxiliaryItemsMaxX: CGFloat {
		return insetOrigin.x + leftAuxiliaryColumnWidth
	}
	private var leftAuxiliaryItemsMaxY: CGFloat!
	
	private var rightAuxiliaryItemsMinX: CGFloat!
	private var rightAuxiliaryItemsMaxY: CGFloat!
	
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
		
		layoutHeaders()
		
		layoutSectionPlaceholder()
		
		layoutLeftAuxiliaryItems()
		
		layoutInnerContent()
		
		layoutRightAuxiliaryItems()
		
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
	
	private func layoutHeaders() {
		headerFooterMinX = position.x
		let headersSizing = LayoutSizingInfo(width: width, layoutMeasure: layoutMeasure)
		layout(layoutSection.headers, using: headersSizing)
		headersMaxY = position.y
	}
	
	private func layoutLeftAuxiliaryItems() {
		position = leftAuxiliaryItemsOrigin
		let sizing = LayoutSizingInfo(width: leftAuxiliaryColumnWidth, layoutMeasure: layoutMeasure)
		layout(layoutSection.leftAuxiliaryItems, using: sizing)
		leftAuxiliaryItemsMaxY = position.y
	}
	private var leftAuxiliaryItemsOrigin: CGPoint {
		return CGPoint(x: origin.x + metrics.contentInset.left, y: headersMaxY)
	}
	
	private func layoutRightAuxiliaryItems() {
		position = rightAuxiliaryItemsOrigin
		let sizing = LayoutSizingInfo(width: rightAuxiliaryColumnWidth, layoutMeasure: layoutMeasure)
		layout(layoutSection.rightAuxiliaryItems, using: sizing)
		rightAuxiliaryItemsMaxY = position.y
	}
	private var rightAuxiliaryItemsOrigin: CGPoint {
		return CGPoint(x: rightAuxiliaryItemsMinX, y: headersMaxY)
	}
	
	private func layoutFooters() {
		position = footersOrigin
		let sizing = LayoutSizingInfo(width: width, layoutMeasure: layoutMeasure)
		layout(layoutSection.footers, using: sizing)
		footersMaxY = position.y
	}
	private var footersOrigin: CGPoint {
		return CGPoint(x: headerFooterMinX, y: footersMinY)
	}
	
	private func layout(supplementaryItems: [LayoutSupplementaryItem], using sizing: LayoutSizing) {
		let engine = makeSupplementaryLayoutEngine(`for`: layoutSection, with: supplementaryItems)
		position = engine.layoutWithOrigin(position, layoutSizing: sizing, invalidationContext: invalidationContext)
		pinnableHeaders += engine.pinnableHeaders
		nonPinnableHeaders += engine.nonPinnableHeaders
	}
	
	private func makeSupplementaryLayoutEngine(`for` layoutSection: GridLayoutSection, with supplementaryItems: [LayoutSupplementaryItem]) -> SupplementaryLayoutEngine {
		if let factory = self.factory {
			return factory(layoutSection: layoutSection, supplementaryItems: supplementaryItems)
		}
		return GridSectionColumnLayoutEngine(layoutSection: layoutSection, supplementaryItems: supplementaryItems)
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
		rightAuxiliaryItemsMinX = position.x + metrics.padding.right
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
