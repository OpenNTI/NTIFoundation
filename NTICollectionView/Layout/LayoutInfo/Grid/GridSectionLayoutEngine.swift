//
//  GridSectionLayoutHelper.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/19/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public class GridSectionLayoutEngine: NSObject, SupplementaryLayoutEngine {
	
	public init(layoutSection: GridLayoutSection) {
		self.layoutSection = layoutSection
		supplementaryItems = layoutSection.supplementaryItems
		super.init()
	}
	
	public weak var layoutSection: GridLayoutSection!
	
	public var pinnableHeaders: [LayoutSupplementaryItem] = []
	public var nonPinnableHeaders: [LayoutSupplementaryItem] = []
	public var supplementaryItems: [LayoutSupplementaryItem]
	
	private var origin: CGPoint!
	private var position: CGPoint!
	
	var layoutSizing: LayoutSizing!
	var invalidationContext: UICollectionViewLayoutInvalidationContext?
	
	public func layoutWithOrigin(start: CGPoint, layoutSizing: LayoutSizing, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) -> CGPoint {
		reset()
		origin = start
		position = start
		self.layoutSizing = layoutSizing
		self.invalidationContext = invalidationContext
		layoutSection.frame.size.width = layoutSizing.width
		
		performLayout()
		
		return position
	}
	
	private func reset() {
		position = origin
		pinnableHeaders = []
		nonPinnableHeaders = []
		layoutSection.removeAllRows()
	}
	
	private func performLayout() {
		let layoutEngine = makeSupplementaryLayoutEngine()
		position = layoutEngine.layoutWithOrigin(origin, layoutSizing: layoutSizing, invalidationContext: invalidationContext)
		let size = CGSize(width: layoutSizing.width, height: position.y - origin.y)
		layoutSection.frame = CGRect(origin: origin, size: size)
		pinnableHeaders += layoutEngine.pinnableHeaders
		nonPinnableHeaders += layoutEngine.nonPinnableHeaders
	}
	
	private func makeSupplementaryLayoutEngine() -> SupplementaryLayoutEngine {
		let cellLayoutEngine = makeCellLayoutEngine()
		return GridSupplementaryItemLayoutEngine(layoutSection: layoutSection, innerLayoutEngine: cellLayoutEngine)
	}
	
	private func makeCellLayoutEngine() -> LayoutEngine {
		return GridSectionCellLayoutEngine(layoutSection: layoutSection)
	}
	
}
