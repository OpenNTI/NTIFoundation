//
//  GridLayoutEngine.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 3/10/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public class GridLayoutEngine: NSObject, SupplementaryLayoutEngine {
	
	public init(layoutInfo: LayoutInfo) {
		self.layoutInfo = layoutInfo
		super.init()
	}
	
	public var layoutInfo: LayoutInfo
	
	public var pinnableHeaders: [LayoutSupplementaryItem] = []
	public var nonPinnableHeaders: [LayoutSupplementaryItem] = []
	
	private var sizing: LayoutSizing!
	private var invalidationContext: UICollectionViewLayoutInvalidationContext?
	
	private var origin: CGPoint!
	private var position: CGPoint!
	
	public func layoutWithOrigin(origin: CGPoint, layoutSizing: LayoutSizing, invalidationContext: UICollectionViewLayoutInvalidationContext?) -> CGPoint {
		self.origin = origin
		self.position = origin
		sizing = layoutSizing
		self.invalidationContext = invalidationContext
		
		layoutSectionInfo()
		
		if let globalSection = layoutInfo.sectionAtIndex(GlobalSectionIndex) {
			let globalSize = CGSize(width: layoutInfo.width, height: position.y - origin.y)
			globalSection.frame = CGRect(origin: origin, size: globalSize)
		}
		
		return position
	}
	
	private func layoutSectionInfo() {
		let engine = makeLayoutEngine()
		position = engine.layoutWithOrigin(position, layoutSizing: sizing, invalidationContext: invalidationContext)
		pinnableHeaders += engine.pinnableHeaders
		nonPinnableHeaders += engine.nonPinnableHeaders
	}
	
	private func makeLayoutEngine() -> SupplementaryLayoutEngine {
		return makeGlobalSectionLayoutEngine() ?? makeSectionsLayoutEngine()
	}
	
	private func makeGlobalSectionLayoutEngine() -> SupplementaryLayoutEngine? {
		guard let globalSection = layoutInfo.sectionAtIndex(GlobalSectionIndex) as? GridLayoutSection else {
			return nil
		}
		let sectionsLayoutEngine = makeSectionsLayoutEngine()
		return GridSupplementaryItemLayoutEngine(layoutSection: globalSection, innerLayoutEngine: sectionsLayoutEngine)
	}
	
	private func makeSectionsLayoutEngine() -> SupplementaryLayoutEngine {
		return ComposedGridSectionLayoutEngine(sections: sections)
	}
	private var sections: [LayoutSection] {
		var sections: [LayoutSection] = []
		for i in 0..<(layoutInfo.numberOfSections) {
			guard let section = layoutInfo.sectionAtIndex(i) else {
				continue
			}
			sections.append(section)
		}
		return sections
	}
	
}
