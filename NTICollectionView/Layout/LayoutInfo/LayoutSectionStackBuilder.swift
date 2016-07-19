//
//  LayoutSectionStackBuilder.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 6/9/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

/// Builds layout sections in a vertical top-to-bottom stack.
public struct LayoutSectionStackBuilder {
	
	public func makeLayoutSections(with descriptions: [SectionDescription], using sectionBuilder: LayoutSectionBuilder, in bounds: LayoutAreaBounds) -> [LayoutSection] {
		var layoutSections = [LayoutSection]()
		var positionBounds = bounds
		
		for description in descriptions {
			let metrics = description.metrics
			let inset = metrics.contentInset
			
			positionBounds.origin.y += inset.top
			
			var sectionBounds = positionBounds
			sectionBounds.origin.x += inset.left
			sectionBounds.width -= inset.width
			
			let section = sectionBuilder.makeLayoutSection(using: description, in: sectionBounds)
			layoutSections.append(section)
			
			positionBounds.origin.y += section.frame.height + inset.bottom
		}
		
		return layoutSections
	}
	
}
