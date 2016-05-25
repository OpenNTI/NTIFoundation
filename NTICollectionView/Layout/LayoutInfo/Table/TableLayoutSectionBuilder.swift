//
//  TableLayoutSectionBuilder.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 4/19/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public struct TableLayoutSectionBuilder: LayoutSectionBuilder {
	
	public init?(metrics: SectionMetrics) {
		guard let tableMetrics = metrics as? TableSectionMetrics else {
			return nil
		}
		self.metrics = tableMetrics
	}
	
	private let metrics: TableSectionMetrics
	
	public func makeLayoutSection(using description: SectionDescription, in layoutBounds: LayoutAreaBounds) -> LayoutSection {
		var section = TableLayoutSection()
		
		section.frame.origin = layoutBounds.origin
		section.frame.size.width = layoutBounds.width
		
		// TODO: Implement
		
		
		return section
	}
	
}
