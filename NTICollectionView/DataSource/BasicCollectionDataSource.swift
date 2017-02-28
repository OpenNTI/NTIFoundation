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
open class BasicCollectionDataSource<Item : AnyObject> : CollectionDataSource {

	/// Allows clients to update loading progress with a specified result if using `waitsForProgressUpdate == true`.
	///
	/// Is `nil` until `loadContent(with:)` has been called while `waitsForProgressUpdate == true`, and resets to `nil` once called.
	fileprivate var updateLoadingProgress: ((Result<[Item]>) -> Void)?
	
	/// Whether `self` relies on `updateLoadingProgress` to update loading progress.
	open var waitsForProgressUpdate = false
	
	public override init() {
		super.init()
	}
	
	open var items: [Item] {
		get {
			return _items
		}
		set {
			setItems(newValue, animated: false)
		}
	}
	
	fileprivate var _items: [Item] = []
	
	open func setItems(_ items: [Item], animated: Bool) {
		guard !(items as NSArray).isEqual(to: _items) else {
			return
		}
		
		guard animated else {
			_items = items
			updateLoadingStateFromItems()
			notifySectionsRefreshed(IndexSet(integer: 0))
			return
		}
		
		let oldItemSet = NSOrderedSet(array: _items)
		let newItemSet = NSOrderedSet(array: items)
		
		let deletedItems = oldItemSet.mutableCopy() as! NSMutableOrderedSet
		deletedItems.minus(newItemSet)
		
		let newItems = newItemSet.mutableCopy() as! NSMutableOrderedSet
		newItems.minus(oldItemSet)
		
		let movedItems = newItemSet.mutableCopy() as! NSMutableOrderedSet
		movedItems.intersect(oldItemSet)
		
		let deletedIndexPaths = deletedItems.map {
			IndexPath(item:  oldItemSet.index(of: $0), section: 0)
		}
		
		let insertedIndexPaths = newItems.map {
			IndexPath(item: newItemSet.index(of: $0), section: 0)
		}
		
		let fromMovedIndexPaths = movedItems.map {
			IndexPath(item: oldItemSet.index(of: $0), section: 0)
		}
		let toMovedIndexPaths = movedItems.map {
			IndexPath(item: newItemSet.index(of: $0), section: 0)
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
	
	/// Optionally allows clients to update loading progress using a specified result.
	///
	/// This method has no effect unless `waitsForProgressUpdate == true` and `loadingState == .loadingContent`. After its initial invocation, this method does nothing.
	open func updateLoadingProgress(with result: Result<[Item]>) {
		self.updateLoadingProgress?(result)
	}
	
	open override func resetContent() {
		super.resetContent()
		performUpdate({
			self.items = []
		})
	}
	
	open override func item(at indexPath: IndexPath) -> AnyItem? {
		return value(at: indexPath)
	}
	
	open func value(at indexPath: IndexPath) -> Item? {
		let itemIndex = indexPath.item
		guard itemIndex < items.count else {
			return nil
		}
		return items[itemIndex]
	}
	
	open override func indexPath(for item: AnyItem) -> IndexPath? {
		guard let itemIndex = items.index(where: { $0 === item }) else {
			return nil
		}
		return IndexPath(item: itemIndex, section: 0)
	}
	
	open override func removeItem(at indexPath: IndexPath) {
		let removedIndexes = IndexSet(integer: indexPath.item)
		removeItems(at: removedIndexes)
	}
	
	fileprivate func updateLoadingStateFromItems() {
		let numberOfItems = items.count
		if numberOfItems > 0 && loadingState == .NoContent {
			loadingState = .ContentLoaded
		} else if numberOfItems == 0 && loadingState == .ContentLoaded {
			loadingState = .NoContent
		}
	}
	
	open func insertItems(_ items: [Item], at indexes: IndexSet) {
		var newItems = _items
		for (item, index) in zip(items, indexes) {
			newItems.insert(item, at: index)
		}
		
		let insertedIndexPaths = indexes.map {
			IndexPath(item: $0, section: 0)
		}
		
		_items = newItems
		updateLoadingStateFromItems()
		notifyItemsInserted(at: insertedIndexPaths)
	}
	
	open func removeItems(at indexes: IndexSet) {
		var newItems: [Item] = []
		let newCount = _items.count - indexes.count
		newItems.reserveCapacity(newCount)
		
		// Set up a delayed set of batch update calls for later execution
		var batchUpdates = {}
		
		for (idx, item) in _items.enumerated() {
			let oldUpdates = batchUpdates
			if indexes.contains(idx) {
				// We're removing this item
				batchUpdates = {
					oldUpdates()
					self.notifyItemsRemoved(at: [IndexPath(item: idx, section: 0)])
				}
			} else {
				// We're keeping this item
				let newIdx = newItems.count
				newItems.append(item)
				batchUpdates = {
					oldUpdates()
					self.notifyItemMoved(from: IndexPath(item: idx, section: 0), to: IndexPath(item: newIdx, section: 0))
				}
			}
		}
		
		_items = newItems
		batchUpdates()
		updateLoadingStateFromItems()
	}
	
	open func replaceItems(at indexes: IndexSet, with items: [Item]) {
		var newItems = _items
		for (index, item) in zip(indexes, items) {
			newItems[index] = item
		}
		
		let replacedIndexPaths = indexes.map { IndexPath(item: $0, section: 0) }
			
		_items = newItems
		notifyItemsRefreshed(at: replacedIndexPaths)
	}
	
	open override func numberOfItemsInSection(_ sectionIndex: Int) -> Int {
		return items.count
	}
	
	open override func loadContent(with progress: LoadingProgress) {
		guard waitsForProgressUpdate else {
			return super.loadContent(with: progress)
		}
		
		updateLoadingProgress = { [unowned self] (result) in
			switch result {
			case let .success(loadedItems):
				let update = { (me: AnyObject) in
					guard let me = me as? BasicCollectionDataSource<Item> else {
						return
					}
					me.items = loadedItems
				}
				
				if loadedItems.isEmpty {
					progress.updateWithNoContent(update)
				}
				else {
					progress.updateWithContent(update)
				}
			case let .failure(error):
				progress.done(with: error)
			}
			
			self.updateLoadingProgress = nil
		}
	}
	
	// MARK: - UICollectionViewDataSource
	
	open override func collectionView(_ collectionView: UICollectionView, moveItemAt indexPath: IndexPath, to destinationIndexPath: IndexPath) {
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
		
		items.remove(at: fromIndex)
		items.insert(movingObject, at: toIndex)
		
		_items = items
		notifyItemMoved(from: indexPath, to: destinationIndexPath)
	}

}
