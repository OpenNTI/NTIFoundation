//
//  CollectionViewLayoutMeasuring.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/18/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public protocol CollectionViewLayoutMeasuring: NSObjectProtocol {
	
	func measuredSizeForSupplementaryItem(inout supplementaryItem: LayoutSupplementaryItem) -> CGSize
	
	func measuredSizeForItem(inout item: LayoutItem) -> CGSize
	
	func measuredSizeForPlaceholder(inout placeholderInfo: LayoutPlaceholder) -> CGSize
	
}
