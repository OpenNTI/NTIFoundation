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
		super.init()
	}
	
	public weak var layoutSection: GridLayoutSection!
	
	public var pinnableHeaders: [LayoutSupplementaryItem] = []
	public var nonPinnableHeaders: [LayoutSupplementaryItem] = []
	
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
		position = layoutEngine.layoutWithOrigin(position, layoutSizing: layoutSizing, invalidationContext: invalidationContext)
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
