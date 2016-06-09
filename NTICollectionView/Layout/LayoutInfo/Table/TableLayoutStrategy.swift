//
//  TableLayoutStrategy.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 6/9/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public struct TableLayoutStrategy : LayoutStrategy {
	
	public func makePlaceholder(startingAtSectionIndex index: Int, inout for data: LayoutData) -> LayoutPlaceholder {
		let placeholder = BasicLayoutPlaceholder(sectionIndexes: NSIndexSet(index: index))
		data.numberOfPlaceholders += 1
		return placeholder
	}
	
	public func finalizeLayout(inout for data: LayoutData) {
		let indicesOfSectionsWithContent = NSMutableIndexSet()
		
		for section in data.sections {
			let sectionIndex = section.sectionIndex
			
			if let placeholder = section.placeholderInfo where placeholder.shouldFillAvailableHeight {
				
				// If there's a placeholder and it didn't start here or end here, there's no content to worry about, because we're not going to show the items or any supplementary elements
				if placeholder.startingSectionIndex != sectionIndex
					&& placeholder.endingSectionIndex != sectionIndex {
					continue
				}
				
				if placeholder.startingSectionIndex == sectionIndex {
					let indexPath = NSIndexPath(forItem: 0, inSection: sectionIndex)
					setSize(placeholder.frame.size, forElementOfKind: collectionElementKindPlaceholder, at: indexPath, in: &data)
				}
			}
			
			if section.items.count > 0 {
				indicesOfSectionsWithContent.addIndex(sectionIndex)
				continue
			}
			
			// There are no items, need to determine if there are any supplementary elements that will be displayed
			if section.supplementaryItems.contains({ section.shouldShow($0) }) {
				indicesOfSectionsWithContent.addIndex(sectionIndex)
			}
		}
		
		// Now go back through all the sections and ask them to finalize their layout
		for (index, section) in data.sections.enumerate() {
			let sectionsWithContent = indicesOfSectionsWithContent.map { data.sections[$0] }
			
			var section = section
			section.finalizeLayoutAttributesForSectionsWithContent(sectionsWithContent)
			data.sections[index] = section
		}
	}
	
	public func setSize(size: CGSize, forItemAt indexPath: NSIndexPath, inout in data: LayoutData, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) {
		let itemIndex = indexPath.item
		let sectionIndex = indexPath.section
		
		let offset = data.sections[sectionIndex].setSize(size, forItemAt: itemIndex, invalidationContext: invalidationContext)
		
		offsetSections(afterSectionAtIndex: sectionIndex, in: &data, by: offset, invalidationContext: invalidationContext)
		invalidationContext?.contentSizeAdjustment = CGSize(width: offset.x, height: offset.y)
	}
	
	public func setSize(size: CGSize, forElementOfKind kind: String, at indexPath: NSIndexPath, inout in data: LayoutData, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) {
		let sectionIndex = indexPath.layoutSection
		let itemIndex = indexPath.itemIndex
		
		var offset = CGPointZero
		if kind == collectionElementKindPlaceholder {
			setSize(size, forPlaceholderAtSectionIndex: sectionIndex, in: &data, resultingOffset: &offset)
		}
		else {
			offset = data.sections[sectionIndex].setSize(size, forSupplementaryElementOfKind: kind, at: itemIndex, invalidationContext: nil)
		}
		
		offsetSections(afterSectionAtIndex: sectionIndex, in: &data, by: offset, invalidationContext: invalidationContext)
		invalidationContext?.contentSizeAdjustment = CGSize(width: offset.x, height: offset.y)
	}
	
	private func offsetSections(afterSectionAtIndex sectionIndex: Int, inout in data: LayoutData, by offset: CGPoint, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) {
		var sectionIndex = sectionIndex
		if sectionIndex == globalSectionIndex {
			sectionIndex = 0
		} else {
			sectionIndex += 1
		}
		
		for index in sectionIndex..<data.sections.count {
			var section = data.sections[index]
			let sectionFrame = CGRectOffset(section.frame, offset.x, offset.y)
			section.setFrame(sectionFrame, invalidationContext: invalidationContext)
			
			// Move placeholder that happens to start at this section index
			if var placeholder = section.placeholderInfo where placeholder.startingSectionIndex == index {
				let placeholderFrame = CGRectOffset(placeholder.frame, offset.x, offset.y)
				placeholder.setFrame(placeholderFrame, invalidationContext: invalidationContext)
				section.placeholderInfo = placeholder
			}
			
			data.sections[index] = section
		}
	}
	
	private func setSize(size: CGSize, forPlaceholderAtSectionIndex sectionIndex: Int, inout in data: LayoutData, inout resultingOffset: CGPoint, context: UICollectionViewLayoutInvalidationContext? = nil) {
		var section = data.sections[sectionIndex]
		guard section.shouldResizePlaceholder, var placeholder = section.placeholderInfo else {
			return
		}
		
		var frame = placeholder.frame
		
		let viewHeight = data.viewBounds.height - data.contentInset.height
		let layoutHeight = data.layoutSize.height
		let heightAvailableForPlaceholders = max(0, viewHeight - layoutHeight)
		
		let sharedHeight = heightAvailableForPlaceholders / CGFloat(data.numberOfPlaceholders)
		var deltaY = size.height - frame.height
		
		if sharedHeight > 0 {
			deltaY += sharedHeight
		}
		
		frame.size.height += deltaY
		
		if deltaY > 0 {
			placeholder.setFrame(frame, invalidationContext: context)
			section.placeholderInfo = placeholder
			data.sections[sectionIndex] = section
		}
		
		resultingOffset.y += deltaY
	}
	
}
