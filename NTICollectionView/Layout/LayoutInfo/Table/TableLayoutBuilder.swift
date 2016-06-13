//
//  TableLayoutBuilder.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 6/9/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public struct TableLayoutBuilder : LayoutBuilder {
	
	public init() {}
	
	public func buildLayout(from description: LayoutDescription, at origin: CGPoint, inout using data: LayoutData) {
		let width = data.viewBounds.width
		var sectionBounds = LayoutAreaBounds(origin: origin, width: width)
		sectionBounds.origin.x += data.contentInset.left
		sectionBounds.width -= data.contentInset.width
		
		if let globalSectionDesc = description.globalSection {
			let sectionBuilder = TableLayoutSectionBuilder()
			let globalSection = sectionBuilder.makeLayoutSection(using: globalSectionDesc, in: sectionBounds)
			sectionBounds.origin.y += globalSection.frame.height
			data.globalSection = globalSection
		}
		
		data.sections = LayoutSectionStackBuilder().makeLayoutSections(with: description.sections, using: TableLayoutSectionBuilder(), in: sectionBounds)
		
		let height: CGFloat
		if let lastSection = data.allSections.last {
			height = lastSection.frame.maxY + data.contentInset.bottom
		} else {
			height = 0
		}
		
		data.layoutSize = CGSize(width: width, height: height)
	}
	
}
