//
//  Array-Extensions.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 3/30/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import Foundation

extension Array where Element: AnyObject {
	
	/// Returns `true` iff `object` is in `self`.
	public func containsObject(_ object: AnyObject) -> Bool {
		return contains(where: { $0 === object })
	}
	
	/// Returns the first index where `object` appears in `self` or `nil` if `object` is not found.
	public func indexOfObject(_ object: AnyObject) -> Int? {
		return index(where: { $0 === object})
	}
	
}
