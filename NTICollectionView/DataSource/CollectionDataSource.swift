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

public protocol DataSource: NSObjectProtocol {
	
	var title: String? { get set }
	
	var numberOfSections: Int { get }
	
	func numberOfItemsInSection(sectionIndex: Int) -> Int
	
	func item(at indexPath: NSIndexPath) -> Item?
	
	func indexPath(for item: Item) -> NSIndexPath?
	
	func removeItem(at indexPath: NSIndexPath)
	
}

public protocol CollectionDataSourceType: UICollectionViewDataSource, DataSource, PageableContentLoading, CollectionDataSourceMetrics {
	
	var delegate: CollectionDataSourceDelegate? { get set }
	var allowsSelection: Bool { get }
	var isRootDataSource: Bool { get }
	func dataSourceForSectionAtIndex(sectionIndex: Int) -> CollectionDataSourceType
	func localIndexPathForGlobal(globalIndexPath: NSIndexPath) -> NSIndexPath?
	func registerReusableViews(with collectionView: UICollectionView)
	
	var noContentPlaceholder: DataSourcePlaceholder? { get set }
	var errorPlaceholder: DataSourcePlaceholder? { get set }
	var placeholder: DataSourcePlaceholder? { get set }
	func update(placeholderView: CollectionPlaceholderView?, forSectionAtIndex sectionIndex: Int)
	
	func performUpdate(update: () -> Void, complete: (() -> Void)?)
	func didBecomeActive()
	func willResignActive()
	
	func setNeedsLoadContent()
	func setNeedsLoadContent(delay: NSTimeInterval)
	func cancelNeedsLoadContent()
	func loadContent()
	func whenLoaded(onLoad: () -> Void)
	
	func setNeedsLoadNextContent()
	func setNeedsLoadNextContent(delay: NSTimeInterval)
	func cancelNeedsLoadNextContent()
	
	func setNeedsLoadPreviousContent()
	func setNeedsLoadPreviousContent(delay: NSTimeInterval)
	func cancelNeedsLoadPreviousContent()
	
	var controller: CollectionDataSourceController? { get set }
	var delegatesLoadingToController: Bool { get set }
	
	func collectionView(collectionView: UICollectionView, identifierForCellAt indexPath: NSIndexPath) -> String
	func collectionView(collectionView: UICollectionView, canEditItemAt indexPath: NSIndexPath) -> Bool
	func collectionView(collectionView: UICollectionView, canMoveItemAt indexPath: NSIndexPath) -> Bool
	func collectionView(collectionView: UICollectionView, canMoveItemAt indexPath: NSIndexPath, to destinationIndexPath: NSIndexPath) -> Bool
	func collectionView(collectionView: UICollectionView, moveItemAt sourceIndexPath: NSIndexPath, to destinationIndexPath: NSIndexPath)
}

public protocol ParentCollectionDataSource: CollectionDataSourceType, CollectionDataSourceDelegate {
	
	var dataSources: [CollectionDataSourceType] { get }
	
	func add(dataSource: CollectionDataSourceType)
	func remove(dataSource: CollectionDataSourceType)
	
}

public protocol CollectionDataSourceMetrics: NSObjectProtocol {
	
	/// The default metrics for all sections in `self`.
	var defaultMetrics: DataSourceSectionMetricsProviding? { get set }
	/// The metrics for the global section (supplementary items) for `self`. 
	/// 
	/// - note: This is only meaningful when `self` is the root or top-level data source.
	var globalMetrics: DataSourceSectionMetricsProviding? { get set }
	var sectionMetrics: [Int: DataSourceSectionMetricsProviding] { get }
	/// Supplementary items organized by element kind which appear prior to the supplementary items in the first section.
	var supplementaryItemsByKind: [String: [SupplementaryItem]] { get }
	
	/// Returns the supplementary item for the given *key*, or `nil` if no such item is found.
	func supplementaryItem(for key: String) -> SupplementaryItem?
	
	func metricsForSectionAtIndex(sectionIndex: Int) -> DataSourceSectionMetricsProviding?
	func setMetrics(metrics: DataSourceSectionMetricsProviding?, forSectionAtIndex sectionIndex: Int)
	
	func numberOfSupplementaryItemsOfKind(kind: String, inSectionAtIndex sectionIndex: Int, shouldIncludeChildDataSources: Bool) -> Int
	
	func indexPaths(for supplementaryItem: SupplementaryItem) -> [NSIndexPath]
	
	func findSupplementaryItemOfKind(kind: String, at indexPath: NSIndexPath, using block: (dataSource: CollectionDataSource, localIndexPath: NSIndexPath, supplementaryItem: SupplementaryItem) -> Void)
	
	func snapshotMetrics() -> [Int: DataSourceSectionMetricsProviding]
	func snapshotMetricsForSectionAtIndex(sectionIndex: Int) -> DataSourceSectionMetricsProviding?
	
	var contributesGlobalMetrics: Bool { get set }
	func snapshotContributedGlobalMetrics() -> DataSourceSectionMetricsProviding?
	
	func add(supplementaryItem: SupplementaryItem)
	func add(supplementaryItem: SupplementaryItem, forSectionAtIndex sectionIndex: Int)
	func add(supplementaryItem: SupplementaryItem, forKey key: String)
	func removeSupplementaryItemForKey(key: String)
	func replaceSupplementaryItemForKey(key: String, with supplementaryItem: SupplementaryItem)
	func supplementaryItemsOfKind(kind: String) -> [SupplementaryItem]
	func supplementaryItemForKey(key: String) -> SupplementaryItem?
}
