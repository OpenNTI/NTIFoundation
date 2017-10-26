//
//  CollectionDataSourceMetricsHelper.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/22/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

open class CollectionDataSourceMetricsHelper: NSObject, CollectionDataSourceMetrics {
	
	public init(dataSource: CollectionDataSource) {
		self.dataSource = dataSource
		super.init()
	}
	
	open weak var dataSource: CollectionDataSource!
	
	var isRootDataSource: Bool {
		return dataSource.isRootDataSource
	}
	
	var numberOfSections: Int {
		return dataSource.numberOfSections
	}
	
	var placeholder: DataSourcePlaceholder? {
		return dataSource.placeholder
	}
	
	open var supplementaryItemsByKind: [String: [SupplementaryItem]] {
		return dataSource.supplementaryItemsByKind
	}
	open var sectionMetrics: [Int: DataSourceSectionMetricsProviding] {
		return dataSource.sectionMetrics
	}
	open var defaultMetrics: DataSourceSectionMetricsProviding? {
		get {
			return dataSource.defaultMetrics
		}
		set {
			dataSource.defaultMetrics = newValue
		}
	}
	open var globalMetrics: DataSourceSectionMetricsProviding? {
		get {
			return dataSource.metricsForSectionAtIndex(globalSectionIndex)
		}
		set {
			dataSource.setMetrics(newValue, forSectionAtIndex: globalSectionIndex)
		}
	}
	
	open var contributesGlobalMetrics: Bool {
		get {
			return dataSource.contributesGlobalMetrics
		}
		set {
			dataSource.contributesGlobalMetrics = newValue
		}
	}
	
	open func supplementaryItem(for key: String) -> SupplementaryItem? {
		return dataSource.supplementaryItem(for: key)
	}
	
	/// Retrieve the layout metrics for a specific section within this data source.
	open func metricsForSectionAtIndex(_ sectionIndex: Int) -> DataSourceSectionMetricsProviding? {
		return dataSource.metricsForSectionAtIndex(sectionIndex)
	}
	
	/// Store customized layout metrics for a section in this data source. The values specified in metrics will override values specified by the data source's `defaultMetrics`.
	open func setMetrics(_ metrics: DataSourceSectionMetricsProviding?, forSectionAtIndex sectionIndex: Int) {
		dataSource.setMetrics(metrics, forSectionAtIndex: sectionIndex)
	}
	
	open func numberOfSupplementaryItemsOfKind(_ kind: String, inSectionAtIndex sectionIndex: Int, shouldIncludeChildDataSources: Bool) -> Int {
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
			let metricsItems = sectionMetrics.supplementaryItemsByKind[kind] {
				numberOfItems += metricsItems.count
		}
		
		return numberOfItems
	}
	
	open func indexPaths(for supplementaryItem: SupplementaryItem) -> [IndexPath] {
		let kind = supplementaryItem.elementKind
		let supplementaryItems = supplementaryItemsOfKind(kind)
		
		if let itemIndex = supplementaryItems.index(where: { $0.isEqual(to: supplementaryItem) }) {
			let indexPath = isRootDataSource ? IndexPath(index: itemIndex) : IndexPath(item: itemIndex, section: 0)
			return [indexPath]
		}
		
		let numberOfGlobalItems = supplementaryItems.count
		
		// If the item is in the default metrics, return an index path for each section
		if let sectionItems = defaultMetrics?.supplementaryItemsByKind[kind],
			let itemIndex = sectionItems.index(where: { $0.isEqual(to: supplementaryItem) }) {
				var result: [IndexPath] = []
				for sectionIndex in 0..<numberOfSections {
					var elementIndex = itemIndex
					if !isRootDataSource && sectionIndex == 0 {
						elementIndex += numberOfGlobalItems
					}
					let indexPath = IndexPath(item: elementIndex, section: sectionIndex)
					result.append(indexPath)
				}
				return result
		}
		
		let numberOfDefaultItems = defaultMetrics?.supplementaryItemsByKind[kind]?.count ?? 0
		var result: IndexPath?
		
		// If the supplementary metrics exist, it's in one of the section metrics
		for (sectionIndex, sectionMetrics) in self.sectionMetrics {
			guard let sectionItems = sectionMetrics.supplementaryItemsByKind[kind],
				let itemIndex = sectionItems.index(where: { $0.isEqual(to: supplementaryItem) }) else {
					continue
			}
			var elementIndex = itemIndex + numberOfDefaultItems
			if !isRootDataSource && sectionIndex == 0 {
				elementIndex += numberOfGlobalItems
			}
			result = IndexPath(item: elementIndex, section: sectionIndex)
			break
		}
		
		return [result].flatMap { $0 }
	}
	
