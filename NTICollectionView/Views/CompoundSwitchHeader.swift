//
//  CompoundSwitchHeader.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 6/2/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

/// A `PinnableHeaderView` with a text label on the left and a text label and a switch on the right.
open class CompoundSwitchHeader: PinnableHeaderView {

	/// The text label displayed on the left side of `self`.
	open let leftLabel = UILabel()
	
	/// The text label displayed on the right side of `self`.
	open let rightLabel = UILabel()
	
	/// The switch displayed on the right side of `self`.
	open let actionSwitch = UISwitch()
	
	public override init(frame: CGRect) {
		super.init(frame: frame)
		
		commonInit()
	}
	
	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	fileprivate func commonInit() {
		clipsToBounds = false
		
		leftLabel.translatesAutoresizingMaskIntoConstraints = false
		leftLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
		addSubview(leftLabel)
		
		rightLabel.translatesAutoresizingMaskIntoConstraints = false
		rightLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
		addSubview(rightLabel)
		
		actionSwitch.translatesAutoresizingMaskIntoConstraints = false
		addSubview(actionSwitch)
		
		let views = ["left": leftLabel, "right": rightLabel, "switch": actionSwitch]
		var constraints = [NSLayoutConstraint]()
		
		constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-[left]-(>=0)-[right]-[switch]-|", options: [], metrics: nil, views: views)
		
		for key in ["left", "right"] {
			constraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|-[\(key)]", options: [], metrics: nil, views: views)
		}
		
		constraints.append(NSLayoutConstraint(item: actionSwitch, attribute: .centerY, relatedBy: .equal, toItem: rightLabel, attribute: .centerY, multiplier: 1, constant: 0))
		
		NSLayoutConstraint.activate(constraints)
	}
}
