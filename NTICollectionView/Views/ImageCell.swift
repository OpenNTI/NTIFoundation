//
//  ImageCell.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 5/31/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

/// A `CollectionViewCell` that displays a single image aligned to the `layoutMargins` of its `contentView`.
public class ImageCell: CollectionViewCell {
	
	/// The image displayed by `self`.
	public var image: UIImage? {
		get { return imageView.image }
		set { imageView.image = newValue }
	}

	private let imageView = UIImageView()
	
	public override init(frame: CGRect) {
		super.init(frame: frame)
		commonInit()
	}
	
	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	private func commonInit() {
		imageView.translatesAutoresizingMaskIntoConstraints = false
		contentView.addSubview(imageView)
		
		let views = ["image": imageView]
		for axis in ["H", "V"] {
			let constraints = NSLayoutConstraint.constraintsWithVisualFormat(
				"\(axis):|-[image]-|", options: [], metrics: nil, views: views)
			NSLayoutConstraint.activateConstraints(constraints)
		}
	}

}
