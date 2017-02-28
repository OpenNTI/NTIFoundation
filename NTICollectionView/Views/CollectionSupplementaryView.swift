//
//  CollectionSupplementaryView.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 3/9/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

open class CollectionSupplementaryView: UICollectionReusableView, Selectable {
	
	/// May be called by `UICollectionViewDelegate` when this view becomes selected.
	open var onDidSelect: (() -> Void)?
	
	/// May be called by `UICollectionViewDelegate` when this view becomes deselected.
	open var onDidDeselect: (() -> Void)?
	
	/// May be called by `UICollectionViewDelegate` when this view will be displayed.
	open var onWillDisplay: (() -> Void)?
	
	/// May be called by `UICollectionViewDelegate` when this view will end being displayed.
	open var onWillEndDisplaying: (() -> Void)?
	
	/// Set when tracking a touch in `self`.
	open var isHighlighted: Bool {
		get {
			return _isHighlighted
		}
		set {
			guard newValue != _isHighlighted else {
				return
			}
			_isHighlighted = newValue
			updateDisplayForHighlighting()
		}
	}
	fileprivate var _isHighlighted = false
	
	open func updateDisplayForHighlighting() {
		updateBackgroundColor()
	}
	
	open var isSelected = false {
		didSet {
			guard isSelected != oldValue else {
				return
			}
			updateDisplayForSelection()
		}
	}
	
	open func updateDisplayForSelection() {
		updateBackgroundColor()
	}
	
	var normalBackgroundColor: UIColor?
	var selectedBackgroundColor: UIColor?
	
	var simulatesSelection = false
	
	open override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
		guard let layoutAttributes = layoutAttributes as? CollectionViewLayoutAttributes else {
			return
		}
		
		isHidden = layoutAttributes.isHidden
		isUserInteractionEnabled = !layoutAttributes.isEditing
		
		layoutMargins = layoutAttributes.layoutMargins
		
		normalBackgroundColor = layoutAttributes.backgroundColor
		selectedBackgroundColor = layoutAttributes.selectedBackgroundColor
		simulatesSelection = layoutAttributes.simulatesSelection
		updateBackgroundColor()
		
		layer.masksToBounds = true
		layer.cornerRadius = layoutAttributes.cornerRadius
	}
	
	open func updateBackgroundColor() {
		if (simulatesSelection && _isHighlighted) || isSelected {
			backgroundColor = selectedBackgroundColor
		} else {
			backgroundColor = normalBackgroundColor
		}
	}
	
	open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		isHighlighted = true
	}
	
	open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		isHighlighted = false
	}
	
	open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
		isHighlighted = false
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
		isSelected = true
		onDidSelect?()
	}
	
	open func didBecomeDeselected() {
		isSelected = false
		onDidDeselect?()
	}
        
}
