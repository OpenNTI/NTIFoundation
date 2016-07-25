//
//  Layout.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 7/25/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import CoreGraphics

/// A type that can layout itself and its contents.
protocol Layout {
	
	/// The type of the leaf content elements in this layout.
	associatedtype Content
	
	/// Return all of the leaf content elements contained in this layout and its descendants.
	var contents: [Content] { get }
	
	/// Lays out this layout and all of its contained layouts within `rect`.
	mutating func layout(in rect: CGRect)
}
