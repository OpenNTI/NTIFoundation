//
//  TextValueCell.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 4/14/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

/// A simple `CollectionViewCell` that displays a large block of text.
open class TextValueCell: CollectionViewCell {
	
	open var numberOfLines: Int = 0 {
		didSet {
			if allowsTruncation {
				textLabel.numberOfLines = numberOfLines
			}
		}
	}
	
	open var allowsTruncation = false {
		didSet {
			if allowsTruncation {
				textLabel.numberOfLines = numberOfLines
			} else {
				textLabel.numberOfLines = 0
			}
		}
	}
	
	open let titleLabel = UILabel()
	
	open let textLabel = TruncatingLabel()
	
	open func configureWith(title: String?, text: String?) {
		titleLabel.text = title
		textLabel.text = text
	}
	
	public override init(frame: CGRect) {
		super.init(frame: frame)
		commonInit()
	}
	
	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		commonInit()
	}
	
	fileprivate func commonInit() {
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		titleLabel.numberOfLines = 1
		contentView.addSubview(titleLabel)
		
		textLabel.translatesAutoresizingMaskIntoConstraints = false
		textLabel.lineBreakMode = .byWordWrapping
		textLabel.numberOfLines = 0
		contentView.addSubview(textLabel)
		
		let views = ["label": textLabel, "title": titleLabel]
		
		NSLayoutConstraint.activate(NSLayoutConstraint.constraints(
			withVisualFormat: "H:|-[title]-|", options: [], metrics: nil, views: views))
		NSLayoutConstraint.activate(NSLayoutConstraint.constraints(
			withVisualFormat: "H:|-[label]-|", options: [], metrics: nil, views: views))
		NSLayoutConstraint.activate(NSLayoutConstraint.constraints(
			withVisualFormat: "V:|-[title]-[label]-|", options: [], metrics: nil, views: views))
	}
	
	open override func layoutSubviews() {
		textLabel.preferredMaxLayoutWidth = bounds.width - 30
		super.layoutSubviews()
	}
	
}
