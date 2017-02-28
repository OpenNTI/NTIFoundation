//
//  ContainerCollectionViewCell.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 6/17/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

/// A `CollectionViewCell` whose `contentView` contains a single `View` subview pinned to its  `layoutMargins`.
open class ContainerCollectionViewCell<View : UIView> : CollectionViewCell where View : FrameInitializable {

	/// The single subview of `contentView`.
	///
	/// The `top`, `leading`, `bottom`, and `trailing` attributes of `containedView` are constrained equal to the respective `layoutMargins` of `contentView`.
	open let containedView: View
	
	open override var layoutMargins: UIEdgeInsets {
		didSet {
			contentView.layoutMargins = layoutMargins
		}
	}
	
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
		contentView.addSubview(containedView)
		
		let views = ["contained": containedView]
		
		for dimension in ["H", "V"] {
			NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "\(dimension):|-[contained]-|", options: [], metrics: nil, views: views))
		}
	}

}
