//
//  CGGeometry-Extensions.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/25/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
	return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

extension CGPoint {
	
	public static var zero: CGPoint {
		return CGPoint.zero
	}
	
}

extension CGSize {
	
	public static var zero: CGSize {
		return CGSize.zero
	}
	
}

extension CGRect {
	
	public static var zero: CGRect {
		return CGRect.zero
	}
	
}

//extension CGPoint: IntegerLiteralConvertible {
//	
//	public init(integerLiteral value: Self.IntegerLiteralType) {
//		x = value
//		y = value
//	}
//	
//}
