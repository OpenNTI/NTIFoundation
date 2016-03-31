//
//  CollectionSupplementaryView.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 3/9/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public class CollectionSupplementaryView: UICollectionReusableView, Selectable {
	
	/// May be called by `UICollectionViewDelegate` when this view becomes selected.
	public var onDidSelect: (() -> Void)?
	
	/// May be called by `UICollectionViewDelegate` when this view becomes deselected.
	public var onDidDeselect: (() -> Void)?
	
	/// May be called by `UICollectionViewDelegate` when this view will be displayed.
	public var onWillDisplay: (() -> Void)?
	
	/// May be called by `UICollectionViewDelegate` when this view will end being displayed.
	public var onWillEndDisplaying: (() -> Void)?
	
	/// Set when tracking a touch in `self`.
	public var isHighlighted: Bool {
		get {
			return _isHighlighted
		}
		set {
			guard newValue != _isHighlighted else {
				return
			}
			_isHighlighted = newValue
			updateBackgroundColor()
		}
	}
	private var _isHighlighted = false
	
	private var normalBackgroundColor: UIColor?
	private var selectedBackgroundColor: UIColor?
	
	private var simulatesSelection = false
	
	public override func applyLayoutAttributes(layoutAttributes: UICollectionViewLayoutAttributes) {
		guard let layoutAttributes = layoutAttributes as? CollectionViewLayoutAttributes else {
			return
		}
		
		hidden = layoutAttributes.hidden
		userInteractionEnabled = !layoutAttributes.isEditing
		
		layoutMargins = layoutAttributes.layoutMargins
		
		normalBackgroundColor = layoutAttributes.backgroundColor
		selectedBackgroundColor = layoutAttributes.selectedBackgroundColor
		simulatesSelection = layoutAttributes.simulatesSelection
		updateBackgroundColor()
	}
	
	private func updateBackgroundColor() {
		if simulatesSelection && _isHighlighted {
			backgroundColor = selectedBackgroundColor
		} else {
			backgroundColor = normalBackgroundColor
		}
	}
	
	public override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
		isHighlighted = true
	}
	
	public override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
		isHighlighted = false
	}
	
	public override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
		isHighlighted = false
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
	
	// MARK: - Selectable
	
	public func didBecomeSelected() {
		onDidSelect?()
	}
	
	public func didBecomeDeselected() {
		onDidDeselect?()
	}
        
}
