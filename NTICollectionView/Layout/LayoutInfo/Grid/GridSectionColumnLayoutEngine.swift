//
//  GridSectionColumnLayoutEngine.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/26/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public class GridSectionColumnLayoutEngine: NSObject, SupplementaryLayoutEngine {

	public init(layoutSection: GridLayoutSection, supplementaryItems: [LayoutSupplementaryItem]) {
		self.layoutSection = layoutSection
		self.supplementaryItems = supplementaryItems
		super.init()
	}
	
	public weak var layoutSection: GridLayoutSection!
	private var numberOfItems: Int {
		return layoutSection.items.count
	}
	public var supplementaryItems: [LayoutSupplementaryItem]
	
	public var pinnableHeaders: [LayoutSupplementaryItem] = []
	public var nonPinnableHeaders: [LayoutSupplementaryItem] = []
	
	private var metrics: GridSectionMetrics {
		return layoutSection.metrics
	}
	
	var origin: CGPoint!
	var position: CGPoint!
	
	var layoutSizing: LayoutSizing!
	var layoutMeasure: CollectionViewLayoutMeasuring!
	var invalidationContext: UICollectionViewLayoutInvalidationContext?
	
	private var width: CGFloat! {
		return layoutSizing.width
	}
	private var leftAuxiliaryColumnWidth: CGFloat {
		return layoutSection.leftAuxiliaryColumnWidth
	}
	private var rightAuxiliaryColumnWidth: CGFloat {
		return layoutSection.rightAuxiliaryColumnWidth
	}
	
	public func layoutWithOrigin(start: CGPoint, layoutSizing: LayoutSizing, invalidationContext: UICollectionViewLayoutInvalidationContext?) -> CGPoint {
		guard let layoutMeasure = layoutSizing.layoutMeasure else {
			return CGPointZero
		}
		self.layoutSizing = layoutSizing
		self.layoutMeasure = layoutMeasure
		self.invalidationContext = invalidationContext
		
		reset()
		origin = start
		position = start
		
		layoutSupplementaryItems()
		
		return position
	}
	
	private func reset() {
		position = CGPoint(x: 0, y: 0)
		pinnableHeaders = []
		nonPinnableHeaders = []
	}
	
	private func layoutSupplementaryItems() {
		for supplementaryItem in supplementaryItems {
			layoutSupplementaryView(supplementaryItem)
		}
	}
	
	private func layoutSupplementaryView(supplementaryItem: LayoutSupplementaryItem) {
		guard shouldLayout(supplementaryItem) else {
			return
		}
		updateFrame(of: supplementaryItem)
		checkEstimatedHeight(of: supplementaryItem)
		updatePosition(with: supplementaryItem)
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
		supplementaryItem.frame = CGRect(x: position.x, y: position.y, width: width, height: height)
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
	
	private func updatePosition(with supplementaryItem: LayoutSupplementaryItem) {
		position.y += supplementaryItem.fixedHeight
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
	
}
