//
//  CollectionDataSourceMetrics.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/18/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public func requireMainThread() {
	precondition(Thread.isMainThread, "This method must be called on the main thread.")
}

public typealias AnyItem = AnyObject

public protocol DataSource: NSObjectProtocol {
	
	var title: String? { get set }
	
	var numberOfSections: Int { get }
	
	func numberOfItemsInSection(_ sectionIndex: Int) -> Int
	
	func item(at indexPath: IndexPath) -> AnyItem?
	
	func indexPath(for item: AnyItem) -> IndexPath?
	
	func removeItem(at indexPath: IndexPath)
	
}

public protocol CollectionDataSourceType: UICollectionViewDataSource, DataSource, PageableContentLoading, CollectionDataSourceMetrics {
	
	var delegate: CollectionDataSourceDelegate? { get set }
	var allowsSelection: Bool { get }
	var isRootDataSource: Bool { get }
	func dataSourceForSectionAtIndex(_ sectionIndex: Int) -> CollectionDataSourceType
	func localIndexPathForGlobal(_ globalIndexPath: IndexPath) -> IndexPath?
	func registerReusableViews(with collectionView: UICollectionView)
	
	var noContentPlaceholder: DataSourcePlaceholder? { get set }
	var errorPlaceholder: DataSourcePlaceholder? { get set }
	var placeholder: DataSourcePlaceholder? { get set }
	func update(_ placeholderView: CollectionPlaceholderView?, forSectionAtIndex sectionIndex: Int)
	
	func performUpdate(_ update: () -> Void, complete: (() -> Void)?)
	func didBecomeActive()
	func willResignActive()
	
	func setNeedsLoadContent()
	func setNeedsLoadContent(_ delay: TimeInterval)
	func cancelNeedsLoadContent()
	func loadContent()
	func whenLoaded(_ onLoad: () -> Void)
	
	func setNeedsLoadNextContent()
	func setNeedsLoadNextContent(_ delay: TimeInterval)
	func cancelNeedsLoadNextContent()
	
	func setNeedsLoadPreviousContent()
	func setNeedsLoadPreviousContent(_ delay: TimeInterval)
	func cancelNeedsLoadPreviousContent()
	
	var controller: CollectionDataSourceController? { get set }
	var delegatesLoadingToController: Bool { get set }
	
	func collectionView(_ collectionView: UICollectionView, identifierForCellAt indexPath: IndexPath) -> String
	func collectionView(_ collectionView: UICollectionView, canEditItemAt indexPath: IndexPath) -> Bool
	func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool
	func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath, to destinationIndexPath: IndexPath) -> Bool
	func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath)
}

public protocol ParentCollectionDataSource: CollectionDataSourceType, CollectionDataSourceDelegate {
	
	var dataSources: [CollectionDataSourceType] { get }
	
	func add(_ dataSource: CollectionDataSourceType)
	func remove(_ dataSource: CollectionDataSourceType)
	
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
	
	func metricsForSectionAtIndex(_ sectionIndex: Int) -> DataSourceSectionMetricsProviding?
	func setMetrics(_ metrics: DataSourceSectionMetricsProviding?, forSectionAtIndex sectionIndex: Int)
	
	func numberOfSupplementaryItemsOfKind(_ kind: String, inSectionAtIndex sectionIndex: Int, shouldIncludeChildDataSources: Bool) -> Int
	
	func indexPaths(for supplementaryItem: SupplementaryItem) -> [IndexPath]
	
	func findSupplementaryItemOfKind(_ kind: String, at indexPath: IndexPath, using block: (_ dataSource: CollectionDataSource, _ localIndexPath: IndexPath, _ supplementaryItem: SupplementaryItem) -> Void)
	
	func snapshotMetrics() -> [Int: DataSourceSectionMetricsProviding]
	func snapshotMetricsForSectionAtIndex(_ sectionIndex: Int) -> DataSourceSectionMetricsProviding?
	
	var contributesGlobalMetrics: Bool { get set }
	func snapshotContributedGlobalMetrics() -> DataSourceSectionMetricsProviding?
	
	func add(_ supplementaryItem: SupplementaryItem)
	func add(_ supplementaryItem: SupplementaryItem, forSectionAtIndex sectionIndex: Int)
	func add(_ supplementaryItem: SupplementaryItem, forKey key: String)
	func removeSupplementaryItemForKey(_ key: String)
	func replaceSupplementaryItemForKey(_ key: String, with supplementaryItem: SupplementaryItem)
	func supplementaryItemsOfKind(_ kind: String) -> [SupplementaryItem]
	func supplementaryItemForKey(_ key: String) -> SupplementaryItem?
}
