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
	
	func measuredSizeForItem(inout item: LayoutItem) -> CGSize {
		return itemSize
	}
	
	func measuredSizeForPlaceholder(inout placeholderInfo: LayoutPlaceholder) -> CGSize {
		return placeholderSize
	}
	
	func measuredSizeForSupplementaryItem(inout supplementaryItem: LayoutSupplementaryItem) -> CGSize {
		return supplementaryItemSize
	}
	
}
