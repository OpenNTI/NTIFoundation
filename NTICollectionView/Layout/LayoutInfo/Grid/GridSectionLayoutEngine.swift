//
//  GridSectionLayoutHelper.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/19/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public class GridSectionLayoutEngine: NSObject {
	
	public init(layoutSection: GridLayoutSection) {
		self.layoutSection = layoutSection
		super.init()
	}
	
	public weak var layoutSection: GridLayoutSection!
	
	public var pinnableHeaders: [LayoutSupplementaryItem] = []
	public var nonPinnableHeaders: [LayoutSupplementaryItem] = []
	
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
//	private var height: CGFloat = 0
	
	
	var layoutInfo: LayoutInfo!
	var layoutMeasure: CollectionViewLayoutMeasuring!
	var invalidationContext: UICollectionViewLayoutInvalidationContext?
	
	private var width: CGFloat! {
		return layoutInfo.width
	}
	
	private var leftAuxiliaryColumnWidth: CGFloat {
		return layoutSection.leftAuxiliaryColumnWidth
	}
	
	private var rightAuxiliaryColumnWidth: CGFloat {
		return layoutSection.rightAuxiliaryColumnWidth
	}
	
	public func layoutWithOrigin(start: CGPoint, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) -> CGPoint {
		guard let layoutInfo = layoutSection.layoutInfo,
			layoutMeasure = layoutInfo.layoutMeasure else {
				return CGPointZero
		}
		self.layoutInfo = layoutInfo
		self.layoutMeasure = layoutMeasure
		self.invalidationContext = invalidationContext
		
		reset()
		origin.y = start.y
		
		layoutHeaders()
		
		layoutLeftAuxiliaryItems()
		layoutRightAuxiliaryItems()
		
		layoutSectionPlaceholder()
		
		layoutRows()
		
		layoutFooters()
		
		layoutSection.frame = CGRect(x: 0, y: start.y, width: width, height: origin.y - start.y)
		
		return origin
	}
	
	private func reset() {
		origin = CGPoint(x: margins.left, y: 0)
		pinnableHeaders = []
		nonPinnableHeaders = []
		layoutSection.removeAllRows()
	}
	
	private func layoutHeaders() {
		for header in layoutSection.headers {
			layoutSupplementaryView(header)
		}
	}
	
	private func layoutLeftAuxiliaryItems() {
		for auxiliaryItem in layoutSection.leftAuxiliaryItems {
			
		}
	}
	
	private func layoutRightAuxiliaryItems() {
		for auxiliaryItem in layoutSection.rightAuxiliaryItems {
			
		}
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
		placeholderInfo.frame = CGRect(x: 0, y: origin.y, width: width, height: placeholderInfo.height)
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
		origin.y += placeholderInfo.height
	}
	
	private func layoutRows() {
		let cellLayoutEngine = GridSectionCellLayoutEngine(layoutSection: layoutSection)
		let newPosition = cellLayoutEngine.layoutWithOrigin(origin, invalidationContext: invalidationContext)
		origin.y = newPosition.y
	}
	
	private func layoutSupplementaryView(supplementaryItem: LayoutSupplementaryItem) {
		guard shouldLayout(supplementaryItem) else {
			return
		}
		updateFrame(of: supplementaryItem)
		checkEstimatedHeight(of: supplementaryItem)
		updateOrigin(with: supplementaryItem)
		checkPinning(of: supplementaryItem)
		invalidate(supplementaryItem)
	}
	
	private func shouldLayout(supplementaryItem: SupplementaryItem) -> Bool {
		return (numberOfItems > 0 || supplementaryItem.isVisibleWhileShowingPlaceholder)
			&& !supplementaryItem.isHidden
			&& supplementaryItem.fixedHeight > 0
	}
	
	private func updateFrame(of supplementaryItem: LayoutSupplementaryItem) {
		let height = supplementaryItem.fixedHeight
		supplementaryItem.frame = CGRect(x: origin.x, y: origin.y, width: width, height: height)
	}
	
	private func checkEstimatedHeight(of supplementaryItem: LayoutSupplementaryItem) {
		if supplementaryItem.hasEstimatedHeight {
			measureHeight(of: supplementaryItem)
		}
	}
	
	private func measureHeight(of supplementaryItem: LayoutSupplementaryItem) {
		let measuredSize = layoutMeasure.measuredSizeForSupplementaryItem(supplementaryItem)
		supplementaryItem.height = measuredSize.height
		updateFrame(of: supplementaryItem)
	}
	
	private func updateOrigin(with supplementaryItem: LayoutSupplementaryItem) {
		origin.y += supplementaryItem.fixedHeight
	}
	
	private func checkPinning(of supplementaryItem: LayoutSupplementaryItem) {
		guard let gridItem = supplementaryItem as? GridSupplementaryItem
			where supplementaryItem.isHeader else {
				return
		}
		updatePinning(of: gridItem)
	}
	
	private func updatePinning(of gridItem: GridSupplementaryItem) {
		if gridItem.shouldPin {
			pinnableHeaders.append(gridItem)
		} else {
			nonPinnableHeaders.append(gridItem)
		}
	}
	
	private func invalidate(supplementaryItem: LayoutSupplementaryItem) {
		invalidationContext?.invalidateSupplementaryElementsOfKind(supplementaryItem.elementKind, atIndexPaths: [supplementaryItem.indexPath])
	}
	
	private func layoutFooters() {
		for footer in layoutSection.footers {
			layoutSupplementaryView(footer)
		}
	}
	
}
