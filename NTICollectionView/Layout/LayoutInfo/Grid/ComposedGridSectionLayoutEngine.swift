//
//  ComposedGridSectionLayoutEngine.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 3/11/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public class ComposedGridSectionLayoutEngine: NSObject, SupplementaryLayoutEngine {

	public init(sections: [GridLayoutSection]) {
		self.sections = sections
	}
	
	public var sections: [GridLayoutSection]
	
	public var pinnableHeaders: [LayoutSupplementaryItem] = []
	public var nonPinnableHeaders: [LayoutSupplementaryItem] = []
	public var supplementaryItems: [LayoutSupplementaryItem] = []
	
	private var origin: CGPoint!
	private var position: CGPoint!
	private var sizing: LayoutSizing!
	private var invalidationContext: UICollectionViewLayoutInvalidationContext?
	
	public func layoutWithOrigin(origin: CGPoint, layoutSizing: LayoutSizing, invalidationContext: UICollectionViewLayoutInvalidationContext?) -> CGPoint {
		self.origin = origin
		position = origin
		sizing = layoutSizing
		self.invalidationContext = invalidationContext
		
		layoutSections()
		
		return position
	}
	
	private func layoutSections() {
		for section in sections {
			layout(section)
		}
	}
	
	private func layout(section: GridLayoutSection) {
		position.x = origin.x
		
		let layoutEngine = GridSectionLayoutEngine(layoutSection: section)
		position = layoutEngine.layoutWithOrigin(position, layoutSizing: sizing, invalidationContext: invalidationContext)
		
		pinnableHeaders += section.pinnableHeaders
		nonPinnableHeaders += section.nonPinnableHeaders
		supplementaryItems += section.supplementaryItems
	}
	
}
