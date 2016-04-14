//
//  TextValueCell.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 4/14/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

/// A simple `CollectionViewCell` that displays a large block of text.
public class TextValueCell: CollectionViewCell {
	
	public var numberOfLines: Int = 0 {
		didSet {
			if allowsTruncation {
				textLabel.numberOfLines = numberOfLines
			}
		}
	}
	
	public var allowsTruncation = false {
		didSet {
			if allowsTruncation {
				textLabel.numberOfLines = numberOfLines
			} else {
				textLabel.numberOfLines = 0
			}
		}
	}
	
	public let titleLabel = UILabel()
	
	public let textLabel = TruncatingLabel()
	
	public func configureWith(title title: String?, text: String?) {
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
	
	private func commonInit() {
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		titleLabel.numberOfLines = 1
		contentView.addSubview(titleLabel)
		
		textLabel.translatesAutoresizingMaskIntoConstraints = false
		textLabel.lineBreakMode = .ByWordWrapping
		textLabel.numberOfLines = 0
		contentView.addSubview(textLabel)
		
		let views = ["label": textLabel, "title": titleLabel]
		
		NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
			"H:|-[title]-|", options: [], metrics: nil, views: views))
		NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
			"H:|-[label]-|", options: [], metrics: nil, views: views))
		NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
			"V:|-[title]-[label]-|", options: [], metrics: nil, views: views))
	}
	
	public override func layoutSubviews() {
		textLabel.preferredMaxLayoutWidth = bounds.width - 30
		super.layoutSubviews()
	}
	
}
