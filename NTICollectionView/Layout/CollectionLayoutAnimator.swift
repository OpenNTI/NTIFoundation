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
	
	func initialLayoutAttributesForAppearingItemAtIndexPath(itemIndexPath: NSIndexPath) -> UICollectionViewLayoutAttributes?
	
	func finalLayoutAttributesForDisappearingItemAtIndexPath(itemIndexPath: NSIndexPath) -> UICollectionViewLayoutAttributes?
	
	func initialLayoutAttributesForAppearingSupplementaryElementOfKind(elementKind: String, atIndexPath elementIndexPath: NSIndexPath) -> UICollectionViewLayoutAttributes?
	
	func finalLayoutAttributesForDisappearingSupplementaryElementOfKind(elementKind: String, atIndexPath elementIndexPath: NSIndexPath) -> UICollectionViewLayoutAttributes?
	
	func initialLayoutAttributesForAppearingDecorationElementOfKind(elementKind: String, atIndexPath decorationIndexPath: NSIndexPath) -> UICollectionViewLayoutAttributes?
	
	func finalLayoutAttributesForDisappearingDecorationElementOfKind(elementKind: String, atIndexPath decorationIndexPath: NSIndexPath) -> UICollectionViewLayoutAttributes?
	
}


