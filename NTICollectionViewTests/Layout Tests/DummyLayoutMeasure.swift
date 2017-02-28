//
//  DummyLayoutMeasure.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/18/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

class DummyLayoutMeasure: NSObject, CollectionViewLayoutMeasuring {
	
	var itemSize = CGSize.zero
	
	var supplementaryItemSize = CGSize.zero
	
	var placeholderSize = CGSize.zero
	
	func measuredSizeForItem(_ item: LayoutItem) -> CGSize {
		return itemSize
	}
	
	func measuredSizeForPlaceholder(_ placeholderInfo: LayoutPlaceholder) -> CGSize {
		return placeholderSize
	}
	
	func measuredSizeForSupplementaryItem(_ supplementaryItem: LayoutSupplementaryItem) -> CGSize {
		return supplementaryItemSize
	}
	
}
