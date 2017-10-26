//
//  DummyLayoutInfo.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/18/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

class DummyLayoutInfo: NSObject, LayoutInfo {

	var collectionViewSize = CGSize.zero
	
	var width: CGFloat = 0
	
	var height: CGFloat = 0
	
	var heightAvailableForPlaceholders: CGFloat = 0
	
	var contentOffset = CGPoint.zero
	
	var contentInset = UIEdgeInsets.zero
	
	var bounds = CGRect.zero
	
	var layoutMeasure: CollectionViewLayoutMeasuring?
	
	var isEditing = false
	
	var numberOfSections = 0
	
	var hasGlobalSection = false
	
	var sections: [LayoutSection] = []
	
	func mutateSection(at index: Int, using mutator: (inout LayoutSection) -> Void) {
		
	}
	
	func mutateItem(at indexPath: IndexPath, using mutator: (inout LayoutItem) -> Void) {
		
	}
	
	func enumerateSections(_ block: (_ sectionIndex: Int, _ sectionInfo: inout LayoutSection, _ stop: inout Bool) -> Void) {
		
	}
	
	func sectionAtIndex(_ sectionIndex: Int) -> LayoutSection? {
		return sections[sectionIndex]
	}
	
	func setSection(_ section: LayoutSection, at sectionIndex: Int) {
		sections[sectionIndex] = section
	}
	
	func add(_ section: LayoutSection, sectionIndex: Int) {
		sections.insert(section, at: sectionIndex)
	}
	
	func newPlaceholderStartingAtSectionIndex(_ sectionIndex: Int) -> LayoutPlaceholder {
		return BasicLayoutPlaceholder(sectionIndexes: IndexSet())
	}
	
	func invalidate() {
		
	}
	
	func finalizeLayout() {
		
	}
	
	func setSize(_ size: CGSize, forItemAt indexPath: IndexPath, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		
	}
	
	func setSize(_ size: CGSize, forElementOfKind kind: String, at indexPath: IndexPath, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		
	}
	
	func invalidateMetricsForItemAt(_ indexPath: IndexPath, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		
	}
	
	func invalidateMetricsForElementOfKind(_ kind: String, at indexPath: IndexPath, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		
	}
	
	func layoutAttributesForCell(at indexPath: IndexPath) -> CollectionViewLayoutAttributes? {
		return nil
	}
	
	func layoutAttributesForDecorationViewOfKind(_ kind: String, at indexPath: IndexPath) -> CollectionViewLayoutAttributes? {
		return nil
	}
	
	func layoutAttributesForSupplementaryElementOfKind(_ kind: String, at indexPath: IndexPath) -> CollectionViewLayoutAttributes? {
		return nil
	}
	
	func prepareForLayout() {
		
	}
	
	func updateSpecialItemsWithContentOffset(_ contentOffset: CGPoint, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		
	}
	
}

