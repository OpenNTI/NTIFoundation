//
//  UIEdgeInsets-Extensions.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 3/10/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

extension UIEdgeInsets {
	
	public static var zero: UIEdgeInsets {
		return UIEdgeInsetsZero
	}
	
	/// The combined left and right inset.
	public var width: CGFloat {
		return left + right
	}
	
	/// The combined top and bottom inset.
	public var height: CGFloat {
		return top + bottom
	}
	
}

extension UIEdgeInsets {
	
	public init(uniformInset: CGFloat) {
		top = uniformInset
		left = uniformInset
		bottom = uniformInset
		right = uniformInset
	}
	
}
