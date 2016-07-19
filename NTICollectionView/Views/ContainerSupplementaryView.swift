//
//  ContainerSupplementaryView.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 6/17/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

/// A `CollectionSupplementaryView` which contains a `View` instance as its single subview.
public class ContainerSupplementaryView<View : UIView where View : FrameInitializable> : CollectionSupplementaryView {

	/// The single subview of `contentView`.
	///
	/// The `top`, `leading`, `bottom`, and `trailing` attributes of `containedView` are constrained equal to the respective `layoutMargins` of `self`.
	public let containedView: View
	
	public override init(frame: CGRect) {
		containedView = View.init(frame: frame)
		
		super.init(frame: frame)
		
		commonInit()
	}
	
	private func commonInit() {
		containedView.layoutMargins = .zero
		containedView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(containedView)
		
		let views = ["contained": containedView]
		
		for dimension in ["H", "V"] {
			NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat("\(dimension):|-[contained]-|", options: [], metrics: nil, views: views))
		}
	}

}
