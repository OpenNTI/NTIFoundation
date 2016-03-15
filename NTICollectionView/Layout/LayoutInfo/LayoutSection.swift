//
//  LayoutSection.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/11/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public protocol LayoutSection: LayoutMetrics, LayoutEngine, LayoutAttributesResolving {
	
	var frame: CGRect { get set }
	var sectionIndex: Int { get set }
	
	var isGlobalSection: Bool { get }
	
	var layoutInfo: LayoutInfo? { get set }
	
	var items: [LayoutItem] { get }
	var supplementaryItems: [LayoutSupplementaryItem] { get }
	var headers: [LayoutSupplementaryItem] { get }
	var footers: [LayoutSupplementaryItem] { get }
	
	var backgroundAttribute: UICollectionViewLayoutAttributes? { get }
	
	var placeholderInfo: LayoutPlaceholder? { get set }
	
	var pinnableHeaders: [LayoutSupplementaryItem] { get set }
	var nonPinnableHeaders: [LayoutSupplementaryItem] { get set }
	
	var heightOfNonPinningHeaders: CGFloat { get }
	var heightOfPinningHeaders: CGFloat { get }
	
	/// All the layout attributes associated with this section.
	var layoutAttributes: [UICollectionViewLayoutAttributes] { get }
	
	var decorationViewClassesByKind: [String: AnyClass] { get }
	
	func add(supplementaryItem: LayoutSupplementaryItem)
	func add(item: LayoutItem)
	
	/// Update the frame of this grouped object and any child objects. Use the invalidation context to mark layout objects as invalid.
	func setFrame(frame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext?)
	
	/// Reset the content of this section.
	func reset()
	
	func finalizeLayoutAttributesForSectionsWithContent(sectionsWithContent: NSIndexSet)
	
	func setSize(size: CGSize, forItemAt index: Int, invalidationContext: UICollectionViewLayoutInvalidationContext?) -> CGPoint
	
	func setSize(size: CGSize, forSupplementaryElementOfKind kind: String, at index: Int, invalidationContext: UICollectionViewLayoutInvalidationContext?) -> CGPoint
	
	func setSize(size: CGSize, forHeaderAt index: Int, invalidationContext: UICollectionViewLayoutInvalidationContext?) -> CGPoint
	
	func setSize(size: CGSize, forFooterAt index: Int, invalidationContext: UICollectionViewLayoutInvalidationContext?) -> CGPoint
	
}

extension LayoutSection {
	
	public var numberOfItems: Int {
		return items.count
	}
	
}

public protocol LayoutEngine: NSObjectProtocol {
	
	/// Layout this section with the given starting origin and using the invalidation context to record cells and supplementary views that should be redrawn.
	func layoutWithOrigin(origin: CGPoint, layoutSizing: LayoutSizing, invalidationContext: UICollectionViewLayoutInvalidationContext?) -> CGPoint
	
}

public func layoutSection(`self`: LayoutSection, setFrame frame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) {
	guard frame != `self`.frame else {
		return
	}
	let offset = CGPoint(x: frame.origin.x - self.frame.origin.x, y: frame.origin.y - self.frame.origin.y)
	
	for supplementaryItem in `self`.supplementaryItems {
		let supplementaryFrame = CGRectOffset(supplementaryItem.frame, offset.x, offset.y)
		supplementaryItem.setFrame(supplementaryFrame, invalidationContext: invalidationContext)
	}
	
	if let backgroundAttribute = `self`.backgroundAttribute {
		let backgroundRect = CGRectOffset(backgroundAttribute.frame, offset.x, offset.y)
		backgroundAttribute.frame = backgroundRect
		invalidationContext?.invalidateDecorationElementsOfKind(backgroundAttribute.representedElementKind!, atIndexPaths: [backgroundAttribute.indexPath])
	}
	
	`self`.frame = frame
}

public func layoutSection(`self`: LayoutSection, offsetContentAfter origin: CGPoint, with offset: CGPoint, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) {
	for supplementaryItem in `self`.supplementaryItems {
		var supplementaryFrame = supplementaryItem.frame
		if supplementaryFrame.minX < origin.x || supplementaryFrame.minY < origin.y {
			continue
		}
		supplementaryFrame = CGRectOffset(supplementaryFrame, offset.x, offset.y)
		supplementaryItem.setFrame(supplementaryFrame, invalidationContext: invalidationContext)
	}
	
	for item in `self`.items {
		var itemFrame = item.frame
		if itemFrame.minX < origin.x || itemFrame.minY < origin.y {
			continue
		}
		itemFrame = CGRectOffset(itemFrame, offset.x, offset.y)
		item.setFrame(itemFrame, invalidationContext: invalidationContext)
	}
}
