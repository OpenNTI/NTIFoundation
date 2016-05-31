//
//  CollectionViewLayoutMeasuring.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/18/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public protocol CollectionViewLayoutMeasuring : class {
	
	func measuredSizeForSupplementaryItem(supplementaryItem: LayoutSupplementaryItem) -> CGSize
	
	func measuredSizeForItem(item: LayoutItem) -> CGSize
	
	func measuredSizeForPlaceholder(placeholderInfo: LayoutPlaceholder) -> CGSize
	
}
