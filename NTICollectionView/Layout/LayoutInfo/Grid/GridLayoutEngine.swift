//
//  GridLayoutEngine.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 3/10/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

open class GridLayoutEngine: NSObject, SupplementaryLayoutEngine {
	
	public init(layoutInfo: LayoutInfo) {
		self.layoutInfo = layoutInfo
		super.init()
	}
	
	open var layoutInfo: LayoutInfo
	
	open var pinnableHeaders: [LayoutSupplementaryItem] = []
	open var nonPinnableHeaders: [LayoutSupplementaryItem] = []
	open var supplementaryItems: [LayoutSupplementaryItem] = []
	
	fileprivate var sizing: LayoutSizing!
	fileprivate var invalidationContext: UICollectionViewLayoutInvalidationContext?
	
	fileprivate var origin: CGPoint!
	fileprivate var position: CGPoint!
	
	open func layoutWithOrigin(_ origin: CGPoint, layoutSizing: LayoutSizing, invalidationContext: UICollectionViewLayoutInvalidationContext?) -> CGPoint {
		self.origin = origin
		self.position = origin
		sizing = layoutSizing
		self.invalidationContext = invalidationContext
		
		layoutSectionInfo()
		
		if var globalSection = layoutInfo.sectionAtIndex(globalSectionIndex) {
			let globalSize = CGSize(width: self.layoutInfo.width, height: self.position.y - origin.y)
			globalSection.frame = CGRect(origin: origin, size: globalSize)
			layoutInfo.setSection(globalSection, at: globalSectionIndex)
		}
		
		return position
	}
	
	fileprivate func layoutSectionInfo() {
		let engine = makeLayoutEngine()
		position = engine.layoutWithOrigin(position, layoutSizing: sizing, invalidationContext: invalidationContext)
		pinnableHeaders += engine.pinnableHeaders
		nonPinnableHeaders += engine.nonPinnableHeaders
		supplementaryItems += engine.supplementaryItems
		
		if let supplementaryEngine = engine as? GridSupplementaryItemLayoutEngine {
			layoutInfo.setSection(supplementaryEngine.layoutSection, at: globalSectionIndex)
			
			if let composedEngine = supplementaryEngine.innerLayoutEngine as? ComposedGridSectionLayoutEngine {
				replaceSections(from: composedEngine)
			}
		}
		else if let composedEngine = engine as? ComposedGridSectionLayoutEngine {
			replaceSections(from: composedEngine)
		}
	}
	
	fileprivate func makeLayoutEngine() -> SupplementaryLayoutEngine {
		return makeGlobalSectionLayoutEngine() ?? makeSectionsLayoutEngine()
	}
	
	fileprivate func makeGlobalSectionLayoutEngine() -> SupplementaryLayoutEngine? {
		guard let globalSection = layoutInfo.sectionAtIndex(globalSectionIndex) as? GridLayoutSection else {
			return nil
		}
		let sectionsLayoutEngine = makeSectionsLayoutEngine()
		return GridSupplementaryItemLayoutEngine(layoutSection: globalSection, innerLayoutEngine: sectionsLayoutEngine)
	}
	
	fileprivate func makeSectionsLayoutEngine() -> SupplementaryLayoutEngine {
		return ComposedGridSectionLayoutEngine(sections: sections)
	}
	fileprivate var sections: [GridLayoutSection] {
		var sections: [GridLayoutSection] = []
		for i in 0..<(layoutInfo.numberOfSections) {
			guard let section = layoutInfo.sectionAtIndex(i) as? GridLayoutSection else {
				continue
			}
			sections.append(section)
		}
		return sections
	}
	
	fileprivate func replaceSections(from layoutEngine: ComposedGridSectionLayoutEngine) {
		for (index, section) in layoutEngine.sections.enumerated() {
			layoutInfo.setSection(section, at: index)
		}
	}
	
}
