//
//  CollectionViewCell.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 3/9/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

open class CollectionViewCell: UICollectionViewCell, Selectable {
	
	/// May be called by `UICollectionViewDelegate` when this cell becomes selected.
	open var onDidSelect: (() -> Void)?
	
	/// May be called by `UICollectionViewDelegate` when this cell becomes deselected.
	open var onDidDeselect: (() -> Void)?
	
	/// May be called by `UICollectionViewDelegate` when this cell will be displayed.
	open var onWillDisplay: (() -> Void)?
	
	/// May be called by `UICollectionViewDelegate` when this cell will end being displayed.
	open var onDidEndDisplaying: (() -> Void)?
	
	open var isEditing = false
	
	/// Informs the containing collection view that `self` needs to be redrawn.
	open func invalidateCollectionViewLayout() {
		NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(CollectionViewCell._invalidateCollectionViewLayout), object: nil)
		perform(#selector(CollectionViewCell._invalidateCollectionViewLayout), with: nil, afterDelay: 0)
	}
	
	func _invalidateCollectionViewLayout() {
		var _collectionView = superview
		while _collectionView != nil && !(_collectionView is UICollectionView) {
			_collectionView = _collectionView?.superview
		}
		guard let collectionView = _collectionView as? UICollectionView,
			let indexPath = collectionView.indexPath(for: self) else {
				return
		}
		
		let layout = collectionView.collectionViewLayout
		
		let contextClass = type(of: layout).invalidationContextClass as! UICollectionViewLayoutInvalidationContext.Type
		let context = contextClass.init()
		(context as? CollectionViewLayoutInvalidationContext)?.invalidateMetrics = true
		context.invalidateItems(at: [indexPath])
		
		layout.invalidateLayout(with: context)
	}
	
	open override func prepareForReuse() {
		super.prepareForReuse()
		isEditing = false
	}
	
	open override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
		super.apply(layoutAttributes)
		isHidden = layoutAttributes.isHidden
		
		guard let attributes = layoutAttributes as? CollectionViewLayoutAttributes else {
			return
		}
		
		layoutMargins = attributes.layoutMargins
		
		backgroundColor = attributes.backgroundColor
		isEditing = attributes.isEditing
		
		contentView.layer.masksToBounds = true
		contentView.layer.cornerRadius = attributes.cornerRadius
	}
	
	open override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
		guard let attributes = layoutAttributes as? CollectionViewLayoutAttributes, attributes.shouldCalculateFittingSize else {
				return layoutAttributes
		}
		
		layoutIfNeeded()
		var frame = attributes.frame
		
		let fittingSize = CGSize(width: frame.width, height: UILayoutFittingCompressedSize.height)
		let layoutSize = systemLayoutSizeFitting(fittingSize, withHorizontalFittingPriority: UILayoutPriorityDefaultHigh, verticalFittingPriority: UILayoutPriorityFittingSizeLevel)
		frame.size = layoutSize
		
		let newAttributes = attributes.copy() as! CollectionViewLayoutAttributes
		newAttributes.frame = frame
		return newAttributes
	}
	
	// MARK: - Selectable
	
	open func didBecomeSelected() {
		onDidSelect?()
	}
	
	open func didBecomeDeselected() {
		onDidDeselect?()
	}
    
}
