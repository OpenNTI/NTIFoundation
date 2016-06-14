//
//  SupplementaryItemStackBuilder.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 6/14/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public struct SupplementaryItemStackBuilder<LayoutItemType : LayoutSupplementaryItem> {
	
	func makeLayoutItems(for supplementaryItems: [SupplementaryItem], using description: SectionDescription, in layoutBounds: LayoutAreaBounds, metrics: LayoutItemStackMetrics = .zero) -> [LayoutItemType] {
		var layoutItems = [LayoutItemType]()
		
		var positionBounds = layoutBounds
		
		for (index, supplementaryItem) in supplementaryItems.enumerate() {
			guard let layoutItem = makeLayoutItem(for: supplementaryItem, atIndex: index, using: description, in: positionBounds) else {
				continue
			}
			
			positionBounds.origin.y += layoutItem.fixedHeight
			
			if index < supplementaryItems.count - 1 {
				positionBounds.origin.y += metrics.spacing
			}
			
			layoutItems.append(layoutItem)
		}
		
		return layoutItems
	}
	
	func makeLayoutItem(for supplementaryItem: SupplementaryItem, atIndex index: Int, using description: SectionDescription, in layoutBounds: LayoutAreaBounds) -> LayoutItemType? {
		guard description.numberOfItems > 0 || supplementaryItem.isVisibleWhileShowingPlaceholder else {
			return nil
		}
		
		var height = supplementaryItem.fixedHeight
		
		guard height > 0 && !supplementaryItem.isHidden else {
			return nil
		}
		
		var layoutItem = LayoutItemType.init(supplementaryItem: supplementaryItem)
		
		layoutItem.itemIndex = index
		layoutItem.sectionIndex = description.sectionIndex
		
		layoutItem.applyValues(from: description.metrics)
		
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

public struct LayoutItemStackMetrics : Equatable {
	
	static let zero = LayoutItemStackMetrics()
	
	var spacing: CGFloat = 0
	
}

public func ==(lhs: LayoutItemStackMetrics, rhs: LayoutItemStackMetrics) -> Bool {
	return lhs.spacing == rhs.spacing
}
