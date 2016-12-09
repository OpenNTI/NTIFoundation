//
//  CollectionLayoutAnimator.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/25/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

/// The purpose of this class will be to encapsulate some of the behavior of `CollectionViewLayout`.
public protocol CollectionLayoutAnimator {
	
	func initialLayoutAttributesForAppearingItemAtIndexPath(_ itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes?
	
	func finalLayoutAttributesForDisappearingItemAtIndexPath(_ itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes?
	
	func initialLayoutAttributesForAppearingSupplementaryElementOfKind(_ elementKind: String, atIndexPath elementIndexPath: IndexPath) -> UICollectionViewLayoutAttributes?
	
	func finalLayoutAttributesForDisappearingSupplementaryElementOfKind(_ elementKind: String, atIndexPath elementIndexPath: IndexPath) -> UICollectionViewLayoutAttributes?
	
	func initialLayoutAttributesForAppearingDecorationElementOfKind(_ elementKind: String, atIndexPath decorationIndexPath: IndexPath) -> UICollectionViewLayoutAttributes?
	
	func finalLayoutAttributesForDisappearingDecorationElementOfKind(_ elementKind: String, atIndexPath decorationIndexPath: IndexPath) -> UICollectionViewLayoutAttributes?
	
}


