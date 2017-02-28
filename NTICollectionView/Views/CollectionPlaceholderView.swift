//
//  CollectionPlaceholderView.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/25/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

/// A placeholder view for use in a collection view. This placeholder includes a loading indicator.
open class CollectionPlaceholderView: CollectionSupplementaryView {
	
	/// Whether `self` is a section placeholder with special behavior.
	open var isSectionPlaceholder = true
	
	fileprivate var activityIndicatorView: UIActivityIndicatorView!
	fileprivate var placeholderView: PlaceholderView?
	
	open func showActivityIndicator(_ shouldShow: Bool) {
		if activityIndicatorView == nil {
			createActivityIndicatorView()
		}
		
		activityIndicatorView.isHidden = !shouldShow
		
		if shouldShow {
			activityIndicatorView.startAnimating()
		} else {
			activityIndicatorView.stopAnimating()
		}
	}
	
	fileprivate func createActivityIndicatorView() {
		activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
		activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
		activityIndicatorView.color = UIColor.lightGray
		activityIndicatorView.setContentHuggingPriority(UILayoutPriorityFittingSizeLevel, for: .horizontal)
		activityIndicatorView.setContentHuggingPriority(UILayoutPriorityFittingSizeLevel, for: .vertical)
		addSubview(activityIndicatorView)
		
		var constraints: [NSLayoutConstraint] = []
		let views = ["activityIndicatorView": activityIndicatorView]
		constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|[activityIndicatorView]|", options: [], metrics: nil, views: views)
		constraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|[activityIndicatorView]|", options: [], metrics: nil, views: views)
		NSLayoutConstraint.activate(constraints)
	}
	
	open func showPlaceholderWithTitle(_ title: String?, message: String?, image: UIImage?, isAnimated: Bool) {
		let oldPlaceholder = placeholderView
		guard oldPlaceholder == nil || oldPlaceholder?.title != title || oldPlaceholder?.message != message else {
			return
		}
		
		showActivityIndicator(false)
		
		let placeholder = PlaceholderView(frame: CGRect.zero, title: title, message: message, image: image)
		placeholderView = placeholder
		placeholder.alpha = 0
		placeholder.translatesAutoresizingMaskIntoConstraints = false
		addSubview(placeholder)
		
		var constraints: [NSLayoutConstraint] = []
		let views = ["placeholderView": placeholder]
		
		constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|[placeholderView]|", options: [], metrics: nil, views: views)
		constraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|[placeholderView]|", options: [], metrics: nil, views: views)
		
		NSLayoutConstraint.activate(constraints)
		sendSubview(toBack: placeholder)
		
		if isAnimated {
			UIView.animate(withDuration: 0.25, animations: {
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
	
	open func hidePlaceholder(isAnimated: Bool) {
		guard let placeholderView = self.placeholderView else {
			return
		}
		
		if isAnimated {
			UIView.animate(withDuration: 0.25, animations: {
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
	
	open func setTitleFont(_ font: UIFont) {
		placeholderView?.titleFont = font
	}
	
	open func setMessageFont(_ font: UIFont) {
		placeholderView?.messageFont = font
	}
	
	open func setTextColor(_ color: UIColor) {
		placeholderView?.textColor = color
	}
	
	open override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
		guard let attributes = layoutAttributes.copy() as? CollectionViewLayoutAttributes else {
			return layoutAttributes
		}
		
		guard isSectionPlaceholder || attributes.shouldCalculateFittingSize else {
			return attributes
		}
		
		layoutIfNeeded()
		var frame = attributes.frame
		
		let fittingSize = CGSize(width: frame.width, height: UILayoutFittingCompressedSize.height)
		frame.size = systemLayoutSizeFitting(fittingSize, withHorizontalFittingPriority: UILayoutPriorityDefaultHigh, verticalFittingPriority: UILayoutPriorityFittingSizeLevel)
		
		attributes.frame = frame
		return attributes
	}
	
}
