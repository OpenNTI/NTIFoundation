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
		data.contentInset = description.contentInset
		data.contentOffset = description.contentOffset
		data.viewBounds = description.bounds
		
		let width = description.bounds.width
		var sectionBounds = LayoutAreaBounds(origin: origin, width: width)
		sectionBounds.origin.x += description.contentInset.left
		sectionBounds.origin.y += description.contentInset.top
		sectionBounds.width -= description.contentInset.width
		
		if let globalSectionDesc = description.globalSection {
			let sectionBuilder = TableLayoutSectionBuilder()
			let globalSection = sectionBuilder.makeLayoutSection(using: globalSectionDesc, in: sectionBounds)
			sectionBounds.origin.y += globalSection.frame.height
			data.globalSection = globalSection
		}
		
		data.sections = LayoutSectionStackBuilder().makeLayoutSections(with: description.sections, using: TableLayoutSectionBuilder(), in: sectionBounds)
		
		let height: CGFloat
		if let lastSection = data.sections.last ?? data.globalSection {
			height = lastSection.frame.maxY + description.contentInset.bottom
		} else {
			height = 0
		}
		
		data.layoutSize = CGSize(width: width, height: height)
		
		return data
	}
	
}
