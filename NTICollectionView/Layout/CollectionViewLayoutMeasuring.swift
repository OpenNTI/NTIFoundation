//
//  CollectionViewLayoutMeasuring.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/18/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public protocol CollectionViewLayoutMeasuring : class {
	
	func measuredSizeForSupplementaryItem(_ supplementaryItem: LayoutSupplementaryItem) -> CGSize
	
	func measuredSizeForItem(_ item: LayoutItem) -> CGSize
	
	func measuredSizeForPlaceholder(_ placeholderInfo: LayoutPlaceholder) -> CGSize
	
}
