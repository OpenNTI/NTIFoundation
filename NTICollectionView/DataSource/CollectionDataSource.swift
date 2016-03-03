//
//  CollectionDataSource.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/18/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public func requireMainThread() {
	precondition(NSThread.isMainThread(), "This method must be called on the main thread.")
}

public typealias Item = AnyObject

public protocol DataSource {
	
	var title: String? { get set }
	
	var numberOfSections: Int { get }
	
	func numberOfItemsInSection(sectionIndex: Int) -> Int
	
	func item(at indexPath: NSIndexPath) -> Item?
	
	func indexPath(`for` item: Item) -> NSIndexPath?
	
	func removeItem(at indexPath: NSIndexPath)
	
}

public protocol CollectionDataSource: UICollectionViewDataSource, DataSource, ContentLoading, CollectionDataSourceMetrics {
	
	var delegate: CollectionDataSourceDelegate? { get set }
	var allowsSelection: Bool { get }
	var isRootDataSource: Bool { get }
	func dataSourceForSectionAtIndex(sectionIndex: Int) -> CollectionDataSource
	func localIndexPathForGlobal(globalIndexPath: NSIndexPath) -> NSIndexPath
	func registerReusableViews(with collectionView: UICollectionView)
	
	var placeholder: DataSourcePlaceholder? { get set }
	func update(placeholderView: CollectionPlaceholderView?, forSectionAtIndex sectionIndex: Int)
	
	func performUpdate(update: () -> Void, complete: (() -> Void)?)
	func didBecomeActive()
	func willResignActive()
	
	func setNeedsLoadContent()
	func loadContent()
	func whenLoaded(onLoad: () -> Void)
	
	func collectionView(collectionView: UICollectionView, identifierForCellAt indexPath: NSIndexPath) -> String
	func collectionView(collectionView: UICollectionView, canEditItemAt indexPath: NSIndexPath) -> Bool
	func collectionView(collectionView: UICollectionView, canMoveItemAt indexPath: NSIndexPath) -> Bool
	func collectionView(collectionView: UICollectionView, canMoveItemAt indexPath: NSIndexPath, to destinationIndexPath: NSIndexPath) -> Bool
	func collectionView(collectionView: UICollectionView, moveItemAt sourceIndexPath: NSIndexPath, to destinationIndexPath: NSIndexPath)
}

public protocol ParentCollectionDataSource: CollectionDataSource, CollectionDataSourceDelegate {
	
	var dataSources: [CollectionDataSource] { get }
	
	func add(dataSource: CollectionDataSource)
	
	func remove(dataSource: CollectionDataSource)
	
}

public protocol CollectionDataSourceMetrics: NSObjectProtocol {
	
	var defaultMetrics: DataSourceSectionMetrics? { get set }
	var globalMetrics: DataSourceSectionMetrics? { get set }
	var sectionMetrics: [Int: DataSourceSectionMetrics] { get }
	var supplementaryItemsByKind: [String: [SupplementaryItem]] { get }
	
	
	func metricsForSectionAtIndex(sectionIndex: Int) -> DataSourceSectionMetrics?
	func setMetrics(metrics: DataSourceSectionMetrics?, forSectionAtIndex sectionIndex: Int)
	
	// FIXME: Typo in "shouldIncludeChilDataSources"
	func numberOfSupplementaryItemsOfKind(kind: String, inSectionAtIndex sectionIndex: Int, shouldIncludeChilDataSources: Bool) -> Int
	
	func indexPaths(`for` supplementaryItem: SupplementaryItem) -> [NSIndexPath]
	
	func findSupplementaryItemOfKind(kind: String, at indexPath: NSIndexPath, using block: (dataSource: CollectionDataSource, localIndexPath: NSIndexPath, supplementaryItem: SupplementaryItem) -> Void)
	
	func snapshotMetrics() -> [Int: DataSourceSectionMetrics]
	func snapshotMetricsForSectionAtIndex(sectionIndex: Int) -> DataSourceSectionMetrics?
	
	func add(supplementaryItem: SupplementaryItem)
	func add(supplementaryItem: SupplementaryItem, forSectionAtIndex sectionIndex: Int)
	func add(supplementaryItem: SupplementaryItem, forKey key: String)
	func supplementaryItemsOfKind(kind: String) -> [SupplementaryItem]
	func supplementaryItemForKey(key: String) -> SupplementaryItem?
}

