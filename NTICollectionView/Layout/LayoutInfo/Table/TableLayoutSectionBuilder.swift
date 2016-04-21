//
//  TableLayoutSectionBuilder.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 4/19/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public struct TableLayoutSectionBuilder: LayoutSectionBuilder {
	
	public init() {}
	
	public func makeLayoutSection(using description: SectionDescription, in layoutBounds: SectionLayoutBounds) -> LayoutSection {
		var section = TableLayoutSection()
		
		section.frame.origin = layoutBounds.origin
		section.frame.size.width = layoutBounds.width
		
		// TODO: Implement
		
		
		return section
	}
	
}
