//
//  UICollectionReusableView-Extensions.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 3/23/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

/*
extension UICollectionReusableView: Selectable {
	
}
*/

@objc public protocol Selectable {
	
	func didBecomeSelected()
	
	func didBecomeDeselected()
	
}

/*
extension Selectable {
	
	public func didBecomeSelected() {
		// Do nothing by default
	}
	
	public func didBecomeDeselected() {
		// Do nothing by default
	}
	
}
*/
