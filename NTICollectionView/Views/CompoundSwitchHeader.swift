//
//  CompoundSwitchHeader.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 6/2/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

/// A `PinnableHeaderView` with a text label on the left and a text label and a switch on the right.
public class CompoundSwitchHeader: PinnableHeaderView {

	/// The text label displayed on the left side of `self`.
	public let leftLabel = UILabel()
	
	/// The text label displayed on the right side of `self`.
	public let rightLabel = UILabel()
	
	/// The switch displayed on the right side of `self`.
	public let actionSwitch = UISwitch()
	
	public override init(frame: CGRect) {
		super.init(frame: frame)
		
		commonInit()
	}
	
	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	private func commonInit() {
		leftLabel.translatesAutoresizingMaskIntoConstraints = false
		leftLabel.setContentHuggingPriority(UILayoutPriorityRequired, forAxis: .Vertical)
		addSubview(leftLabel)
		
		rightLabel.translatesAutoresizingMaskIntoConstraints = false
		rightLabel.setContentHuggingPriority(UILayoutPriorityRequired, forAxis: .Vertical)
		addSubview(rightLabel)
		
		actionSwitch.translatesAutoresizingMaskIntoConstraints = false
		addSubview(actionSwitch)
		
		let views = ["left": leftLabel, "right": rightLabel, "switch": actionSwitch]
		var constraints = [NSLayoutConstraint]()
		
		constraints += NSLayoutConstraint.constraintsWithVisualFormat("H:|-[left]-(>=0)-[switch]-[right]-|", options: [], metrics: nil, views: views)
		
		for key in ["left", "right"] {
			constraints += NSLayoutConstraint.constraintsWithVisualFormat("V:|-[\(key)]", options: [], metrics: nil, views: views)
		}
		
		constraints.append(NSLayoutConstraint(item: actionSwitch, attribute: .CenterY, relatedBy: .Equal, toItem: rightLabel, attribute: .CenterY, multiplier: 1, constant: 0))
		
		NSLayoutConstraint.activateConstraints(constraints)
	}
	
}
