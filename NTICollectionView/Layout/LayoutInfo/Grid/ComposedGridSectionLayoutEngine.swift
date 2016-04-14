//
//  ComposedGridSectionLayoutEngine.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 3/11/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public class ComposedGridSectionLayoutEngine: NSObject, SupplementaryLayoutEngine {

	public init(sections: [LayoutSection]) {
		self.sections = sections
	}
	
	public var sections: [LayoutSection]
	
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
	
	private func layout(section: LayoutSection) {
		position.x = origin.x
		position = section.layoutWithOrigin(position, layoutSizing: sizing, invalidationContext: invalidationContext)
		pinnableHeaders += section.pinnableHeaders
		nonPinnableHeaders += section.nonPinnableHeaders
		supplementaryItems += section.supplementaryItems
	}
	
}
