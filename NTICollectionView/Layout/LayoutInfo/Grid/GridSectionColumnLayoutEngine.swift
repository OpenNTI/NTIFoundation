//
//  GridSectionColumnLayoutEngine.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/26/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

open class GridSectionColumnLayoutEngine: NSObject, SupplementaryLayoutEngine {

	public init(layoutSection: GridLayoutSection, supplementaryItems: [LayoutSupplementaryItem]) {
		self.layoutSection = layoutSection
		self.supplementaryItems = supplementaryItems
		super.init()
	}
	
	open var layoutSection: GridLayoutSection
	fileprivate var numberOfItems: Int {
		return layoutSection.items.count
	}
	open var supplementaryItems: [LayoutSupplementaryItem]
	
	open var pinnableHeaders: [LayoutSupplementaryItem] = []
	open var nonPinnableHeaders: [LayoutSupplementaryItem] = []
	
	open var spacing: CGFloat = 0
	
	fileprivate var metrics: GridSectionMetricsProviding {
		return layoutSection.metrics
	}
	
	var origin: CGPoint!
	var position: CGPoint!
	
	var layoutSizing: LayoutSizing!
	var layoutMeasure: CollectionViewLayoutMeasuring!
	var invalidationContext: UICollectionViewLayoutInvalidationContext?
	
	fileprivate var width: CGFloat! {
		return layoutSizing.width
	}
	fileprivate var leftAuxiliaryColumnWidth: CGFloat {
		return layoutSection.leftAuxiliaryColumnWidth
	}
	fileprivate var rightAuxiliaryColumnWidth: CGFloat {
		return layoutSection.rightAuxiliaryColumnWidth
	}
	
	open func layoutWithOrigin(_ start: CGPoint, layoutSizing: LayoutSizing, invalidationContext: UICollectionViewLayoutInvalidationContext?) -> CGPoint {
		guard let layoutMeasure = layoutSizing.layoutMeasure else {
			return CGPoint.zero
		}
		self.layoutSizing = layoutSizing
		self.layoutMeasure = layoutMeasure
		self.invalidationContext = invalidationContext
		
		reset()
		origin = start
		position = start
		
		layoutSupplementaryItems()
		
		position.x = origin.x + width
		
		return position
	}
	
	fileprivate func reset() {
		position = CGPoint(x: 0, y: 0)
		pinnableHeaders = []
		nonPinnableHeaders = []
	}
	
	fileprivate func layoutSupplementaryItems() {
		for index in supplementaryItems.indices {
			layoutSupplementaryView(&supplementaryItems[index])
		}
	}
	
	fileprivate func layoutSupplementaryView(_ supplementaryItem: inout LayoutSupplementaryItem) {
		guard shouldLayout(supplementaryItem) else {
			return
		}
		updateFrame(of: &supplementaryItem)
		checkEstimatedHeight(of: &supplementaryItem)
		updatePosition(with: supplementaryItem)
		checkPinning(of: &supplementaryItem)
		invalidate(supplementaryItem)
	}
	
	fileprivate func shouldLayout(_ supplementaryItem: SupplementaryItem) -> Bool {
		return layoutSection.shouldShow(supplementaryItem)
			&& !supplementaryItem.isHidden
			&& supplementaryItem.fixedHeight > 0
	}
	
	fileprivate func updateFrame(of supplementaryItem: inout LayoutSupplementaryItem) {
		let height = supplementaryItem.fixedHeight
		supplementaryItem.frame = CGRect(x: position.x, y: position.y, width: width, height: height)
	}
	
	fileprivate func checkEstimatedHeight(of supplementaryItem: inout LayoutSupplementaryItem) {
		if supplementaryItem.hasEstimatedHeight {
			measureHeight(of: &supplementaryItem)
		}
	}
	
	fileprivate func measureHeight(of supplementaryItem: inout LayoutSupplementaryItem) {
		let measuredSize = layoutMeasure.measuredSizeForSupplementaryItem(supplementaryItem)
		supplementaryItem.height = measuredSize.height
		updateFrame(of: &supplementaryItem)
	}
	
	fileprivate func updatePosition(with supplementaryItem: LayoutSupplementaryItem) {
		position.y += supplementaryItem.fixedHeight
		
		// FIXME: This logic is kind of jank
		if !supplementaryItem.isEqual(to: supplementaryItems.last!) {
			position.y += spacing
		}
	}
	
	fileprivate func checkPinning(of supplementaryItem: inout LayoutSupplementaryItem) {
		guard var gridItem = supplementaryItem as? GridLayoutSupplementaryItem, supplementaryItem.isHeader else {
				return
		}
		
		gridItem.unpinnedY = gridItem.frame.minY
		supplementaryItem = gridItem
		
		if gridItem.shouldPin {
			pinnableHeaders.append(gridItem)
		} else {
			nonPinnableHeaders.append(gridItem)
		}
	}
	
	fileprivate func invalidate(_ supplementaryItem: LayoutSupplementaryItem) {
		invalidationContext?.invalidateSupplementaryElements(ofKind: supplementaryItem.elementKind, at: [supplementaryItem.indexPath as IndexPath])
	}
	
}
