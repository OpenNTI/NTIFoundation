//
//  LayoutSectionBase.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 4/20/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public struct LayoutSectionBase {
	
	public var frame = CGRectZero
	
	public var sectionIndex = NSNotFound
	
	public var supplementaryItemsByKind: [String: [LayoutSupplementaryItem]] = [:]
	
	public var phantomCellIndex: Int?
	
	public var phantomCellSize = CGSizeZero
	
}

extension LayoutSectionBase {
	
	public var supplementaryItems: [LayoutSupplementaryItem] {
		return supplementaryItemsByKind.contents
	}
	
	public func supplementaryItems(of kind: String) -> [LayoutSupplementaryItem] {
		return supplementaryItemsByKind[kind] ?? []
	}
	
	public mutating func setSupplementaryItems(supplementaryItems: [LayoutSupplementaryItem], of kind: String) {
		var supplementaryItems = supplementaryItems
		for index in supplementaryItems.indices {
			supplementaryItems[index].itemIndex = index
			supplementaryItems[index].sectionIndex = sectionIndex
		}
		supplementaryItemsByKind[kind] = supplementaryItems
	}
	
	public mutating func add(supplementaryItem: LayoutSupplementaryItem) {
		let kind = supplementaryItem.elementKind
		var supplementaryItem = supplementaryItem
		supplementaryItem.itemIndex = supplementaryItems(of: kind).count
		supplementaryItem.sectionIndex = sectionIndex
		supplementaryItemsByKind.append(supplementaryItem, to: kind)
	}
	
	public mutating func mutateSupplementaryItems(using mutator: (supplementaryItem: inout LayoutSupplementaryItem, kind: String, index: Int) -> Void) {
		for (kind, supplementaryItems) in supplementaryItemsByKind {
			var supplementaryItems = supplementaryItems
			for index in supplementaryItems.indices {
				mutator(supplementaryItem: &supplementaryItems[index], kind: kind, index: index)
			}
			supplementaryItemsByKind[kind] = supplementaryItems
		}
	}
	
}

// MARK: - LayoutSectionBaseComposite

public protocol LayoutSectionBaseComposite {
	
	var layoutSectionBase: LayoutSectionBase { get set }
	
}

extension LayoutSectionBaseComposite {
	
	public var frame: CGRect {
		get {
			return layoutSectionBase.frame
		}
		set {
			layoutSectionBase.frame = newValue
		}
	}
	
	public var sectionIndex: Int {
		get {
			return layoutSectionBase.sectionIndex
		}
		set {
			layoutSectionBase.sectionIndex = newValue
		}
	}
	
	public var supplementaryItemsByKind: [String: [LayoutSupplementaryItem]] {
		get {
			return layoutSectionBase.supplementaryItemsByKind
		}
		set {
			layoutSectionBase.supplementaryItemsByKind = newValue
		}
	}
	
	public var phantomCellIndex: Int? {
		get { return layoutSectionBase.phantomCellIndex }
		set { layoutSectionBase.phantomCellIndex = newValue }
	}
	
	public var phantomCellSize: CGSize {
		get { return layoutSectionBase.phantomCellSize }
		set { layoutSectionBase.phantomCellSize = newValue }
	}
	
	public var supplementaryItems: [LayoutSupplementaryItem] {
		return layoutSectionBase.supplementaryItems
	}
	
	public func supplementaryItems(of kind: String) -> [LayoutSupplementaryItem] {
		return layoutSectionBase.supplementaryItems(of: kind)
	}
	
	public mutating func setSupplementaryItems(supplementaryItems: [LayoutSupplementaryItem], of kind: String) {
		layoutSectionBase.setSupplementaryItems(supplementaryItems, of: kind)
	}
	
	public mutating func add(supplementaryItem: LayoutSupplementaryItem) {
		layoutSectionBase.add(supplementaryItem)
	}
	
	public mutating func mutateSupplementaryItems(using mutator: (supplementaryItem: inout LayoutSupplementaryItem, kind: String, index: Int) -> Void) {
		layoutSectionBase.mutateSupplementaryItems(using: mutator)
	}
	
}