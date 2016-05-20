//
//  CollectionPlaceholderView.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/25/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

/// A placeholder view for use in a collection view. This placeholder includes a loading indicator.
public class CollectionPlaceholderView: CollectionSupplementaryView {
	
	/// Whether `self` is a section placeholder with special behavior.
	public var isSectionPlaceholder = true
	
	private var activityIndicatorView: UIActivityIndicatorView!
	private var placeholderView: PlaceholderView?
	
	public func showActivityIndicator(shouldShow: Bool) {
		if activityIndicatorView == nil {
			createActivityIndicatorView()
		}
		
		activityIndicatorView.hidden = !shouldShow
		
		if shouldShow {
			activityIndicatorView.startAnimating()
		} else {
			activityIndicatorView.stopAnimating()
		}
	}
	
	private func createActivityIndicatorView() {
		activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
		activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
		activityIndicatorView.color = UIColor.lightGrayColor()
		activityIndicatorView.setContentHuggingPriority(UILayoutPriorityFittingSizeLevel, forAxis: .Horizontal)
		activityIndicatorView.setContentHuggingPriority(UILayoutPriorityFittingSizeLevel, forAxis: .Vertical)
		addSubview(activityIndicatorView)
		
		var constraints: [NSLayoutConstraint] = []
		let views = ["activityIndicatorView": activityIndicatorView]
		constraints += NSLayoutConstraint.constraintsWithVisualFormat("H:|[activityIndicatorView]|", options: [], metrics: nil, views: views)
		constraints += NSLayoutConstraint.constraintsWithVisualFormat("V:|[activityIndicatorView]|", options: [], metrics: nil, views: views)
		NSLayoutConstraint.activateConstraints(constraints)
	}
	
	public func showPlaceholderWithTitle(title: String?, message: String?, image: UIImage?, isAnimated: Bool) {
		let oldPlaceholder = placeholderView
		guard oldPlaceholder == nil || oldPlaceholder?.title != title || oldPlaceholder?.message != message else {
			return
		}
		
		showActivityIndicator(false)
		
		let placeholder = PlaceholderView(frame: CGRectZero, title: title, message: message, image: image)
		placeholderView = placeholder
		placeholder.alpha = 0
		placeholder.translatesAutoresizingMaskIntoConstraints = false
		addSubview(placeholder)
		
		var constraints: [NSLayoutConstraint] = []
		let views = ["placeholderView": placeholder]
		
		constraints += NSLayoutConstraint.constraintsWithVisualFormat("H:|[placeholderView]|", options: [], metrics: nil, views: views)
		constraints += NSLayoutConstraint.constraintsWithVisualFormat("V:|[placeholderView]|", options: [], metrics: nil, views: views)
		
		NSLayoutConstraint.activateConstraints(constraints)
		sendSubviewToBack(placeholder)
		
		if isAnimated {
			UIView.animateWithDuration(0.25, animations: {
				placeholder.alpha = 1
				oldPlaceholder?.alpha = 0
				}, completion: { _ in
					oldPlaceholder?.removeFromSuperview()
			})
		} else {
			UIView.performWithoutAnimation {
				placeholder.alpha = 1
				oldPlaceholder?.alpha = 0
				oldPlaceholder?.removeFromSuperview()
			}
		}
	}
	
	public func hidePlaceholder(isAnimated isAnimated: Bool) {
		guard let placeholderView = self.placeholderView else {
			return
		}
		
		if isAnimated {
			UIView.animateWithDuration(0.25, animations: {
				placeholderView.alpha = 0
				}, completion: { _ in
					placeholderView.removeFromSuperview()
					if placeholderView === self.placeholderView {
						self.placeholderView = nil
					}
			})
		} else {
			UIView.performWithoutAnimation {
				placeholderView.removeFromSuperview()
				if placeholderView === self.placeholderView {
					self.placeholderView = nil
				}
			}
		}
	}
	
	public func setTitleFont(font: UIFont) {
		placeholderView?.titleFont = font
	}
	
	public func setMessageFont(font: UIFont) {
		placeholderView?.messageFont = font
	}
	
	public func setTextColor(color: UIColor) {
		placeholderView?.textColor = color
	}
	
	public override func preferredLayoutAttributesFittingAttributes(layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
		guard let attributes = layoutAttributes.copy() as? CollectionViewLayoutAttributes else {
			return layoutAttributes
		}
		
		guard isSectionPlaceholder || attributes.shouldCalculateFittingSize else {
			return attributes
		}
		
		layoutIfNeeded()
		var frame = attributes.frame
		
		let fittingSize = CGSize(width: frame.width, height: UILayoutFittingCompressedSize.height)
		frame.size = systemLayoutSizeFittingSize(fittingSize, withHorizontalFittingPriority: UILayoutPriorityDefaultHigh, verticalFittingPriority: UILayoutPriorityFittingSizeLevel)
		
		attributes.frame = frame
		return attributes
	}
	
}
