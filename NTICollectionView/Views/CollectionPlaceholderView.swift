//
//  CollectionPlaceholderView.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/25/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

/// A placeholder view for use in a collection view. This placeholder includes a loading indicator.
public class CollectionPlaceholderView: UICollectionReusableView {
	
	private var activityIndicatorView: UIActivityIndicatorView!
	private var placeholderView: PlaceholderView!
	
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
		guard oldPlaceholder == nil || oldPlaceholder.title != title || oldPlaceholder.message != message else {
			return
		}
		
		showActivityIndicator(false)
		
		placeholderView = PlaceholderView(frame: CGRectZero, title: title, message: message, image: image)
		placeholderView.alpha = 0
		placeholderView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(placeholderView)
		
		var constraints: [NSLayoutConstraint] = []
		let views = ["placeholderView": placeholderView]
		
		constraints += NSLayoutConstraint.constraintsWithVisualFormat("H:|[placeholderView]|", options: [], metrics: nil, views: views)
		constraints += NSLayoutConstraint.constraintsWithVisualFormat("V:|[placeholderView]|", options: [], metrics: nil, views: views)
		
		NSLayoutConstraint.activateConstraints(constraints)
		sendSubviewToBack(placeholderView)
		
		if isAnimated {
			UIView.animateWithDuration(0.25, animations: {
				self.placeholderView.alpha = 1
				oldPlaceholder.alpha = 0
				}, completion: { _ in
					oldPlaceholder.removeFromSuperview()
			})
		} else {
			UIView.performWithoutAnimation {
				self.placeholderView.alpha = 1
				oldPlaceholder.alpha = 0
				oldPlaceholder.removeFromSuperview()
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
	
	public override func preferredLayoutAttributesFittingAttributes(layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
		guard let attributes = layoutAttributes.copy() as? CollectionViewLayoutAttributes else {
			return layoutAttributes
		}
		
		layoutSubviews()
		var frame = attributes.frame
		
		let fittingSize = CGSize(width: frame.width, height: UILayoutFittingCompressedSize.height)
		frame.size = systemLayoutSizeFittingSize(fittingSize, withHorizontalFittingPriority: UILayoutPriorityDefaultHigh, verticalFittingPriority: UILayoutPriorityFittingSizeLevel)
		
		attributes.frame = frame
		return attributes
	}
	
}
