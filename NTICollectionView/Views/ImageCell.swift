//
//  ImageCell.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 5/31/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

/// A `CollectionViewCell` that displays a single image aligned to the `layoutMargins` of its `contentView`.
open class ImageCell: CollectionViewCell {
	
	/// The image displayed by `self`.
	open var image: UIImage? {
		get { return imageView.image }
		set { imageView.image = newValue }
	}

	fileprivate let imageView = UIImageView()
	
	open override var layoutMargins: UIEdgeInsets {
		didSet { contentView.layoutMargins = layoutMargins }
	}
	
	public override init(frame: CGRect) {
		super.init(frame: frame)
		commonInit()
	}
	
	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	fileprivate func commonInit() {
		imageView.translatesAutoresizingMaskIntoConstraints = false
		contentView.addSubview(imageView)
		
		let views = ["image": imageView]
		for axis in ["H", "V"] {
			let constraints = NSLayoutConstraint.constraints(
				withVisualFormat: "\(axis):|-[image]-|", options: [], metrics: nil, views: views)
			NSLayoutConstraint.activate(constraints)
		}
	}

}
