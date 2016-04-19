//
//  UICollectionView+SupplementaryViews.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 3/3/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public protocol CollectionViewSupplementaryViewTracking: NSObjectProtocol {
	
	func collectionView(collectionView: UICollectionView, visibleViewForSupplementaryElementOfKind kind: String, at indexPath: NSIndexPath) -> UICollectionReusableView?
	
}

extension UICollectionView {
	
	public func _supplementaryViewOfKind(kind: String, at indexPath: NSIndexPath) -> UICollectionReusableView? {
		guard #available(iOS 9.0, *) else {
			return _supplementaryViewForElementKind(kind, at: indexPath)
		}
		return supplementaryViewForElementKind(kind, atIndexPath: indexPath)
	}
	
	public func _supplementaryViewForElementKind(kind: String, at indexPath: NSIndexPath) -> UICollectionReusableView? {
		guard let delegate = self.delegate as? CollectionViewSupplementaryViewTracking else {
			return nil
		}
		return delegate.collectionView(self, visibleViewForSupplementaryElementOfKind: kind, at: indexPath)
	}
	
}
