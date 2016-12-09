//
//  BasicLayoutInfo.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/18/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

open class BasicLayoutInfo: LayoutInfo {
	
	public init(layoutMeasure: CollectionViewLayoutMeasuring?) {
		self.layoutMeasure = layoutMeasure
	}
	
	open var collectionViewSize = CGSize.zero
	
	open var width: CGFloat = 0
	
	open var height: CGFloat = 0
	
	open var heightAvailableForPlaceholders: CGFloat = 0
	
	open var contentOffset = CGPoint.zero
	
	open var contentInset = UIEdgeInsets.zero
	
	open var bounds = CGRect.zero
	
	open weak var layout: CollectionViewLayout?
	
	open weak var layoutMeasure: CollectionViewLayoutMeasuring?
	
	open var isEditing = false
	
	open var numberOfSections: Int {
		return localSections.count
	}
	
	open var hasGlobalSection: Bool {
		return globalSection != nil
	}
	
	open var sections: [LayoutSection] {
		var sections = localSections
		if let globalSection = self.globalSection {
			sections.insert(globalSection, at: 0)
		}
		return sections
	}
	
	fileprivate var localSections: [LayoutSection] = []
	
	fileprivate var globalSection: LayoutSection?
	
	fileprivate var numberOfPlaceholders = 0
	
	open func copy() -> BasicLayoutInfo {
		let copy = BasicLayoutInfo(layoutMeasure: layoutMeasure)
		
		copy.width = width
		copy.height = height
		copy.contentOffset = contentOffset
		
		return copy
	}
	
	open func enumerateSections(_ block: (_ sectionIndex: Int, _ sectionInfo: inout LayoutSection, _ stop: inout Bool) -> Void) {
		var stop = false
		if var globalSection = self.globalSection {
			block(globalSectionIndex, &globalSection, &stop)
			self.globalSection = globalSection
		}
		
		guard !stop else {
			return
		}
		
		for sectionIndex in localSections.indices {
			block(sectionIndex, &localSections[sectionIndex], &stop)
			
			if stop {
				return
			}
		}
	}
	
	open func add(_ section: LayoutSection, sectionIndex: Int) {
		var section = section
		section.sectionIndex = sectionIndex
		
		if sectionIndex == globalSectionIndex {
			globalSection = section
		} else {
			precondition(sectionIndex == localSections.count, "Number of sections out-of-sync with the section index")
			localSections.insert(section, at: sectionIndex)
		}
	}
	
	open func mutateSection(at index: Int, using mutator: (inout LayoutSection) -> Void) {
		var section = sections[index]
		mutator(&section)
		setSection(section, at: index)
	}
	
	open func mutateItem(at indexPath: IndexPath, using mutator: (inout LayoutItem) -> Void) {
		mutateSection(at: indexPath.section) { (section) in
			section.mutateItem(at: indexPath.item, using: mutator)
		}
	}
	
	open func newPlaceholderStartingAtSectionIndex(_ sectionIndex: Int) -> LayoutPlaceholder {
		let placeholder = BasicLayoutPlaceholder(sectionIndexes: IndexSet(integer: sectionIndex))
		numberOfPlaceholders += 1
		return placeholder
	}
	
	open func sectionAtIndex(_ sectionIndex: Int) -> LayoutSection? {
		if sectionIndex == globalSectionIndex {
			return globalSection
		}
		
		guard (0..<numberOfSections).contains(sectionIndex) else {
			return nil
		}
		
		return localSections[sectionIndex]
	}
	
	open func setSection(_ section: LayoutSection, at sectionIndex: Int) {
		if sectionIndex == globalSectionIndex {
			globalSection = section
		}
		
		guard (0..<numberOfSections).contains(sectionIndex) else {
			return
		}
		
		localSections[sectionIndex] = section
	}
	
	open func invalidate() {
		globalSection = nil
		localSections.removeAll(keepingCapacity: true)
	}
	
	open func prepareForLayout() {
		enumerateSections { (_, sectionInfo, _) in
			sectionInfo.prepareForLayout()
		}
	}
	
	open func finalizeLayout() {
		var sectionsWithContent: [LayoutSection] = []
		
		for sectionInfo in sections {
			if sectionInfo.isGlobalSection {
				continue
			}
			
			if let placeholderInfo = sectionInfo.placeholderInfo, placeholderInfo.shouldFillAvailableHeight {
				// If there's a placeholder and it didn't start here or end here, there's no content to worry about, because we're not going to show the items or any supplementary elements
				if placeholderInfo.startingSectionIndex != sectionInfo.sectionIndex
					&& placeholderInfo.endingSectionIndex != sectionInfo.sectionIndex {
						continue
				}
				
				if placeholderInfo.startingSectionIndex == sectionInfo.sectionIndex {
					let indexPath = IndexPath(item: 0, section: sectionInfo.sectionIndex)
					setSize(placeholderInfo.frame.size, forElementOfKind: collectionElementKindPlaceholder, at: indexPath)
				}
			}
			
			if sectionInfo.items.count > 0 {
				sectionsWithContent.append(sectionInfo)
				continue
			}
			
			// There are no items, need to determine if there are any supplementary elements that will be displayed
			for supplementaryItem in sectionInfo.supplementaryItems {
				guard sectionInfo.shouldShow(supplementaryItem) && !supplementaryItem.isHidden && supplementaryItem.height != 0 else {
					continue
				}
				sectionsWithContent.append(sectionInfo)
			}
		}
		
		// Now go back through all the sections and ask them to finalize their layout
		enumerateSections { (_, sectionInfo, _) in
			sectionInfo.finalizeLayoutAttributesForSectionsWithContent(sectionsWithContent)
		}
	}
	
