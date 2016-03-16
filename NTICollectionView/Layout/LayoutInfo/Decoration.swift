//
//  Decoration.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 3/15/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public protocol DecorationProvider {
	
	typealias SectionType: LayoutSection
	
}

public protocol Decoration {
	
	var elementKind: String { get }
	
}

public protocol LayoutDecoration: Decoration, LayoutElement {
	
	typealias SectionType: LayoutSection
	
}