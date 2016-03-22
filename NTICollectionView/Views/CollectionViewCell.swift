//
//  CollectionViewCell.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 3/9/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public class CollectionViewCell: UICollectionViewCell {
	
	public var isEditing = false
	
	/// Informs the containing collection view that `self` needs to be redrawn.
	public func invalidateCollectionViewLayout() {
		NSObject.cancelPreviousPerformRequestsWithTarget(self, selector: #selector(CollectionViewCell._invalidateCollectionViewLayout), object: nil)
		performSelector(#selector(CollectionViewCell._invalidateCollectionViewLayout), withObject: nil, afterDelay: 0)
	}
	
	func _invalidateCollectionViewLayout() {
		var _collectionView = superview
		while _collectionView != nil && !(_collectionView is UICollectionView) {
			_collectionView = _collectionView?.superview
		}
		guard let collectionView = _collectionView as? UICollectionView,
			indexPath = collectionView.indexPathForCell(self) else {
				return
		}
		
		let layout = collectionView.collectionViewLayout
		
		let contextClass = layout.dynamicType.invalidationContextClass() as! UICollectionViewLayoutInvalidationContext.Type
		let context = contextClass.init()
		(context as? CollectionViewLayoutInvalidationContext)?.invalidateMetrics = true
		context.invalidateItemsAtIndexPaths([indexPath])
		
		layout.invalidateLayoutWithContext(context)
	}
	
	public override func prepareForReuse() {
		super.prepareForReuse()
		isEditing = false
	}
	
	public override func applyLayoutAttributes(layoutAttributes: UICollectionViewLayoutAttributes) {
		super.applyLayoutAttributes(layoutAttributes)
		hidden = layoutAttributes.hidden
		
		guard let attributes = layoutAttributes as? CollectionViewLayoutAttributes else {
			return
		}
		
		layoutMargins = attributes.layoutMargins
		
		backgroundColor = attributes.backgroundColor
		isEditing = attributes.isEditing
	}
	
	public override func preferredLayoutAttributesFittingAttributes(layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
		guard let attributes = layoutAttributes as? CollectionViewLayoutAttributes
			where attributes.shouldCalculateFittingSize else {
				return layoutAttributes
		}
		
		layoutIfNeeded()
		var frame = attributes.frame
		
		let fittingSize = CGSize(width: frame.width, height: UILayoutFittingCompressedSize.height)
		let layoutSize = systemLayoutSizeFittingSize(fittingSize, withHorizontalFittingPriority: UILayoutPriorityDefaultHigh, verticalFittingPriority: UILayoutPriorityFittingSizeLevel)
		frame.size = layoutSize
		
		let newAttributes = attributes.copy() as! CollectionViewLayoutAttributes
		newAttributes.frame = frame
		return newAttributes
	}
    
}