	open func setSize(_ size: CGSize, forItemAt indexPath: IndexPath, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) {
		let sectionIndex = indexPath.section
		
		let offset = localSections[sectionIndex].setSize(size, forItemAt: indexPath.item, invalidationContext: invalidationContext)
		
		offsetSections(afterSectionAt: sectionIndex, by: offset, invalidationContext: invalidationContext)
	}
	
	open func setSize(_ size: CGSize, forElementOfKind kind: String, at indexPath: IndexPath, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) {
		let sectionIndex = indexPath.layoutSection
		let itemIndex = indexPath.itemIndex
		
		let offset: CGPoint
		if kind == collectionElementKindPlaceholder {
			offset = setSize(size, forPlaceholderAt: sectionIndex, invalidationContext: invalidationContext)
		}
		else if var sectionInfo = sectionAtIndex(sectionIndex) {
			offset = sectionInfo.setSize(size, forSupplementaryElementOfKind: kind, at: itemIndex, invalidationContext: invalidationContext)
			setSection(sectionInfo, at: sectionIndex)
		}
		else {
			offset = CGPoint.zero
		}
		
		offsetSections(afterSectionAt: sectionIndex, by: offset, invalidationContext: invalidationContext)
		invalidationContext?.contentSizeAdjustment = CGSize(width: offset.x, height: offset.y)
	}
	
	fileprivate func offsetSections(afterSectionAt sectionIndex: Int, by offset: CGPoint,  invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) {
		var sectionIndex = sectionIndex
		if sectionIndex == globalSectionIndex {
			sectionIndex = 0
		} else {
			sectionIndex += 1
		}
		
		// FIXME: Is this correct?
		for index in sectionIndex..<numberOfSections {
			var sectionInfo = localSections[index]
			let sectionFrame = sectionInfo.frame.offsetBy(dx: offset.x, dy: offset.y)
			sectionInfo.setFrame(sectionFrame, invalidationContext: invalidationContext)
			
			// Move placeholder that happens to start at this section index
			if var placeholderInfo = sectionInfo.placeholderInfo, placeholderInfo.startingSectionIndex == index {
				
				let placeholderFrame = placeholderInfo.frame.offsetBy(dx: offset.x, dy: offset.y)
				placeholderInfo.setFrame(placeholderFrame, invalidationContext: invalidationContext)
				sectionInfo.placeholderInfo = placeholderInfo
			}
			
			setSection(sectionInfo, at: index)
		}
	}
	
	fileprivate func setSize(_ size: CGSize, forPlaceholderAt sectionIndex: Int, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) -> CGPoint {
		guard var section = sectionAtIndex(sectionIndex), section.shouldResizePlaceholder,
			var placeholderInfo = section.placeholderInfo else {
				return CGPoint.zero
		}
		var frame = placeholderInfo.frame
		
		let sharedHeight = heightAvailableForPlaceholders / CGFloat(numberOfPlaceholders)
		var deltaY = size.height - frame.height
		
		if sharedHeight > 0 {
			deltaY += sharedHeight
		}
		
		frame.size.height += deltaY
		
		if deltaY > 0 {
			placeholderInfo.setFrame(frame, invalidationContext: invalidationContext)
			section.placeholderInfo = placeholderInfo
			setSection(section, at: sectionIndex)
		}
		return CGPoint(x: 0, y: deltaY)
	}
	
	open func updateSpecialItemsWithContentOffset(_ contentOffset: CGPoint, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) {
		enumerateSections { (_, section, _) in
			section.updateSpecialItemsWithContentOffset(contentOffset, layoutInfo: self,  invalidationContext: invalidationContext)
		}
	}
	
	open func layoutAttributesForCell(at indexPath: IndexPath) -> CollectionViewLayoutAttributes? {
		let sectionIndex = indexPath.layoutSection
		let sectionInfo = sectionAtIndex(sectionIndex)
		return sectionInfo?.layoutAttributesForCell(at: indexPath)
	}
	
	open func layoutAttributesForDecorationViewOfKind(_ kind: String, at indexPath: IndexPath) -> CollectionViewLayoutAttributes? {
		let sectionIndex = indexPath.layoutSection
		let sectionInfo = sectionAtIndex(sectionIndex)
		return sectionInfo?.layoutAttributesForDecorationViewOfKind(kind, at: indexPath)
	}
	
	open func layoutAttributesForSupplementaryElementOfKind(_ kind: String, at indexPath: IndexPath) -> CollectionViewLayoutAttributes? {
		let sectionIndex = indexPath.layoutSection
		let sectionInfo = sectionAtIndex(sectionIndex)
		return sectionInfo?.layoutAttributesForSupplementaryElementOfKind(kind, at: indexPath)
	}
	
}
