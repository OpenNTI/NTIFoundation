//
//  DummyLayoutMeasure.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/18/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

class DummyLayoutMeasure: NSObject, CollectionViewLayoutMeasuring {
	
	var itemSize = CGSizeZero
	
	var supplementaryItemSize = CGSizeZero
	
	var placeholderSize = CGSizeZero
	
	func measuredSizeForItem(item: LayoutItem) -> CGSize {
		return itemSize
	}
	
	func measuredSizeForPlaceholder(placeholderInfo: LayoutPlaceholder) -> CGSize {
		return placeholderSize
	}
	
	func measuredSizeForSupplementaryItem(supplementaryItem: LayoutSupplementaryItem) -> CGSize {
		return supplementaryItemSize
	}
	
}
