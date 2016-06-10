//
//  TableLayoutBuilder.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 6/9/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public struct TableLayoutBuilder : LayoutBuilder {
	
	public func makeLayoutData(using description: LayoutDescription, at origin: CGPoint) -> LayoutData {
		var data = LayoutData()
		
		var sectionBounds = LayoutAreaBounds(origin: origin, width: description.bounds.width)
		sectionBounds.origin.x += description.contentInset.left
		sectionBounds.origin.y += description.contentInset.top
		sectionBounds.width -= description.contentInset.width
		
		
		
		return data
	}
	
}
