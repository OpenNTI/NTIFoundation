//
//  Dictionary-Extensions.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 3/15/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import Foundation

extension Dictionary where Value: RangeReplaceableCollection & ExpressibleByArrayLiteral {
	
	public var contents: [Value.Iterator.Element] {
		var allContents: [Value.Iterator.Element] = []
		for contents in values {
			allContents += contents
		}
		return allContents
	}
	
	public mutating func append(_ x: Value.Iterator.Element, to key: Key) {
		var items = self[key] ?? []
		items.append(x)
		self[key] = items
	}
	
	public mutating func appendContents(of dictionary: [Key: Value]) {
		for (key, value) in dictionary {
			appendContents(of: value, to: key)
		}
	}
	
	public mutating func appendContents(of newElements: Value, to key: Key) {
		var items = self[key] ?? []
		items.append(contentsOf: newElements)
		self[key] = items
	}
	
	public func countDiff(with other: [Key: Value]) -> [Key: Int] {
		var countDiffs: [Key: Int] = [:]
		let allKeys = Set(keys).union(other.keys)
		for key in allKeys {
			let items = Array(self[key] ?? [])
			let otherItems = Array(other[key] ?? [])
			let countDiff = items.count - otherItems.count
			countDiffs[key] = countDiff
		}
		return countDiffs
	}
	
}
