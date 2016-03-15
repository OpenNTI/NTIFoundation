//
//  Dictionary-Extensions.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 3/15/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import Foundation

extension Dictionary where Value: Array<Any> {
	
	public mutating func append(x: Value.Generator.Element, to key: Key) {
		var items = self[key] ?? []
		items.append(x)
		self[key] = items
	}
	
	public mutating func appendContentsOf(newElements: Value, to key: Key) {
		var items = self[key] ?? []
		items.appendContentsOf(newElements)
		self[key] = items
	}
	
}