	open func findSupplementaryItemOfKind(_ kind: String, at indexPath: IndexPath, using block: (_ dataSource: CollectionDataSource, _ localIndexPath: IndexPath, _ supplementaryItem: SupplementaryItem) -> Void) {
		let sectionIndex = indexPath.layoutSection
		var itemIndex = indexPath.itemIndex
		
		// Disable this assertion to allow contributed global supplementary views, unless it breaks
//		assert(sectionIndex != globalSectionIndex || isRootDataSource, "Should only have the global section when we're the root data source")
		
		let items = supplementaryItemsOfKind(kind)
		
		if isRootDataSource && sectionIndex == globalSectionIndex {
			if itemIndex < items.count {
				block(dataSource, indexPath, items[itemIndex])
			}
			return
		}
		
		if !isRootDataSource && sectionIndex == 0 {
			if itemIndex < items.count {
				return block(dataSource, indexPath, items[itemIndex])
			}
			// Need to allow for the items that were added from the "global" data source items
			itemIndex -= items.count
		}
		
		// Check for items in the default metrics
		if let defaultItems = defaultMetrics?.supplementaryItemsByKind[kind] {
			let defaultItemCount = defaultItems.count
			if itemIndex < defaultItemCount {
				let localIndexPath = IndexPath(item: itemIndex, section: sectionIndex)
				return block(dataSource, localIndexPath, defaultItems[itemIndex])
			}
			itemIndex -= defaultItemCount
		}
		
		let sectionMetrics = self.sectionMetrics[sectionIndex]
		if let metricsItems = sectionMetrics?.supplementaryItemsByKind[kind], itemIndex < metricsItems.count {
				let localIndexPath = IndexPath(item: itemIndex, section: sectionIndex)
				return block(dataSource, localIndexPath, metricsItems[itemIndex])
		}
	}
	
	open func snapshotMetrics() -> [Int: DataSourceSectionMetricsProviding] {
		var metrics: [Int: DataSourceSectionMetricsProviding] = [:]
		
		let globalMetrics = snapshotMetricsForSectionAtIndex(globalSectionIndex)
		metrics[globalSectionIndex] = globalMetrics
		
		for sectionIndex in 0..<numberOfSections {
			let sectionMetrics = snapshotMetricsForSectionAtIndex(sectionIndex)
			metrics[sectionIndex] = sectionMetrics
		}
		
		return metrics
	}
	
	open func snapshotMetricsForSectionAtIndex(_ sectionIndex: Int) -> DataSourceSectionMetricsProviding? {
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
	
	fileprivate func appliedMetricsForSection(at sectionIndex: Int) -> DataSourceSectionMetricsProviding? {
		guard var metrics = defaultMetrics else {
			return sectionMetrics[sectionIndex]
		}
		
		if let sectionMetrics = self.sectionMetrics[sectionIndex] {
			metrics.applyValues(from: sectionMetrics)
		}
		
		return metrics
	}
	
	open func snapshotContributedGlobalMetrics() -> DataSourceSectionMetricsProviding? {
		guard contributesGlobalMetrics else {
			return nil
		}
		return sectionMetrics[globalSectionIndex]
	}
	
	open func layoutIndexPathForItemIndex(_ itemIndex: Int, sectionIndex: Int) -> IndexPath {
		let isGlobalSection = sectionIndex == globalSectionIndex
		if isGlobalSection {
			return IndexPath(index: itemIndex)
		} else {
			return IndexPath(item: itemIndex, section: sectionIndex)
		}
	}
	
	open func add(_ supplementaryItem: SupplementaryItem) {
		dataSource.add(supplementaryItem)
	}
	
	open func add(_ supplementaryItem: SupplementaryItem, forSectionAtIndex sectionIndex: Int) {
		dataSource.add(supplementaryItem, forSectionAtIndex: sectionIndex)
	}
	
	open func add(_ supplementaryItem: SupplementaryItem, forKey key: String) {
		dataSource.add(supplementaryItem, forKey: key)
	}
	
	open func removeSupplementaryItemForKey(_ key: String) {
		dataSource.removeSupplementaryItemForKey(key)
	}
	
	open func replaceSupplementaryItemForKey(_ key: String, with supplementaryItem: SupplementaryItem) {
		dataSource.replaceSupplementaryItemForKey(key, with: supplementaryItem)
	}
	
	open func supplementaryItemsOfKind(_ kind: String) -> [SupplementaryItem] {
		return dataSource.supplementaryItemsOfKind(kind)
	}
	
	open func supplementaryItemForKey(_ key: String) -> SupplementaryItem? {
		return dataSource.supplementaryItemForKey(key)
	}
	
}
