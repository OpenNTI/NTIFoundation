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
	
	public func targetLayoutHeight(forProposedLayoutHeight proposed: CGFloat, using data: LayoutData) -> CGFloat {
		guard let globalSection = data.globalSection else {
			return proposed
		}
		
		let height = data.viewBounds.height - data.contentInset.height
		
		let globalNonPinningHeight = self.height(of: headers(pinnable: false, in: globalSection))
		
		if data.contentOffset.y >= globalNonPinningHeight && proposed - globalNonPinningHeight < height {
			return height + globalNonPinningHeight
		}
		
		return proposed
	}
	
	private func height(of supplementaryItems: [LayoutSupplementaryItem]) -> CGFloat {
		guard !supplementaryItems.isEmpty else {
			return 0
		}
		var minY = CGFloat.max
		var maxY = CGFloat.min
		
		for supplementaryItem in supplementaryItems {
			let frame = supplementaryItem.frame
			minY = min(minY, frame.minY)
			maxY = max(maxY, frame.maxY)
		}
		
		return maxY - minY
	}
	
	public func updateSpecialItems(withContentOffset offset: CGPoint, inout in data: LayoutData, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		var pinnableY = offset.y + data.contentInset.top
		var nonPinnableY = pinnableY
		
		for index in data.sections.indices {
			resetHeaders(pinnable: true, in: &data.sections[index], invalidationContext: invalidationContext)
		}
		
		guard var globalSection = data.globalSection else {
			return
		}
		
		resetHeaders(pinnable: true, in: &globalSection, invalidationContext: invalidationContext)
		
		applyTopPinningToPinnableHeaders(in: &globalSection, minY: &pinnableY, invalidationContext: invalidationContext)
		
		finalizePinningForHeaders(pinnable: true, in: &globalSection, zIndex: pinnedHeaderZIndex)
		
		let nonPinnableHeaders = headers(pinnable: false, in: globalSection)
		
		resetHeaders(pinnable: false, in: &globalSection, invalidationContext: invalidationContext)
		
		applyBottomPinningToNonPinnableHeaders(in: &globalSection, maxY: &nonPinnableY, invalidationContext: invalidationContext)
		
		finalizePinningForHeaders(pinnable: false, in: &globalSection, zIndex: pinnedHeaderZIndex)
		
		if var backgroundDecoration = globalSection.decorationsByKind[collectionElementKindGlobalHeaderBackground]?.first {
			var frame = backgroundDecoration.frame
			frame.origin.y = min(nonPinnableY, data.viewBounds.minY)
			
			let pinnableHeaders = headers(pinnable: true, in: globalSection)
			let bottomY = max(pinnableHeaders.last?.frame.maxY ?? 0, nonPinnableHeaders.last?.frame.maxY ?? 0)
			frame.size.height = bottomY - frame.minY
			
			backgroundDecoration.setContainerFrame(frame, invalidationContext: nil)
			globalSection.decorationsByKind[collectionElementKindGlobalHeaderBackground]![0] = backgroundDecoration
		}
		
		// Find the first section overlapping pinnableY
		for (index, section) in data.sections.enumerate() {
			let frame = section.frame
			
			guard frame.minY <= pinnableY && pinnableY <= frame.maxY else {
				continue
			}
			
			var section = section
			
			applyTopPinningToPinnableHeaders(in: &section, minY: &pinnableY, invalidationContext: invalidationContext)
			
			// FIXME: Magic number
			finalizePinningForHeaders(pinnable: true, in: &section, zIndex: pinnedHeaderZIndex - 100)
			
			data.sections[index] = section
			
			break
		}
		
		data.globalSection = globalSection
	}
	
	private func resetHeaders(pinnable pinnable: Bool, inout in section: LayoutSection, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		guard var headers = section.supplementaryItemsByKind[UICollectionElementKindSectionHeader] else {
			return
		}
		
		for (index, header) in headers.enumerate() where header.shouldPin == pinnable {
			guard var header = header as? TableLayoutSupplementaryItem else {
				continue
			}
			
			var frame = header.frame
			
			if frame.minY != header.unpinnedY {
				invalidationContext?.invalidate(header)
			}
			
			header.isPinned = false
			
			frame.origin.y = header.unpinnedY
			header.frame = frame
			
			headers[index] = header
		}
		
		section.supplementaryItemsByKind[UICollectionElementKindSectionHeader] = headers
	}
	
	/// Pins the pinnable headers starting at `minY` -- as long as they don't cross `minY` -- and updates `minY` to a new value.
	private func applyTopPinningToPinnableHeaders(inout in section: LayoutSection, inout minY: CGFloat, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		guard var headers = section.supplementaryItemsByKind[UICollectionElementKindSectionHeader] else {
			return
		}
		
		for (index, header) in headers.enumerate() where header.shouldPin {
			guard var header = header as? TableLayoutSupplementaryItem else {
				continue
			}
			
			var frame = header.frame
			
			guard frame.minY < minY else {
				continue
			}
			
			// We have a new pinning offset
			frame.origin.y = minY
			minY = frame.maxY
			header.frame = frame
			
			invalidationContext?.invalidate(header)
			headers[index] = header
		}
		
		section.supplementaryItemsByKind[UICollectionElementKindSectionHeader] = headers
	}
	
	private func finalizePinningForHeaders(pinnable pinnable: Bool, inout in section: LayoutSection, zIndex: Int) {
		guard var headers = section.supplementaryItemsByKind[UICollectionElementKindSectionHeader] else {
			return
		}
		
		for (index, header) in headers.enumerate() where header.shouldPin == pinnable {
			guard var header = header as? TableLayoutSupplementaryItem else {
				continue
			}
			
			header.isPinned = header.frame.minY != header.unpinnedY
			
			let depth = index + 1
			header.zIndex = zIndex - depth
			
			headers[index] = header
		}
		
		section.supplementaryItemsByKind[UICollectionElementKindSectionHeader] = headers
	}
	
	private func applyBottomPinningToNonPinnableHeaders(inout in section: LayoutSection, inout maxY: CGFloat, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		guard var headers = section.supplementaryItemsByKind[UICollectionElementKindSectionHeader] else {
			return
		}
		
		for (index, header) in headers.enumerate().reverse() where !header.shouldPin {
			var header = header
			var frame = header.frame
			
			guard frame.maxY < maxY else {
				continue
			}
			
			maxY -= frame.height
			frame.origin.y = maxY
			header.frame = frame
			
			invalidationContext?.invalidate(header)
			headers[index] = header
		}
		
		section.supplementaryItemsByKind[UICollectionElementKindSectionHeader] = headers
	}
	
	private func headers(pinnable pinnable: Bool, in section: LayoutSection) -> [LayoutSupplementaryItem] {
		guard let headers = section.supplementaryItemsByKind[UICollectionElementKindSectionHeader] else {
			return []
		}
		
		return headers.filter { $0.shouldPin == pinnable }
	}
	
}
