//
//  GridSupplementaryItemLayoutEngine.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 3/10/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public class GridSupplementaryItemLayoutEngine: NSObject, LayoutEngine {

	public init(layoutSection: GridLayoutSection, innerLayoutEngine: LayoutEngine) {
		self.layoutSection = layoutSection
		self.innerLayoutEngine = innerLayoutEngine
		super.init()
	}
	
	public weak var layoutSection: GridLayoutSection!
	public weak var innerLayoutEngine: LayoutEngine!
	
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
		
		layoutLeftAuxiliaryItems()
		
		layoutInnerContent()
		
		layoutRightAuxiliaryItems()
		
		layoutFooters()
		
		position.x = layoutSizing.width
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
		let sizing = LayoutSizingInfo(width: leftAuxiliaryColumnWidth, layoutMeasure: layoutMeasure)
		layout(layoutSection.leftAuxiliaryItems, using: sizing)
		leftAuxiliaryItemsMaxY = position.y
	}
	
	private func layoutRightAuxiliaryItems() {
		position.x = rightAuxiliaryItemsMinX
		position.y = headersMaxY
		let sizing = LayoutSizingInfo(width: rightAuxiliaryColumnWidth, layoutMeasure: layoutMeasure)
		layout(layoutSection.rightAuxiliaryItems, using: sizing)
		rightAuxiliaryItemsMaxY = position.y
	}
	
	private func layoutFooters() {
		position.x = headerFooterMinX
		position.y = footersMinY
		let sizing = LayoutSizingInfo(width: width, layoutMeasure: layoutMeasure)
		layout(layoutSection.footers, using: sizing)
		footersMaxY = position.y
	}
	
	private func layout(supplementaryItems: [LayoutSupplementaryItem], using sizing: LayoutSizing) {
		let engine = GridSectionColumnLayoutEngine(layoutSection: layoutSection, supplementaryItems: supplementaryItems)
		position = engine.layoutWithOrigin(position, layoutSizing: sizing, invalidationContext: invalidationContext)
		pinnableHeaders += engine.pinnableHeaders
		nonPinnableHeaders += engine.nonPinnableHeaders
	}
	
	private func layoutInnerContent() {
		let innerWidth = width - leftAuxiliaryColumnWidth - rightAuxiliaryColumnWidth
		let innerSizing = LayoutSizingInfo(width: innerWidth, layoutMeasure: layoutMeasure)
		let innerStartPoint = CGPoint(x: leftAuxiliaryItemsMaxX, y: headersMaxY)
		let innerEndPoint = innerLayoutEngine.layoutWithOrigin(innerStartPoint, layoutSizing: innerSizing, invalidationContext: invalidationContext)
		rightAuxiliaryItemsMinX = innerEndPoint.x
		footersMinY = innerEndPoint.y
	}
	
}
