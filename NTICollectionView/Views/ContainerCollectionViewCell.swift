//
//  ContainerCollectionViewCell.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 6/17/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

/// A `CollectionViewCell` whose `contentView` contains a single `View` subview pinned to its  `layoutMargins`.
public class ContainerCollectionViewCell<View : UIView, FrameInitializable> : CollectionViewCell {

	/// The single subview of `contentView`.
	///
	/// The `top`, `leading`, `bottom`, and `trailing` attributes of `containedView` are constrained equal to the respective `layoutMargins` of `contentView`.
	public let containedView: View
	
	public override var layoutMargins: UIEdgeInsets {
		didSet {
			contentView.layoutMargins = layoutMargins
		}
	}
	
	public override init(frame: CGRect) {
		containedView = View.init(frame: frame)
		
		super.init(frame: frame)
		
		commonInit()
	}
	
	private func commonInit() {
		containedView.layoutMargins = .zero
		containedView.translatesAutoresizingMaskIntoConstraints = false
		contentView.addSubview(containedView)
		
		let views = ["contained": containedView]
		
		for dimension in ["H", "V"] {
			NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat("\(dimension):|-[contained]-|", options: [], metrics: nil, views: views))
		}
	}

}
