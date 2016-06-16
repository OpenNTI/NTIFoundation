//
//  HeadedTextCell.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 6/1/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

// MARK: - HeadedTextCell

/// A `CollectionViewCell` which displays a `HeadedTextView`.
public class HeadedTextCell: CollectionViewCell {
	
	/// The `HeadedTextView` displayed by `self`.
	public let headedTextView = HeadedTextView()
	
	public override init(frame: CGRect) {
		super.init(frame: frame)
		commonInit()
	}
	
	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	private func commonInit() {
		headedTextView.translatesAutoresizingMaskIntoConstraints = false
		contentView.addSubview(headedTextView)
		
		let views = ["headedText": headedTextView]
		let metrics: [String: NSNumber] = [:]
		
		for dimension in ["H", "V"] {
			NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat("\(dimension):|-[headedText]-|", options: [], metrics: metrics, views: views))
		}
	}

}

// MARK: - HeadedTextView

/// A `UIView` which displays header text above primary text.
public class HeadedTextView : UIView {
	
	/// Displays the header text.
	public let headerLabel = UILabel()
	
	/// Displays the primary text.
	public let textLabel = UILabel()
	
	/// The vertical spacing between the header and the primary text.
	public var spacing: CGFloat = 7 {
		didSet { spacingConstraint.constant = spacing }
	}
	
	private var spacingConstraint: NSLayoutConstraint!
	
	public override init(frame: CGRect) {
		super.init(frame: frame)
		commonInit()
	}
	
	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	private func commonInit() {
		for view in [headerLabel, textLabel] {
			view.translatesAutoresizingMaskIntoConstraints = false
			addSubview(view)
		}
		
		let views = ["header": headerLabel, "text": textLabel]
		let metrics: [String: NSNumber] = [:]
		
		var constraints = [NSLayoutConstraint]()
		
		constraints += NSLayoutConstraint.constraintsWithVisualFormat("V:|-[header]", options: [], metrics: metrics, views: views)
		constraints += NSLayoutConstraint.constraintsWithVisualFormat("V:[text]-|", options: [], metrics: metrics, views: views)
		
		spacingConstraint = NSLayoutConstraint(item: textLabel, attribute: .Top, relatedBy: .Equal, toItem: headerLabel, attribute: .Bottom, multiplier: 1, constant: spacing)
		constraints.append(spacingConstraint)
		
		constraints += NSLayoutConstraint.constraintsWithVisualFormat("H:|-[header]-|", options: [], metrics: metrics, views: views)
		constraints += NSLayoutConstraint.constraintsWithVisualFormat("H:|-[text]-|", options: [], metrics: metrics, views: views)
		
		NSLayoutConstraint.activateConstraints(constraints)
	}
	
		
		constraints.append(NSLayoutConstraint(item: wrapper, attribute: .CenterX, relatedBy: .Equal, toItem: contentView, attribute: .CenterX, multiplier: 1, constant: 0))
		constraints.append(NSLayoutConstraint(item: wrapper, attribute: .CenterY, relatedBy: .Equal, toItem: contentView, attribute: .CenterY, multiplier: 1, constant: 0))
		
		NSLayoutConstraint.activateConstraints(constraints)
	}

}
