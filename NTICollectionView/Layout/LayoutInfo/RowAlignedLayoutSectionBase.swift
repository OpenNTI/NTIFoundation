//
//  RowAlignedLayoutSectionBase.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 4/22/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public struct RowAlignedLayoutSectionBase: LayoutSectionBaseComposite {
	
	public var rows: [LayoutRow] = []
	
	public var layoutSectionBase: LayoutSectionBase = .init()
	
}

extension RowAlignedLayoutSectionBase {
	
	public var items: [LayoutItem] {
		return rows.reduce([]) { (items, row) in
			items + row.items
		}
	}
	
	public func item(at index: Int) -> LayoutItem {
		var searchIndex = 0
		
		for row in rows {
			let itemCount = row.items.count
			
			if searchIndex + itemCount <= index {
				searchIndex += itemCount
				continue
			}
			
			let itemIndex = index - searchIndex
			return row.items[itemIndex]
		}
		
		preconditionFailure("We should find an item at \(index).")
	}
	
	public mutating func setItem(item: LayoutItem, at index: Int) {
		var searchIndex = 0
		
		for rowIndex in rows.indices {
			var row = rows[rowIndex]
			let itemCount = row.items.count
			
			if searchIndex + itemCount <= index {
				searchIndex += itemCount
				continue
			}
			
			let itemIndex = index - searchIndex
			row.items[itemIndex] = item
			
			rows[rowIndex] = row
			return
		}
	}
	
	public mutating func mutateItems(using mutator: (item: inout LayoutItem, index: Int) -> Void) {
		mutateRows { (row, _) in
			for itemIndex in row.items.indices {
				mutator(item: &row.items[itemIndex], index: itemIndex)
			}
		}
	}
	
}

extension RowAlignedLayoutSectionBase {
	
	public func row(forItemAt itemIndex: Int) -> LayoutRow? {
		guard let index = rowIndex(forItemAt: itemIndex) else {
			return nil
		}
		
		return rows[index]
	}
	
	public func rowIndex(forItemAt itemIndex: Int) -> Int? {
		var searchIndex = 0
		
		for (index, row) in rows.enumerate() {
			let itemCount = row.items.count
			
			if searchIndex + itemCount < itemIndex {
				searchIndex += itemCount
				continue
			}
			
			return index
		}
		
		return nil
	}
	
	public mutating func add(row: LayoutRow) {
		rows.append(row)
	}
	
	public mutating func mutateRows(using mutator: (row: inout LayoutRow, index: Int) -> Void) {
		for index in rows.indices {
			mutator(row: &rows[index], index: index)
		}
	}
	
	public mutating func removeAllRows() {
		rows.removeAll(keepCapacity: true)
	}
	
}

// MARK: - RowAlignedLayoutSectionBaseComposite

public protocol RowAlignedLayoutSectionBaseComposite: LayoutSectionBaseComposite {
	
	var rowAlignedLayoutSectionBase: RowAlignedLayoutSectionBase { get set }
	
}

extension RowAlignedLayoutSectionBaseComposite {
	
	public var layoutSectionBase: LayoutSectionBase {
		get { return rowAlignedLayoutSectionBase.layoutSectionBase }
		set { rowAlignedLayoutSectionBase.layoutSectionBase = newValue }
	}
	
	public var rows: [LayoutRow] {
		get { return rowAlignedLayoutSectionBase.rows }
		set { rowAlignedLayoutSectionBase.rows = newValue }
	}
	
	public var items: [LayoutItem] {
		return rowAlignedLayoutSectionBase.items
	}
	
	public func item(at index: Int) -> LayoutItem {
		return rowAlignedLayoutSectionBase.item(at: index)
	}
	
	public mutating func setItem(item: LayoutItem, at index: Int) {
		rowAlignedLayoutSectionBase.setItem(item, at: index)
	}
	
	public mutating func mutateItems(using mutator: (item: inout LayoutItem, index: Int) -> Void) {
		rowAlignedLayoutSectionBase.mutateItems(using: mutator)
	}
	
	public func row(forItemAt itemIndex: Int) -> LayoutRow? {
		return rowAlignedLayoutSectionBase.row(forItemAt: itemIndex)
	}
	
	public func rowIndex(forItemAt itemIndex: Int) -> Int? {
		return rowAlignedLayoutSectionBase.rowIndex(forItemAt: itemIndex)
	}
	
	public mutating func add(row: LayoutRow) {
		rowAlignedLayoutSectionBase.add(row)
	}
	
	public mutating func mutateRows(using mutator: (row: inout LayoutRow, index: Int) -> Void) {
		rowAlignedLayoutSectionBase.mutateRows(using: mutator)
	}
	
	public mutating func removeAllRows() {
		rowAlignedLayoutSectionBase.removeAllRows()
	}
	
}


