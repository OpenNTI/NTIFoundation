//
//  BasicLayoutInfo.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/18/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public class BasicLayoutInfo: LayoutInfo {
	
	public init(layoutMeasure: CollectionViewLayoutMeasuring?) {
		self.layoutMeasure = layoutMeasure
	}
	
	public var collectionViewSize = CGSizeZero
	
	public var width: CGFloat = 0
	
	public var height: CGFloat = 0
	
	public var heightAvailableForPlaceholders: CGFloat = 0
	
	public var contentOffset = CGPointZero
	
	public var contentInset = UIEdgeInsetsZero
	
	public var bounds = CGRectZero
	
	public weak var layout: CollectionViewLayout?
	
	public weak var layoutMeasure: CollectionViewLayoutMeasuring?
	
	public var isEditing = false
	
	public var numberOfSections: Int {
		return localSections.count
	}
	
	public var hasGlobalSection: Bool {
		return globalSection != nil
	}
	
	public var sections: [LayoutSection] {
		var sections = localSections
		if let globalSection = self.globalSection {
			sections.insert(globalSection, atIndex: 0)
		}
		return sections
	}
	
	private var localSections: [LayoutSection] = []
	
	private var globalSection: LayoutSection?
	
	private var numberOfPlaceholders = 0
	
	public func copy() -> BasicLayoutInfo {
		let copy = BasicLayoutInfo(layoutMeasure: layoutMeasure)
		
		copy.width = width
		copy.height = height
		copy.contentOffset = contentOffset
		
		return copy
	}
	
	public func enumerateSections(block: (sectionIndex: Int, inout sectionInfo: LayoutSection, stop: inout Bool) -> Void) {
		var stop = false
		if var globalSection = self.globalSection {
			block(sectionIndex: globalSectionIndex, sectionInfo: &globalSection, stop: &stop)
			self.globalSection = globalSection
		}
		
		guard !stop else {
			return
		}
		
		for sectionIndex in localSections.indices {
			block(sectionIndex: sectionIndex, sectionInfo: &localSections[sectionIndex], stop: &stop)
			
			if stop {
				return
			}
		}
	}
	
	public func add(section: LayoutSection, sectionIndex: Int) {
		var section = section
		section.sectionIndex = sectionIndex
		
		if sectionIndex == globalSectionIndex {
			globalSection = section
		} else {
			precondition(sectionIndex == localSections.count, "Number of sections out-of-sync with the section index")
			localSections.insert(section, atIndex: sectionIndex)
		}
	}
	
	public func mutateSection(at index: Int, using mutator: (inout LayoutSection) -> Void) {
		var section = sections[index]
		mutator(&section)
		setSection(section, at: index)
	}
	
	public func mutateItem(at indexPath: NSIndexPath, using mutator: (inout LayoutItem) -> Void) {
		mutateSection(at: indexPath.section) { (section) in
			section.mutateItem(at: indexPath.item, using: mutator)
		}
	}
	
	public func newPlaceholderStartingAtSectionIndex(sectionIndex: Int) -> LayoutPlaceholder {
		let placeholder = BasicLayoutPlaceholder(sectionIndexes: NSIndexSet(index: sectionIndex))
		numberOfPlaceholders += 1
		return placeholder
	}
	
	public func sectionAtIndex(sectionIndex: Int) -> LayoutSection? {
		if sectionIndex == globalSectionIndex {
			return globalSection
		}
		
		guard (0..<numberOfSections).contains(sectionIndex) else {
			return nil
		}
		
		return localSections[sectionIndex]
	}
	
	public func setSection(section: LayoutSection, at sectionIndex: Int) {
		if sectionIndex == globalSectionIndex {
			globalSection = section
		}
		
		guard (0..<numberOfSections).contains(sectionIndex) else {
			return
		}
		
		localSections[sectionIndex] = section
	}
	
	public func invalidate() {
		globalSection = nil
		localSections.removeAll(keepCapacity: true)
	}
	
	public func prepareForLayout() {
		enumerateSections { (_, sectionInfo, _) in
			sectionInfo.prepareForLayout()
		}
	}
	
	public func finalizeLayout() {
		var sectionsWithContent: [LayoutSection] = []
		
		for sectionInfo in sections {
			if sectionInfo.isGlobalSection {
				continue
			}
			
			if let placeholderInfo = sectionInfo.placeholderInfo where placeholderInfo.shouldFillAvailableHeight {
				// If there's a placeholder and it didn't start here or end here, there's no content to worry about, because we're not going to show the items or any supplementary elements
				if placeholderInfo.startingSectionIndex != sectionInfo.sectionIndex
					&& placeholderInfo.endingSectionIndex != sectionInfo.sectionIndex {
						continue
				}
				
				if placeholderInfo.startingSectionIndex == sectionInfo.sectionIndex {
					let indexPath = NSIndexPath(forItem: 0, inSection: sectionInfo.sectionIndex)
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
	
	public func setSize(size: CGSize, forItemAt indexPath: NSIndexPath, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) {
		let sectionIndex = indexPath.section
		
		let offset = localSections[sectionIndex].setSize(size, forItemAt: indexPath.item, invalidationContext: invalidationContext)
		
		offsetSections(afterSectionAt: sectionIndex, by: offset, invalidationContext: invalidationContext)
	}
	
	public func setSize(size: CGSize, forElementOfKind kind: String, at indexPath: NSIndexPath, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) {
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
			offset = CGPointZero
		}
		
		offsetSections(afterSectionAt: sectionIndex, by: offset, invalidationContext: invalidationContext)
		invalidationContext?.contentSizeAdjustment = CGSize(width: offset.x, height: offset.y)
	}
	
	private func offsetSections(afterSectionAt sectionIndex: Int, by offset: CGPoint,  invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) {
		var sectionIndex = sectionIndex
		if sectionIndex == globalSectionIndex {
			sectionIndex = 0
		} else {
			sectionIndex += 1
		}
		
		// FIXME: Is this correct?
		for index in sectionIndex..<numberOfSections {
			var sectionInfo = localSections[index]
			let sectionFrame = CGRectOffset(sectionInfo.frame, offset.x, offset.y)
			sectionInfo.setFrame(sectionFrame, invalidationContext: invalidationContext)
			
			// Move placeholder that happens to start at this section index
			if var placeholderInfo = sectionInfo.placeholderInfo
				where placeholderInfo.startingSectionIndex == index {
				
				let placeholderFrame = CGRectOffset(placeholderInfo.frame, offset.x, offset.y)
				placeholderInfo.setFrame(placeholderFrame, invalidationContext: invalidationContext)
				sectionInfo.placeholderInfo = placeholderInfo
			}
			
			setSection(sectionInfo, at: index)
		}
	}
	
	private func setSize(size: CGSize, forPlaceholderAt sectionIndex: Int, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) -> CGPoint {
		guard var section = sectionAtIndex(sectionIndex) where section.shouldResizePlaceholder,
			var placeholderInfo = section.placeholderInfo else {
				return CGPointZero
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
		return CGPointMake(0, deltaY)
	}
	
	public func updateSpecialItemsWithContentOffset(contentOffset: CGPoint, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) {
		enumerateSections { (_, section, _) in
			section.updateSpecialItemsWithContentOffset(contentOffset, layoutInfo: self,  invalidationContext: invalidationContext)
		}
	}
	
	public func layoutAttributesForCell(at indexPath: NSIndexPath) -> CollectionViewLayoutAttributes? {
		let sectionIndex = indexPath.layoutSection
		let sectionInfo = sectionAtIndex(sectionIndex)
		return sectionInfo?.layoutAttributesForCell(at: indexPath)
	}
	
	public func layoutAttributesForDecorationViewOfKind(kind: String, at indexPath: NSIndexPath) -> CollectionViewLayoutAttributes? {
		let sectionIndex = indexPath.layoutSection
		let sectionInfo = sectionAtIndex(sectionIndex)
		return sectionInfo?.layoutAttributesForDecorationViewOfKind(kind, at: indexPath)
	}
	
	public func layoutAttributesForSupplementaryElementOfKind(kind: String, at indexPath: NSIndexPath) -> CollectionViewLayoutAttributes? {
		let sectionIndex = indexPath.layoutSection
		let sectionInfo = sectionAtIndex(sectionIndex)
		return sectionInfo?.layoutAttributesForSupplementaryElementOfKind(kind, at: indexPath)
	}
	
}
