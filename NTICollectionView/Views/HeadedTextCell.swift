//
//  HeadedTextCell.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 6/1/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

/// A `CollectionViewCell` which displays header text above primary text.
public class HeadedTextCell: CollectionViewCell {
	
	/// Displays the header text.
	public let headerLabel = UILabel()
	
	/// Displays the primary text.
	public let textLabel = UILabel()
	
	private let wrapper = UIView()
	
	public override init(frame: CGRect) {
		super.init(frame: frame)
		commonInit()
	}
	
	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	private func commonInit() {
		wrapper.translatesAutoresizingMaskIntoConstraints = false
		contentView.addSubview(wrapper)
		
		headerLabel.translatesAutoresizingMaskIntoConstraints = false
		wrapper.addSubview(headerLabel)
		
		textLabel.translatesAutoresizingMaskIntoConstraints = false
		wrapper.addSubview(textLabel)
		
		let views = ["wrapper": wrapper, "header": headerLabel, "text": textLabel]
		let metrics = ["s": 7]
		
		var constraints = [NSLayoutConstraint]()
		constraints += NSLayoutConstraint.constraintsWithVisualFormat("V:|[header]-s-[text]|", options: [], metrics: metrics, views: views)
		constraints += NSLayoutConstraint.constraintsWithVisualFormat("H:|[header]|", options: [], metrics: metrics, views: views)
		constraints += NSLayoutConstraint.constraintsWithVisualFormat("H:|[text]|", options: [], metrics: metrics, views: views)
		constraints += NSLayoutConstraint.constraintsWithVisualFormat("H:|-(>=0)-[wrapper]-(>=0)-|", options: [], metrics: metrics, views: views)
		constraints += NSLayoutConstraint.constraintsWithVisualFormat("V:|-(>=0)-[wrapper]-(>=0)-|", options: [], metrics: metrics, views: views)
		constraints.append(NSLayoutConstraint(item: wrapper, attribute: .CenterX, relatedBy: .Equal, toItem: contentView, attribute: .CenterX, multiplier: 1, constant: 0))
		constraints.append(NSLayoutConstraint(item: wrapper, attribute: .CenterY, relatedBy: .Equal, toItem: contentView, attribute: .CenterY, multiplier: 1, constant: 0))
		NSLayoutConstraint.activateConstraints(constraints)
	}

}
