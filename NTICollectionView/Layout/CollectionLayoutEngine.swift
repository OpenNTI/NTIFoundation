//
//  CollectionLayoutEngine.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/25/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public protocol CollectionLayout: NSObjectProtocol {
	
	func layoutAttributesForElementsInRect(_ rect: CGRect) -> [UICollectionViewLayoutAttributes]?
	
	func layoutAttributesForItemAtIndexPath(_ indexPath: IndexPath) -> UICollectionViewLayoutAttributes?
	
	func layoutAttributesForSupplementaryViewOfKind(_ elementKind: String, atIndexPath indexPath: IndexPath) -> UICollectionViewLayoutAttributes?
	
	func layoutAttributesForDecorationViewOfKind(_ elementKind: String, atIndexPath indexPath: IndexPath) -> UICollectionViewLayoutAttributes?
	
}

/// The purpose of this class will be to encapsulate some of the behavior of `CollectionViewLayout`.
open class CollectionLayoutEngine: NSObject {
	
}
