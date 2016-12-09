//
//  ComposedGridSectionLayoutEngine.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 3/11/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

open class ComposedGridSectionLayoutEngine: NSObject, SupplementaryLayoutEngine {

	public init(sections: [GridLayoutSection]) {
		self.sections = sections
	}
	
	open var sections: [GridLayoutSection]
	
	open var pinnableHeaders: [LayoutSupplementaryItem] = []
	open var nonPinnableHeaders: [LayoutSupplementaryItem] = []
	open var supplementaryItems: [LayoutSupplementaryItem] = []
	
	fileprivate var origin: CGPoint!
	fileprivate var position: CGPoint!
	fileprivate var sizing: LayoutSizing!
	fileprivate var invalidationContext: UICollectionViewLayoutInvalidationContext?
	
	open func layoutWithOrigin(_ origin: CGPoint, layoutSizing: LayoutSizing, invalidationContext: UICollectionViewLayoutInvalidationContext?) -> CGPoint {
		self.origin = origin
		position = origin
		sizing = layoutSizing
		self.invalidationContext = invalidationContext
		
		layoutSections()
		
		return position
	}
	
	fileprivate func layoutSections() {
		for index in sections.indices {
			layout(&sections[index])
		}
	}
	
	fileprivate func layout(_ section: inout GridLayoutSection) {
		position.x = origin.x
		
		let layoutEngine = GridSectionLayoutEngine(layoutSection: section)
		position = layoutEngine.layoutWithOrigin(position, layoutSizing: sizing, invalidationContext: invalidationContext)
		
		pinnableHeaders += section.pinnableHeaders
		nonPinnableHeaders += section.nonPinnableHeaders
		supplementaryItems += section.supplementaryItems
		
		section = layoutEngine.layoutSection
	}
	
}
