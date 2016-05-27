//
//  BasicLayoutInfo.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/18/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public class BasicLayoutInfo: LayoutInfo {
	
	public init(layout: CollectionViewLayout?) {
		self.layout = layout
	}
	
	public var collectionViewSize = CGSizeZero
	
	public var width: CGFloat = 0
	
	public var height: CGFloat = 0
	
	public var heightAvailableForPlaceholders: CGFloat = 0
	
	public var contentOffset = CGPointZero
	
	public var contentInset = UIEdgeInsetsZero
	
	public var bounds = CGRectZero
	
	public weak var layout: CollectionViewLayout?
	
	public var layoutMeasure: CollectionViewLayoutMeasuring? {
		return layout
	}
	
	public var isEditing: Bool {
		return layout?.isEditing ?? false
	}
	
	public var numberOfSections: Int {
		return _sections.count
	}
	
	public var hasGlobalSection: Bool {
		return globalSection != nil
	}
	
	public var sections: [LayoutSection] {
		var sections = _sections
		if let globalSection = self.globalSection {
			sections.insert(globalSection, atIndex: 0)
		}
		return sections
	}
	
	private var _sections: [LayoutSection] = []
	
	private var globalSection: LayoutSection?
	
	private var numberOfPlaceholders = 0
	
	public func copy() -> BasicLayoutInfo {
		let copy = BasicLayoutInfo(layout: layout)
		
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
		
		for sectionIndex in _sections.indices {
			block(sectionIndex: sectionIndex, sectionInfo: &_sections[sectionIndex], stop: &stop)
			
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
			precondition(sectionIndex == _sections.count, "Number of sections out-of-sync with the section index")
			_sections.insert(section, atIndex: sectionIndex)
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
		
		return _sections[sectionIndex]
	}
	
	public func setSection(section: LayoutSection, at sectionIndex: Int) {
		if sectionIndex == globalSectionIndex {
			globalSection = section
		}
		
		guard (0..<numberOfSections).contains(sectionIndex) else {
			return
		}
		
		_sections[sectionIndex] = section
	}
	
	public func invalidate() {
		globalSection = nil
		_sections.removeAll(keepCapacity: true)
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
			
			if let placeholderInfo = sectionInfo.placeholderInfo {
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
				guard supplementaryItem.isVisibleWhileShowingPlaceholder && !supplementaryItem.isHidden && supplementaryItem.height != 0 else {
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
		
		let offset = _sections[sectionIndex].setSize(size, forItemAt: indexPath.item, invalidationContext: invalidationContext)
		
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
		for _ in sectionIndex..<numberOfSections {
			var sectionInfo = sections[sectionIndex]
			let sectionFrame = CGRectOffset(sectionInfo.frame, offset.x, offset.y)
			sectionInfo.setFrame(sectionFrame, invalidationContext: invalidationContext)
			
			// Move placeholder that happens to start at this section index
			if var placeholderInfo = sectionInfo.placeholderInfo
				where placeholderInfo.startingSectionIndex == sectionIndex {
				
				let placeholderFrame = CGRectOffset(placeholderInfo.frame, offset.x, offset.y)
				placeholderInfo.setFrame(placeholderFrame, invalidationContext: invalidationContext)
				sectionInfo.placeholderInfo = placeholderInfo
			}
			
			setSection(sectionInfo, at: sectionIndex)
		}
	}
	
	private func setSize(size: CGSize, forPlaceholderAt sectionIndex: Int, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) -> CGPoint {
		guard var section = sectionAtIndex(sectionIndex),
			var placeholderInfo = section.placeholderInfo else {
				return CGPointZero
		}
		var frame = placeholderInfo.frame
		
		let sharedHeight = heightAvailableForPlaceholders / CGFloat(numberOfPlaceholders)
		var deltaY = size.height - frame.height
		
		if sharedHeight > 0 {
			deltaY = size.height + sharedHeight - frame.height
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
	
	public func invalidateMetricsForItemAt(indexPath: NSIndexPath, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) {
		guard let cell = layout?.collectionView?.cellForItemAtIndexPath(indexPath) else {
			return
		}
		
		let attributes = layoutAttributesForCell(at: indexPath)?.copy() as! UICollectionViewLayoutAttributes
		if let attributes = attributes as? CollectionViewLayoutAttributes {
			attributes.shouldCalculateFittingSize = true
		}
		
		let newAttributes = cell.preferredLayoutAttributesFittingAttributes(attributes)
		guard newAttributes.frame.size != attributes.frame.size else {
			return
		}
		
		setSize(newAttributes.frame.size, forItemAt: indexPath, invalidationContext: invalidationContext)
	}
	
	public func invalidateMetricsForElementOfKind(kind: String, at indexPath: NSIndexPath, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) {
		guard let view = layout?.collectionView?._supplementaryViewOfKind(kind, at: indexPath) else {
			return
		}
		
		let attributes = layoutAttributesForSupplementaryElementOfKind(kind, at: indexPath)?.copy() as! UICollectionViewLayoutAttributes
		if let attributes = attributes as? CollectionViewLayoutAttributes {
			attributes.shouldCalculateFittingSize = true
		}
		
		let newAttributes = view.preferredLayoutAttributesFittingAttributes(attributes)
		guard newAttributes.frame.size != attributes.frame.size else {
			return
		}
		
		setSize(newAttributes.frame.size, forElementOfKind: kind, at: indexPath, invalidationContext: invalidationContext)
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
