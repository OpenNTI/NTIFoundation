//
//  UICollectionViewLayoutInvalidationContext-Extensions.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/25/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

extension UICollectionViewLayoutInvalidationContext {
	
	public func invalidateSupplementaryElement(with attributes: UICollectionViewLayoutAttributes) {
		invalidateSupplementaryElementsOfKind(attributes.representedElementKind!, atIndexPaths: [attributes.indexPath])
	}
	
}