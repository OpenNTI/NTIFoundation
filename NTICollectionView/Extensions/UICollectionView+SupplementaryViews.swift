//
//  UICollectionView+SupplementaryViews.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 3/3/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public protocol CollectionViewSupplementaryViewTracking: NSObjectProtocol {
	
	func collectionView(_ collectionView: UICollectionView, visibleViewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView?
	
}

extension UICollectionView {
	
	public func register(_ item: SupplementaryItem) {
		self.register(item.supplementaryViewClass, forSupplementaryViewOfKind: item.elementKind, withReuseIdentifier: item.reuseIdentifier)
	}
	
	public func _supplementaryViewOfKind(_ kind: String, at indexPath: IndexPath) -> UICollectionReusableView? {
		guard #available(iOS 9.0, *) else {
			return _supplementaryViewForElementKind(kind, at: indexPath)
		}
		return supplementaryView(forElementKind: kind, at: indexPath)
	}
	
	public func _supplementaryViewForElementKind(_ kind: String, at indexPath: IndexPath) -> UICollectionReusableView? {
		guard let delegate = self.delegate as? CollectionViewSupplementaryViewTracking else {
			return nil
		}
		return delegate.collectionView(self, visibleViewForSupplementaryElementOfKind: kind, at: indexPath)
	}
	
}
