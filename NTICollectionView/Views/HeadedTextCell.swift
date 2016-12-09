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
open class HeadedTextCell: CollectionViewCell {
	
	/// The `HeadedTextView` displayed by `self`.
	open let headedTextView = HeadedTextView()
	
	open override var layoutMargins: UIEdgeInsets {
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
	
	fileprivate func commonInit() {
		headedTextView.layoutMargins = .zero
		headedTextView.translatesAutoresizingMaskIntoConstraints = false
		contentView.addSubview(headedTextView)
		
		let views = ["headedText": headedTextView]
		let metrics: [String: NSNumber] = [:]
		
		for dimension in ["H", "V"] {
			NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "\(dimension):|-[headedText]-|", options: [], metrics: metrics, views: views))
		}
	}

}

/// A `CollectionSupplementaryView` which displays a `HeadedTextView`.
open class HeadedTextSupplementaryView : CollectionSupplementaryView {
	
	/// The `HeadedTextView` displayed by `self`.
	open let headedTextView = HeadedTextView()
	
	public override init(frame: CGRect) {
		super.init(frame: frame)
		commonInit()
	}
	
	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	fileprivate func commonInit() {
		headedTextView.layoutMargins = .zero
		headedTextView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(headedTextView)
		
		let views = ["headedText": headedTextView]
		let metrics: [String: NSNumber] = [:]
		
		for dimension in ["H", "V"] {
			NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "\(dimension):|-[headedText]-|", options: [], metrics: metrics, views: views))
		}
	}
	
}

// MARK: - HeadedTextView

/// A `UIView` which displays header text above primary text.
open class HeadedTextView : UIView, FrameInitializable {
	
	/// Displays the header text.
	open let headerLabel = UILabel()
	
	/// Displays the primary text.
	open let textLabel = UILabel()
	
	/// The vertical spacing between the header and the primary text.
	open var spacing: CGFloat = 7 {
		didSet { spacingConstraint.constant = spacing }
	}
	
	fileprivate var spacingConstraint: NSLayoutConstraint!
	
	public override required init(frame: CGRect) {
		super.init(frame: frame)
		commonInit()
	}
	
	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	fileprivate func commonInit() {
		for view in [headerLabel, textLabel] {
			view.translatesAutoresizingMaskIntoConstraints = false
			addSubview(view)
		}
		
		let views = ["header": headerLabel, "text": textLabel]
		let metrics: [String: NSNumber] = [:]
		
		var constraints = [NSLayoutConstraint]()
		
		constraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|-[header]", options: [], metrics: metrics, views: views)
		constraints += NSLayoutConstraint.constraints(withVisualFormat: "V:[text]-|", options: [], metrics: metrics, views: views)
		
		spacingConstraint = NSLayoutConstraint(item: textLabel, attribute: .top, relatedBy: .equal, toItem: headerLabel, attribute: .bottom, multiplier: 1, constant: spacing)
		constraints.append(spacingConstraint)
		
		constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-[header]-|", options: [], metrics: metrics, views: views)
		constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-[text]-|", options: [], metrics: metrics, views: views)
		
		NSLayoutConstraint.activate(constraints)
	}
	
}

// MARK: - DupleHeadedTextCell

/// A `CollectionViewCell` which displays two `HeadedTextView`s side-by-side.
open class DupleHeadedTextCell : CollectionViewCell {
	
	/// The first `HeadedTextView` displayed by `self`.
	open let headedTextView1 = HeadedTextView()
	
	/// The second `HeadedTextView` displayed by `self`.
	open let headedTextView2 = HeadedTextView()
	
	/// The horizontal spacing between the `HeadedTextView`s displayed by `self`.
	open var horizontalSpacing: CGFloat = 22 {
		didSet { horizontalSpacingConstraint.constant = horizontalSpacing }
	}
	
	/// The vertical spacing used by the `HeadedTextView`s displayed by `self`.
	open var verticalSpacing: CGFloat = 7 {
		didSet {
			headedTextView1.spacing = verticalSpacing
			headedTextView2.spacing = verticalSpacing
		}
	}
	
	open override var layoutMargins: UIEdgeInsets {
		didSet {
			contentView.layoutMargins = layoutMargins
		}
	}
	
	fileprivate var horizontalSpacingConstraint: NSLayoutConstraint!
	
	public override init(frame: CGRect) {
		super.init(frame: frame)
		commonInit()
	}
	
	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	fileprivate func commonInit() {
		for view in [headedTextView1, headedTextView2] {
			view.layoutMargins = .zero
			view.translatesAutoresizingMaskIntoConstraints = false
			contentView.addSubview(view)
		}
		
		let views = ["headedText1": headedTextView1, "headedText2": headedTextView2]
		let metrics: [String: NSNumber] = [:]
		
		var constraints = [NSLayoutConstraint]()
		
		constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-[headedText1]", options: [], metrics: metrics, views: views)
		constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:[headedText2]-(>=0)-|", options: [], metrics: metrics, views: views)
		
		horizontalSpacingConstraint = NSLayoutConstraint(item: headedTextView2, attribute: .leading, relatedBy: .equal, toItem: headedTextView1, attribute: .trailing, multiplier: 1, constant: horizontalSpacing)
		constraints.append(horizontalSpacingConstraint)
		
		for idx in ["1", "2"] {
			constraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|-[headedText\(idx)]-|", options: [], metrics: metrics, views: views)
		}
		
		NSLayoutConstraint.activate(constraints)
	}
	
}
