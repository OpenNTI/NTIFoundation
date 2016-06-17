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
	
	public override var layoutMargins: UIEdgeInsets {
		didSet {
			contentView.layoutMargins = layoutMargins
		}
	}
	
	public override init(frame: CGRect) {
		super.init(frame: frame)
		commonInit()
	}
	
	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	private func commonInit() {
		headedTextView.layoutMargins = .zero
		headedTextView.translatesAutoresizingMaskIntoConstraints = false
		contentView.addSubview(headedTextView)
		
		let views = ["headedText": headedTextView]
		let metrics: [String: NSNumber] = [:]
		
		for dimension in ["H", "V"] {
			NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat("\(dimension):|-[headedText]-|", options: [], metrics: metrics, views: views))
		}
	}

}

/// A `CollectionSupplementaryView` which displays a `HeadedTextView`.
public class HeadedTextSupplementaryView : CollectionSupplementaryView {
	
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
		headedTextView.layoutMargins = .zero
		headedTextView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(headedTextView)
		
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
	
}

// MARK: - DupleHeadedTextCell

/// A `CollectionViewCell` which displays two `HeadedTextView`s side-by-side.
public class DupleHeadedTextCell : CollectionViewCell {
	
	/// The first `HeadedTextView` displayed by `self`.
	public let headedTextView1 = HeadedTextView()
	
	/// The second `HeadedTextView` displayed by `self`.
	public let headedTextView2 = HeadedTextView()
	
	/// The horizontal spacing between the `HeadedTextView`s displayed by `self`.
	public var horizontalSpacing: CGFloat = 22 {
		didSet { horizontalSpacingConstraint.constant = horizontalSpacing }
	}
	
	/// The vertical spacing used by the `HeadedTextView`s displayed by `self`.
	public var verticalSpacing: CGFloat = 7 {
		didSet {
			headedTextView1.spacing = verticalSpacing
			headedTextView2.spacing = verticalSpacing
		}
	}
	
	public override var layoutMargins: UIEdgeInsets {
		didSet {
			contentView.layoutMargins = layoutMargins
		}
	}
	
	private var horizontalSpacingConstraint: NSLayoutConstraint!
	
	public override init(frame: CGRect) {
		super.init(frame: frame)
		commonInit()
	}
	
	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	private func commonInit() {
		for view in [headedTextView1, headedTextView2] {
			view.layoutMargins = .zero
			view.translatesAutoresizingMaskIntoConstraints = false
			contentView.addSubview(view)
		}
		
		let views = ["headedText1": headedTextView1, "headedText2": headedTextView2]
		let metrics: [String: NSNumber] = [:]
		
		var constraints = [NSLayoutConstraint]()
		
		constraints += NSLayoutConstraint.constraintsWithVisualFormat("H:|-[headedText1]", options: [], metrics: metrics, views: views)
		constraints += NSLayoutConstraint.constraintsWithVisualFormat("H:[headedText2]-(>=0)-|", options: [], metrics: metrics, views: views)
		
		horizontalSpacingConstraint = NSLayoutConstraint(item: headedTextView2, attribute: .Leading, relatedBy: .Equal, toItem: headedTextView1, attribute: .Trailing, multiplier: 1, constant: horizontalSpacing)
		constraints.append(horizontalSpacingConstraint)
		
		for idx in ["1", "2"] {
			constraints += NSLayoutConstraint.constraintsWithVisualFormat("V:|-[headedText\(idx)]-|", options: [], metrics: metrics, views: views)
		}
		
		NSLayoutConstraint.activateConstraints(constraints)
	}
	
}
