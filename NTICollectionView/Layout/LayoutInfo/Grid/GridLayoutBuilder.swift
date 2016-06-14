//
//  GridLayoutBuilder.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 6/13/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public struct GridLayoutBuilder : LayoutBuilder {
	
	public init() {}
	
	public func buildLayout(from description: LayoutDescription, at origin: CGPoint, inout using data: LayoutData) {
		let width = data.viewBounds.width
		var sectionBounds = LayoutAreaBounds(origin: origin, width: width)
		sectionBounds.origin.x += data.contentInset.left
		sectionBounds.width -= data.contentInset.width
		
		if let globalSectionDesc = description.globalSection {
			var globalSection = GridLayoutSection()
			globalSection.sectionIndex = globalSectionIndex
			globalSection.frame.origin = sectionBounds.origin
			globalSection.frame.size.width = sectionBounds.width
			globalSection.applyValues(from: globalSectionDesc.metrics)
			
			let plan = GridLayoutPlanBuilder().makeLayoutItems(using: globalSectionDesc, in: sectionBounds)
			
			for header in plan.headers {
				globalSection.add(header)
			}
			
			for leftItem in plan.leftItems {
				globalSection.add(leftItem)
			}
			
			for rightItem in plan.rightItems {
				globalSection.add(rightItem)
			}
			
			sectionBounds = plan.contentBounds
			data.globalSection = globalSection
		}
		
		data.sections = LayoutSectionStackBuilder().makeLayoutSections(with: description.sections, using: GridLayoutSectionBuilder(), in: sectionBounds)
		
		let height: CGFloat
		if let lastSection = data.allSections.last {
			height = lastSection.frame.maxY + data.contentInset.bottom
		} else {
			height = 0
		}
		
		data.layoutSize = CGSize(width: width, height: height)
	}
	
}
