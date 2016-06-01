//
//  SemiEquatable.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 6/1/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import Foundation

public protocol SemiEquatable {
	
	func isEqual(to other: Any) -> Bool
	
}

extension Equatable {
	
	public func isEqual(to other: Any) -> Bool {
		guard let other = other as? Self else {
			return false
		}
		
		return self == other
	}
	
}

extension NSObject : SemiEquatable {}

extension String : SemiEquatable {}

extension Int : SemiEquatable {}

extension Bool : SemiEquatable {}

extension SequenceType where Generator.Element : SemiEquatable {
	
	public func isEqual(to other: Self) -> Bool {
		return elementsEqual(other) { $0.isEqual(to: $1) }
	}
	
}
