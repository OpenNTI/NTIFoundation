//
//  BasicLayoutInfo.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/18/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public class BasicLayoutInfo: NSObject, LayoutInfo, NSCopying {
	
	public init(layout: CollectionViewLayout?) {
		super.init()
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
	
	public func copyWithZone(zone: NSZone) -> AnyObject {
		let copy = BasicLayoutInfo(layout: layout)
		
		copy.width = width
		copy.height = height
		copy.contentOffset = contentOffset
		
		return copy
	}
	
	public func enumerateSections(block: (sectionIndex: Int, sectionInfo: LayoutSection, stop: inout Bool) -> Void) {
		var stop = false
		if let globalSection = self.globalSection {
			block(sectionIndex: GlobalSectionIndex, sectionInfo: globalSection, stop: &stop)
		}
		
		guard !stop else {
			return
		}
		
		for (sectionIndex, sectionInfo) in _sections.enumerate() {
			block(sectionIndex: sectionIndex, sectionInfo: sectionInfo, stop: &stop)
			if stop {
				return
			}
		}
	}
	
	public func add(section: LayoutSection, sectionIndex: Int) {
		section.layoutInfo = self
		section.sectionIndex = sectionIndex
		if sectionIndex == GlobalSectionIndex {
			globalSection = section
		} else {
			precondition(sectionIndex == _sections.count, "Number of sections out-of-sync with the section index")
			_sections.insert(section, atIndex: sectionIndex)
		}
	}
	
	// This isn't currently being called -- see FIXME
//	public func newSection(sectionIndex index: Int) -> LayoutSection {
//		// FIXME: The type of section should be determined elsewhere
//		let section = AbstractLayoutSection()
//		add(section, sectionIndex: index)
//		return section
//	}
	
	public func newPlaceholderStartingAtSectionIndex(sectionIndex: Int) -> LayoutPlaceholder {
		let placeholder = BasicLayoutPlaceholder(sectionIndexes: NSIndexSet(index: sectionIndex))
		numberOfPlaceholders += 1
		return placeholder
	}
	
	public func sectionAtIndex(sectionIndex: Int) -> LayoutSection? {
		if sectionIndex == GlobalSectionIndex {
			return globalSection
		}
		guard (0..<numberOfSections).contains(sectionIndex) else {
			return nil
		}
		return _sections[sectionIndex]
	}
	
	public func invalidate() {
		globalSection = nil
		_sections.removeAll(keepCapacity: true)
	}
	
	public func prepareForLayout() {
		for section in sections {
			section.prepareForLayout()
		}
	}
	
	public func finalizeLayout() {
		let sectionsWithContent = NSMutableIndexSet()
		
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
					setSize(placeholderInfo.frame.size, forElementOfKind: CollectionElementKindPlaceholder, at: indexPath)
				}
			}
			
			if sectionInfo.items.count > 0 {
				sectionsWithContent.addIndex(sectionInfo.sectionIndex)
				continue
			}
			
			// There are no items, need to determine if there are any supplementary elements that will be displayed
			for supplementaryItem in sectionInfo.supplementaryItems {
				guard supplementaryItem.isVisibleWhileShowingPlaceholder && !supplementaryItem.isHidden && supplementaryItem.height != 0 else {
					continue
				}
				sectionsWithContent.addIndex(sectionInfo.sectionIndex)
			}
		}
		
		// Now go back through all the sections and ask them to finalize their layout
		for sectionInfo in sections {
			sectionInfo.finalizeLayoutAttributesForSectionsWithContent(sectionsWithContent)
		}
	}
	
	public func setSize(size: CGSize, forItemAt indexPath: NSIndexPath, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) {
		let sectionIndex = indexPath.section
		let sectionInfo = _sections[sectionIndex]
		
		let offset = sectionInfo.setSize(size, forItemAt: indexPath.item, invalidationContext: invalidationContext)
		offsetSections(afterSectionAt: sectionIndex, by: offset, invalidationContext: invalidationContext)
	}
	
	public func setSize(size: CGSize, forElementOfKind kind: String, at indexPath: NSIndexPath, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) {
		let sectionIndex = indexPath.layoutSection
		let itemIndex = indexPath.itemIndex
		let sectionInfo = sectionAtIndex(sectionIndex)
		
		let offset: CGPoint
		if kind == CollectionElementKindPlaceholder {
			offset = setSize(size, forPlaceholderAt: sectionIndex, invalidationContext: invalidationContext)
		} else {
			offset = sectionInfo?.setSize(size, forSupplementaryElementOfKind: kind, at: itemIndex, invalidationContext: invalidationContext) ?? CGPointZero
		}
		
		offsetSections(afterSectionAt: sectionIndex, by: offset, invalidationContext: invalidationContext)
		invalidationContext?.contentSizeAdjustment = CGSize(width: offset.x, height: offset.y)
	}
	
	private func offsetSections(afterSectionAt sectionIndex: Int, by offset: CGPoint,  invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) {
		var sectionIndex = sectionIndex
		if sectionIndex == GlobalSectionIndex {
			sectionIndex = 0
		} else {
			sectionIndex += 1
		}
		
		for _ in sectionIndex..<numberOfSections {
			let sectionInfo = sections[sectionIndex]
			let sectionFrame = CGRectOffset(sectionInfo.frame, offset.x, offset.y)
			sectionInfo.setFrame(sectionFrame, invalidationContext: invalidationContext)
			
			// Move placeholder that happens to start at this section index
			if let placeholderInfo = sectionInfo.placeholderInfo
				where placeholderInfo.startingSectionIndex == sectionIndex {
					let placeholderFrame = CGRectOffset(placeholderInfo.frame, offset.x, offset.y)
					placeholderInfo.setFrame(placeholderFrame, invalidationContext: invalidationContext)
			}
		}
	}
	
	private func setSize(size: CGSize, forPlaceholderAt sectionIndex: Int, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) -> CGPoint {
		guard let placeholderInfo = sectionAtIndex(sectionIndex)?.placeholderInfo else {
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
		}
		return CGPointMake(0, deltaY)
	}
	
	public func updateSpecialItemsWithContentOffset(contentOffset: CGPoint, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) {
		for section in sections {
			section.updateSpecialItemsWithContentOffset(contentOffset, invalidationContext: invalidationContext)
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
	
	public func layoutAttributesForCell(at indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
		let sectionIndex = indexPath.layoutSection
		let sectionInfo = sectionAtIndex(sectionIndex)
		return sectionInfo?.layoutAttributesForCell(at: indexPath)
	}
	
	public func layoutAttributesForDecorationViewOfKind(kind: String, at indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
		let sectionIndex = indexPath.layoutSection
		let sectionInfo = sectionAtIndex(sectionIndex)
		return sectionInfo?.layoutAttributesForDecorationViewOfKind(kind, at: indexPath)
	}
	
	public func layoutAttributesForSupplementaryElementOfKind(kind: String, at indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
		let sectionIndex = indexPath.layoutSection
		let sectionInfo = sectionAtIndex(sectionIndex)
		return sectionInfo?.layoutAttributesForSupplementaryElementOfKind(kind, at: indexPath)
	}
	
}
