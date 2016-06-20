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
			let layoutItem = makeLayoutItem(for: supplementaryItem, atIndex: index, using: description, in: positionBounds)
			
			layoutItems.append(layoutItem)
			
			guard shouldDisplay(layoutItem) else {
				continue
			}
			
			positionBounds.origin.y += layoutItem.fixedHeight
			
			if index < supplementaryItems.count - 1 {
				positionBounds.origin.y += metrics.spacing
			}
		}
		
		return layoutItems
	}
	
	func makeLayoutItem(for supplementaryItem: SupplementaryItem, atIndex index: Int, using description: SectionDescription, in layoutBounds: LayoutAreaBounds) -> LayoutItemType {
		
		var layoutItem = LayoutItemType(supplementaryItem: supplementaryItem)
		
		guard shouldDisplay(supplementaryItem, using: description) else {
			layoutItem.isHidden = true
			return layoutItem
		}
		
		layoutItem.itemIndex = index
		layoutItem.sectionIndex = description.sectionIndex
		
		layoutItem.applyValues(from: description.metrics)
		
		let origin = layoutBounds.origin
		var height = supplementaryItem.fixedHeight
		
		layoutItem.frame = CGRect(x: origin.x, y: origin.y, width: layoutBounds.width, height: height)
		
		if supplementaryItem.hasEstimatedHeight, let sizing = description.sizingInfo {
			let measuredSize = sizing.measuredSizeForSupplementaryItem(layoutItem)
			height = measuredSize.height
			layoutItem.height = height
			layoutItem.frame.size.height = height
		}
		
		return layoutItem
	}
	
	func shouldDisplay(supplementaryItem: SupplementaryItem, using description: SectionDescription) -> Bool {
		return (description.numberOfItems > 0
			|| supplementaryItem.isVisibleWhileShowingPlaceholder)
			&& supplementaryItem.fixedHeight > 0
			&& !supplementaryItem.isHidden
	}
	
	func shouldDisplay(layoutItem: LayoutSupplementaryItem) -> Bool {
		return !layoutItem.isHidden
			&& layoutItem.fixedHeight > 0
	}
	
}

public struct LayoutItemStackMetrics : Equatable {
	
	static let zero = LayoutItemStackMetrics()
	
	var spacing: CGFloat = 0
	
}

public func ==(lhs: LayoutItemStackMetrics, rhs: LayoutItemStackMetrics) -> Bool {
	return lhs.spacing == rhs.spacing
}
