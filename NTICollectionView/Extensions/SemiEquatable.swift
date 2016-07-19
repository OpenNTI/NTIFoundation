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

extension NSObject : SemiEquatable {

	public func isEqual(to other: Any) -> Bool {
		guard let other = other as? NSObject else {
			return false
		}
		
		return self == other
	}

}

extension String : SemiEquatable {

	public func isEqual(to other: Any) -> Bool {
		guard let other = other as? String else {
			return false
		}
		
		return self == other
	}
	
}

extension Int : SemiEquatable {

	public func isEqual(to other: Any) -> Bool {
		guard let other = other as? Int else {
			return false
		}
		
		return self == other
	}

}

extension Bool : SemiEquatable {

	public func isEqual(to other: Any) -> Bool {
		guard let other = other as? Bool else {
			return false
		}
		
		return self == other
	}

}

extension SequenceType where Generator.Element : SemiEquatable {
	
	public func isEqual(to other: Self) -> Bool {
		return elementsEqual(other) { $0.isEqual(to: $1) }
	}
	
}
