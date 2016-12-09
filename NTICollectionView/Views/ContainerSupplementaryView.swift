//
//  ContainerSupplementaryView.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 6/17/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

/// A `CollectionSupplementaryView` which contains a `View` instance as its single subview.
open class ContainerSupplementaryView<View : UIView> : CollectionSupplementaryView where View : FrameInitializable {

	/// The single subview of `contentView`.
	///
	/// The `top`, `leading`, `bottom`, and `trailing` attributes of `containedView` are constrained equal to the respective `layoutMargins` of `self`.
	open let containedView: View
	
	public override init(frame: CGRect) {
		containedView = View.init(frame: frame)
		
		super.init(frame: frame)
		
		commonInit()
	}

	required public init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
	fileprivate func commonInit() {
		containedView.layoutMargins = .zero
		containedView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(containedView)
		
		let views = ["contained": containedView]
		
		for dimension in ["H", "V"] {
			NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "\(dimension):|-[contained]-|", options: [], metrics: nil, views: views))
		}
	}

}
