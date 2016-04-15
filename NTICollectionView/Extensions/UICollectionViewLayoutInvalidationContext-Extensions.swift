//
//  UICollectionViewLayoutInvalidationContext-Extensions.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/25/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

extension UICollectionViewLayoutInvalidationContext {
	
	public func invalidate(supplementaryItem: LayoutSupplementaryItem) {
		invalidateSupplementaryElementsOfKind(supplementaryItem.elementKind, atIndexPaths: [supplementaryItem.indexPath])
	}
	
	public func invalidateSupplementaryElement(with attributes: UICollectionViewLayoutAttributes) {
		invalidateSupplementaryElementsOfKind(attributes.representedElementKind!, atIndexPaths: [attributes.indexPath])
	}
	
	public func invalidateDecorationElement(with attributes: UICollectionViewLayoutAttributes) {
		guard let kind = attributes.representedElementKind else {
			return
		}
		invalidateDecorationElementsOfKind(kind, atIndexPaths: [attributes.indexPath])
	}
	
}