extension CollectionDataSource {
	
	public var isRootDataSource: Bool {
		return !(delegate is CollectionDataSource)
	}
	
	public func dataSourceForSectionAtIndex(sectionIndex: Int) -> CollectionDataSource {
		return self
	}
	
	public func localIndexPathForGlobal(globalIndexPath: NSIndexPath) -> NSIndexPath {
		return globalIndexPath
	}
	
	public func collectionView(collectionView: UICollectionView, canMoveItemAt indexPath: NSIndexPath) -> Bool {
		return false
	}
	
	public func collectionView(collectionView: UICollectionView, moveItemAt sourceIndexPath: NSIndexPath, to destinationIndexPath: NSIndexPath) {
		
	}
	
}

extension CollectionDataSource {
	
	/// Notify the parent data source and the collection view that new items have been inserted at positions represented by *insertedIndexPaths*.
	public func notifyItemsInserted(at indexPaths: [NSIndexPath]) {
		requireMainThread()
		delegate?.dataSource(self, didInsertItemsAt: indexPaths)
	}
	
	/// Notify the parent data source and collection view that the items represented by *removedIndexPaths* have been removed from this data source.
	public func notifyItemsRemoved(at indexPaths: [NSIndexPath]) {
		requireMainThread()
		delegate?.dataSource(self, didRemoveItemsAt: indexPaths)
	}
	
	/// Notify the parent data sources and collection view that the items represented by *refreshedIndexPaths* have been updated and need redrawing.
	public func notifyItemsRefreshed(at indexPaths: [NSIndexPath]) {
		requireMainThread()
		delegate?.dataSource(self, didRefreshItemsAt: indexPaths)
	}
	
	/// Notify the parent data sources and collection view that the items represented by *refreshedIndexPaths* have been updated and need redrawing.
	public func notifyItemMoved(from oldIndexPath: NSIndexPath, to newIndexPath: NSIndexPath) {
		requireMainThread()
		delegate?.dataSource(self, didMoveItemAt: oldIndexPath, to: newIndexPath)
	}
	
	/// Notify parent data sources and the collection view that the sections were inserted.
	public func notifySectionsInserted(sections: NSIndexSet, direction: SectionOperationDirection? = nil) {
		requireMainThread()
		delegate?.dataSource(self, didInsertSections: sections, direction: direction)
	}
	
	/// Notify parent data sources and (eventually) the collection view that the sections were removed.
	public func notifySectionsRemoved(sections: NSIndexSet, direction: SectionOperationDirection? = nil) {
		requireMainThread()
		delegate?.dataSource(self, didRemoveSections: sections, direction: direction)
	}
	
	/// Notify parent data sources and the collection view that the section at *oldSectionIndex* was moved to *newSectionIndex*.
	public func notifySectionsMoved(from oldSectionIndex: Int, to newSectionIndex: Int, direction: SectionOperationDirection? = nil) {
		requireMainThread()
		delegate?.dataSource(self, didMoveSectionFrom: oldSectionIndex, to: newSectionIndex, direction: direction)
	}
	
	/// Notify parent data sources and ultimately the collection view the specified sections were refreshed.
	public func notifySectionsRefreshed(sections: NSIndexSet) {
		requireMainThread()
		delegate?.dataSource(self, didRefreshSections: sections)
	}
	
	/// Notify parent data sources and ultimately the collection view that the data in this data source has been reloaded.
	public func notifyDidReloadData() {
		requireMainThread()
		delegate?.dataSourceDidReloadData(self)
	}
	
	public func notifyContentLoaded(with error: NSError? = nil) {
		requireMainThread()
		delegate?.dataSourceDidLoadContent(self, error: error)
	}
	
	public func notifyWillLoadContent() {
		requireMainThread()
		delegate?.dataSourceWillLoadContent(self)
	}
	
	public func notifyContentUpdated(`for` supplementaryItem: SupplementaryItem, at indexPaths: [NSIndexPath]) {
		requireMainThread()
		delegate?.dataSource(self, didUpdate: supplementaryItem, at: indexPaths)
	}
	
}

extension CollectionDataSource {
	
	public var globalMetrics: DataSourceSectionMetrics? {
		get {
			return metricsForSectionAtIndex(GlobalSectionIndex)
		}
		set {
			setMetrics(newValue, forSectionAtIndex: GlobalSectionIndex)
		}
	}
	
}
