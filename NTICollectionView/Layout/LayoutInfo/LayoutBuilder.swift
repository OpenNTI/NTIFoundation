//
//  LayoutBuilder.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 4/19/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

/// Conforming types can build `LayoutInfo` instances from `LayoutDescription`s.
public protocol LayoutBuilder {
	
	func buildLayout(from description: LayoutDescription, at origin: CGPoint, inout using data: LayoutData)
	
}

/// Conforming types can build `LayoutSection` instances from `SectionDescription`s.
public protocol LayoutSectionBuilder {
	
	func makeLayoutSection(using description: SectionDescription, in layoutBounds: LayoutAreaBounds) -> LayoutSection
	
}


public struct LayoutAreaBounds {
	
	public var origin: CGPoint
	
	public var width: CGFloat
	
}