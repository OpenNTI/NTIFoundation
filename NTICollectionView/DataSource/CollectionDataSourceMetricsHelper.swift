//
//  CollectionDataSourceMetricsHelper.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/22/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public class CollectionDataSourceMetricsHelper: NSObject, CollectionDataSourceMetrics {
	
	public init(dataSource: CollectionDataSource) {
		self.dataSource = dataSource
		super.init()
	}
	
	public weak var dataSource: CollectionDataSource!
	
	var isRootDataSource: Bool {
		return dataSource.isRootDataSource
	}
	
	var numberOfSections: Int {
		return dataSource.numberOfSections
	}
	
	var placeholder: DataSourcePlaceholder? {
		return dataSource.placeholder
	}
	
	public var supplementaryItemsByKind: [String: [SupplementaryItem]] {
		return dataSource.supplementaryItemsByKind
	}
	public var sectionMetrics: [Int: DataSourceSectionMetricsProviding] {
		return dataSource.sectionMetrics
	}
	public var defaultMetrics: DataSourceSectionMetricsProviding? {
		get {
			return dataSource.defaultMetrics
		}
		set {
			dataSource.defaultMetrics = newValue
		}
	}
	public var globalMetrics: DataSourceSectionMetricsProviding? {
		get {
			return dataSource.metricsForSectionAtIndex(globalSectionIndex)
		}
		set {
			dataSource.setMetrics(newValue, forSectionAtIndex: globalSectionIndex)
		}
	}
	
	public var contributesGlobalMetrics: Bool {
		get {
			return dataSource.contributesGlobalMetrics
		}
		set {
			dataSource.contributesGlobalMetrics = newValue
		}
	}
	
	public func supplementaryItem(for key: String) -> SupplementaryItem? {
		return dataSource.supplementaryItem(for: key)
	}
	
	/// Retrieve the layout metrics for a specific section within this data source.
	public func metricsForSectionAtIndex(sectionIndex: Int) -> DataSourceSectionMetricsProviding? {
		return dataSource.metricsForSectionAtIndex(sectionIndex)
	}
	
	/// Store customized layout metrics for a section in this data source. The values specified in metrics will override values specified by the data source's `defaultMetrics`.
	public func setMetrics(metrics: DataSourceSectionMetricsProviding?, forSectionAtIndex sectionIndex: Int) {
		dataSource.setMetrics(metrics, forSectionAtIndex: sectionIndex)
	}
	
	public func numberOfSupplementaryItemsOfKind(kind: String, inSectionAtIndex sectionIndex: Int, shouldIncludeChildDataSources: Bool) -> Int {
		let items = supplementaryItemsOfKind(kind)
		
		if isRootDataSource && sectionIndex == globalSectionIndex {
			return items.count
		}
		
		var numberOfItems = 0
		
		if !isRootDataSource && sectionIndex == 0 {
			numberOfItems += items.count
		}
		
		numberOfItems += defaultMetrics?.supplementaryItemsByKind[kind]?.count ?? 0
		
		if let sectionMetrics = self.sectionMetrics[sectionIndex],
			metricsItems = sectionMetrics.supplementaryItemsByKind[kind] {
				numberOfItems += metricsItems.count
		}
		
		return numberOfItems
	}
	
	public func indexPaths(for supplementaryItem: SupplementaryItem) -> [NSIndexPath] {
		let kind = supplementaryItem.elementKind
		let supplementaryItems = supplementaryItemsOfKind(kind)
		
		if let itemIndex = supplementaryItems.indexOf({ $0.isEqual(to: supplementaryItem) }) {
			let indexPath = isRootDataSource ? NSIndexPath(index: itemIndex) : NSIndexPath(forItem: itemIndex, inSection: 0)
			return [indexPath]
		}
		
		let numberOfGlobalItems = supplementaryItems.count
		
		// If the item is in the default metrics, return an index path for each section
		if let sectionItems = defaultMetrics?.supplementaryItemsByKind[kind],
			itemIndex = sectionItems.indexOf({ $0.isEqual(to: supplementaryItem) }) {
				var result: [NSIndexPath] = []
				for sectionIndex in 0..<numberOfSections {
					var elementIndex = itemIndex
					if !isRootDataSource && sectionIndex == 0 {
						elementIndex += numberOfGlobalItems
					}
					let indexPath = NSIndexPath(forItem: elementIndex, inSection: sectionIndex)
					result.append(indexPath)
				}
				return result
		}
		
		let numberOfDefaultItems = defaultMetrics?.supplementaryItemsByKind[kind]?.count ?? 0
		var result: NSIndexPath?
		
		// If the supplementary metrics exist, it's in one of the section metrics
		for (sectionIndex, sectionMetrics) in self.sectionMetrics {
			guard let sectionItems = sectionMetrics.supplementaryItemsByKind[kind],
				itemIndex = sectionItems.indexOf({ $0.isEqual(to: supplementaryItem) }) else {
					continue
			}
			var elementIndex = itemIndex + numberOfDefaultItems
			if !isRootDataSource && sectionIndex == 0 {
				elementIndex += numberOfGlobalItems
			}
			result = NSIndexPath(forItem: elementIndex, inSection: sectionIndex)
			break
		}
		
		return [result].flatMap { $0 }
	}
	
	public func findSupplementaryItemOfKind(kind: String, at indexPath: NSIndexPath, using block: (dataSource: CollectionDataSource, localIndexPath: NSIndexPath, supplementaryItem: SupplementaryItem) -> Void) {
		let sectionIndex = indexPath.layoutSection
		var itemIndex = indexPath.itemIndex
		
		// Disable this assertion to allow contributed global supplementary views, unless it breaks
//		assert(sectionIndex != globalSectionIndex || isRootDataSource, "Should only have the global section when we're the root data source")
		
		let items = supplementaryItemsOfKind(kind)
		
		if isRootDataSource && sectionIndex == globalSectionIndex {
			if itemIndex < items.count {
				block(dataSource: dataSource, localIndexPath: indexPath, supplementaryItem: items[itemIndex])
			}
			return
		}
		
		if !isRootDataSource && sectionIndex == 0 {
			if itemIndex < items.count {
				return block(dataSource: dataSource, localIndexPath: indexPath, supplementaryItem: items[itemIndex])
			}
			// Need to allow for the items that were added from the "global" data source items
			itemIndex -= items.count
		}
		
		// Check for items in the default metrics
		if let defaultItems = defaultMetrics?.supplementaryItemsByKind[kind] {
			let defaultItemCount = defaultItems.count
			if itemIndex < defaultItemCount {
				let localIndexPath = NSIndexPath(forItem: itemIndex, inSection: sectionIndex)
				return block(dataSource: dataSource, localIndexPath: localIndexPath, supplementaryItem: defaultItems[itemIndex])
			}
			itemIndex -= defaultItemCount
		}
		
		let sectionMetrics = self.sectionMetrics[sectionIndex]
		if let metricsItems = sectionMetrics?.supplementaryItemsByKind[kind]
			where itemIndex < metricsItems.count {
				let localIndexPath = NSIndexPath(forItem: itemIndex, inSection: sectionIndex)
				return block(dataSource: dataSource, localIndexPath: localIndexPath, supplementaryItem: metricsItems[itemIndex])
		}
	}
	
	public func snapshotMetrics() -> [Int: DataSourceSectionMetricsProviding] {
		var metrics: [Int: DataSourceSectionMetricsProviding] = [:]
		
		let globalMetrics = snapshotMetricsForSectionAtIndex(globalSectionIndex)
		metrics[globalSectionIndex] = globalMetrics
		
		for sectionIndex in 0..<numberOfSections {
			let sectionMetrics = snapshotMetricsForSectionAtIndex(sectionIndex)
			metrics[sectionIndex] = sectionMetrics
		}
		
		return metrics
	}
	
	public func snapshotMetricsForSectionAtIndex(sectionIndex: Int) -> DataSourceSectionMetricsProviding? {
		guard var metrics = appliedMetricsForSection(at: sectionIndex) else {
			return nil
		}
		
		 // The root data source puts its items into the special global section; other data sources put theirs into their 0 section
		if isRootDataSource && sectionIndex == globalSectionIndex {
			metrics.supplementaryItemsByKind = supplementaryItemsByKind
		}
		else if !isRootDataSource && sectionIndex == 0 {
			// We need to handle global items and the placeholder view for section 0
			var newSupplementaryItemsByKind = supplementaryItemsByKind
			newSupplementaryItemsByKind.appendContents(of: metrics.supplementaryItemsByKind)
			metrics.supplementaryItemsByKind = newSupplementaryItemsByKind
		}
		
		// Stash the placeholder in the metrics; this is really only used so we can determine the range of the placeholders
		metrics.placeholder = placeholder
		
		return metrics
	}
	
	private func appliedMetricsForSection(at sectionIndex: Int) -> DataSourceSectionMetricsProviding? {
		guard var metrics = defaultMetrics else {
			return sectionMetrics[sectionIndex]
		}
		
		if let sectionMetrics = self.sectionMetrics[sectionIndex] {
			metrics.applyValues(from: sectionMetrics)
		}
		
		return metrics
	}
	
	public func snapshotContributedGlobalMetrics() -> DataSourceSectionMetricsProviding? {
		guard contributesGlobalMetrics else {
			return nil
		}
		return sectionMetrics[globalSectionIndex]
	}
	
	public func layoutIndexPathForItemIndex(itemIndex: Int, sectionIndex: Int) -> NSIndexPath {
		let isGlobalSection = sectionIndex == globalSectionIndex
		if isGlobalSection {
			return NSIndexPath(index: itemIndex)
		} else {
			return NSIndexPath(forItem: itemIndex, inSection: sectionIndex)
		}
	}
	
	public func add(supplementaryItem: SupplementaryItem) {
		dataSource.add(supplementaryItem)
	}
	
	public func add(supplementaryItem: SupplementaryItem, forSectionAtIndex sectionIndex: Int) {
		dataSource.add(supplementaryItem, forSectionAtIndex: sectionIndex)
	}
	
	public func add(supplementaryItem: SupplementaryItem, forKey key: String) {
		dataSource.add(supplementaryItem, forKey: key)
	}
	
	public func removeSupplementaryItemForKey(key: String) {
		dataSource.removeSupplementaryItemForKey(key)
	}
	
	public func replaceSupplementaryItemForKey(key: String, with supplementaryItem: SupplementaryItem) {
		dataSource.replaceSupplementaryItemForKey(key, with: supplementaryItem)
	}
	
	public func supplementaryItemsOfKind(kind: String) -> [SupplementaryItem] {
		return dataSource.supplementaryItemsOfKind(kind)
	}
	
	public func supplementaryItemForKey(key: String) -> SupplementaryItem? {
		return dataSource.supplementaryItemForKey(key)
	}
	
}
