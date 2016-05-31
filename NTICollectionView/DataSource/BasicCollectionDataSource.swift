//
//  BasicCollectionDataSource.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/23/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

/**
A `CollectionDataSource` which manages a single section of items backed by an array.
*/
public class BasicCollectionDataSource<Item : AnyObject> : CollectionDataSource {

	public override init() {
		super.init()
	}
	
	public var items: [Item] {
		get {
			return _items
		}
		set {
			setItems(newValue, animated: false)
		}
	}
	private var _items: [Item] = []
	
	public func setItems(items: [Item], animated: Bool) {
		guard !(items as NSArray).isEqualToArray(_items) else {
			return
		}
		
		guard animated else {
			_items = items
			updateLoadingStateFromItems()
			notifySectionsRefreshed(NSIndexSet(index: 0))
			return
		}
		
		let oldItemSet = NSOrderedSet(array: _items)
		let newItemSet = NSOrderedSet(array: items)
		
		let deletedItems = oldItemSet.mutableCopy() as! NSMutableOrderedSet
		deletedItems.minusOrderedSet(newItemSet)
		
		let newItems = newItemSet.mutableCopy() as! NSMutableOrderedSet
		newItems.minusOrderedSet(oldItemSet)
		
		let movedItems = newItemSet.mutableCopy() as! NSMutableOrderedSet
		movedItems.intersectOrderedSet(oldItemSet)
		
		let deletedIndexPaths = deletedItems.map {
			NSIndexPath(forItem:  oldItemSet.indexOfObject($0), inSection: 0)
		}
		
		let insertedIndexPaths = newItems.map {
			NSIndexPath(forItem: newItemSet.indexOfObject($0), inSection: 0)
		}
		
		let fromMovedIndexPaths = movedItems.map {
			NSIndexPath(forItem: oldItemSet.indexOfObject($0), inSection: 0)
		}
		let toMovedIndexPaths = movedItems.map {
			NSIndexPath(forItem: newItemSet.indexOfObject($0), inSection: 0)
		}
		
		_items = items
		updateLoadingStateFromItems()
		
		if !deletedIndexPaths.isEmpty {
			notifyItemsRemoved(at: deletedIndexPaths)
		}
		
		if !insertedIndexPaths.isEmpty {
			notifyItemsInserted(at: insertedIndexPaths)
		}
		
		for (fromIndexPath, toIndexPath) in zip(fromMovedIndexPaths, toMovedIndexPaths) {
			notifyItemMoved(from: fromIndexPath, to: toIndexPath)
		}
	}
	
	public override func resetContent() {
		super.resetContent()
		performUpdate({
			self.items = []
		})
	}
	
	public override func item(at indexPath: NSIndexPath) -> AnyItem? {
		return value(at: indexPath)
	}
	
	public func value(at indexPath: NSIndexPath) -> Item? {
		let itemIndex = indexPath.item
		guard itemIndex < items.count else {
			return nil
		}
		return items[itemIndex]
	}
	
	public override func indexPath(for item: AnyItem) -> NSIndexPath? {
		guard let itemIndex = items.indexOf({ $0 === item }) else {
			return nil
		}
		return NSIndexPath(forItem: itemIndex, inSection: 0)
	}
	
	public override func removeItem(at indexPath: NSIndexPath) {
		let removedIndexes = NSIndexSet(index: indexPath.item)
		removeItems(at: removedIndexes)
	}
	
	private func updateLoadingStateFromItems() {
		let numberOfItems = items.count
		if numberOfItems > 0 && loadingState == .NoContent {
			loadingState = .ContentLoaded
		} else if numberOfItems == 0 && loadingState == .ContentLoaded {
			loadingState = .NoContent
		}
	}
	
	public func insertItems(items: [Item], at indexes: NSIndexSet) {
		var newItems = _items
		for (item, index) in zip(items, indexes) {
			newItems.insert(item, atIndex: index)
		}
		
		let insertedIndexPaths = indexes.map {
			NSIndexPath(forItem: $0, inSection: 0)
		}
		
		_items = newItems
		updateLoadingStateFromItems()
		notifyItemsInserted(at: insertedIndexPaths)
	}
	
	public func removeItems(at indexes: NSIndexSet) {
		var newItems: [Item] = []
		let newCount = _items.count - indexes.count
		newItems.reserveCapacity(newCount)
		
		// Set up a delayed set of batch update calls for later execution
		var batchUpdates = {}
		
		for (idx, item) in _items.enumerate() {
			let oldUpdates = batchUpdates
			if indexes.containsIndex(idx) {
				// We're removing this item
				batchUpdates = {
					oldUpdates()
					self.notifyItemsRemoved(at: [NSIndexPath(forItem: idx, inSection: 0)])
				}
			} else {
				// We're keeping this item
				let newIdx = newItems.count
				newItems.append(item)
				batchUpdates = {
					oldUpdates()
					self.notifyItemMoved(from: NSIndexPath(forItem: idx, inSection: 0), to: NSIndexPath(forItem: newIdx, inSection: 0))
				}
			}
		}
		
		_items = newItems ?? []
		batchUpdates()
		updateLoadingStateFromItems()
	}
	
	public func replaceItems(at indexes: NSIndexSet, with items: [Item]) {
		var newItems = _items
		for (index, item) in zip(indexes, items) {
			newItems[index] = item
		}
		
		let replacedIndexPaths = indexes.map { NSIndexPath(forItem: $0, inSection: 0) }
			
		_items = newItems
		notifyItemsRefreshed(at: replacedIndexPaths)
	}
	
	public override func numberOfItemsInSection(sectionIndex: Int) -> Int {
		return items.count
	}
	
	// MARK: - UICollectionViewDataSource
	
	public func collectionView(collectionView: UICollectionView, moveItemAtIndexPath indexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
		let fromIndex = indexPath.item
		var toIndex = destinationIndexPath.item
		
		guard fromIndex != toIndex else {
			return
		}
		
		let numberOfItems = _items.count
		guard fromIndex < numberOfItems else {
			return
		}
		
		if toIndex >= numberOfItems {
			toIndex = numberOfItems - 1
		}
		
		var items = _items
		
		let movingObject = items[fromIndex]
		
		items.removeAtIndex(fromIndex)
		items.insert(movingObject, atIndex: toIndex)
		
		_items = items
		notifyItemMoved(from: indexPath, to: destinationIndexPath)
	}

}
