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
	public var supplementaryItems: [LayoutSupplementaryItem] = []
	
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
		
		if var globalSection = layoutInfo.sectionAtIndex(globalSectionIndex) {
			let globalSize = CGSize(width: self.layoutInfo.width, height: self.position.y - origin.y)
			globalSection.frame = CGRect(origin: origin, size: globalSize)
			layoutInfo.setSection(globalSection, at: globalSectionIndex)
		}
		
		return position
	}
	
	private func layoutSectionInfo() {
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
	
	private func makeLayoutEngine() -> SupplementaryLayoutEngine {
		return makeGlobalSectionLayoutEngine() ?? makeSectionsLayoutEngine()
	}
	
	private func makeGlobalSectionLayoutEngine() -> SupplementaryLayoutEngine? {
		guard let globalSection = layoutInfo.sectionAtIndex(globalSectionIndex) as? GridLayoutSection else {
			return nil
		}
		let sectionsLayoutEngine = makeSectionsLayoutEngine()
		return GridSupplementaryItemLayoutEngine(layoutSection: globalSection, innerLayoutEngine: sectionsLayoutEngine)
	}
	
	private func makeSectionsLayoutEngine() -> SupplementaryLayoutEngine {
		return ComposedGridSectionLayoutEngine(sections: sections)
	}
	private var sections: [GridLayoutSection] {
		var sections: [GridLayoutSection] = []
		for i in 0..<(layoutInfo.numberOfSections) {
			guard let section = layoutInfo.sectionAtIndex(i) as? GridLayoutSection else {
				continue
			}
			sections.append(section)
		}
		return sections
	}
	
	private func replaceSections(from layoutEngine: ComposedGridSectionLayoutEngine) {
		for (index, section) in layoutEngine.sections.enumerate() {
			layoutInfo.setSection(section, at: index)
		}
	}
	
}
