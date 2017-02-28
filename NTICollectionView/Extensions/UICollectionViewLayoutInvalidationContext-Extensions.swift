//
//  UICollectionViewLayoutInvalidationContext-Extensions.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/25/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

extension UICollectionViewLayoutInvalidationContext {
	
	public func invalidate(_ supplementaryItem: LayoutSupplementaryItem) {
		invalidateSupplementaryElements(ofKind: supplementaryItem.elementKind, at: [supplementaryItem.indexPath as IndexPath])
	}
	
	public func invalidateSupplementaryElement(with attributes: UICollectionViewLayoutAttributes) {
		invalidateSupplementaryElements(ofKind: attributes.representedElementKind!, at: [attributes.indexPath])
	}
	
	public func invalidateDecorationElement(with attributes: UICollectionViewLayoutAttributes) {
		guard let kind = attributes.representedElementKind else {
			return
		}
		invalidateDecorationElements(ofKind: kind, at: [attributes.indexPath])
	}
	
}
