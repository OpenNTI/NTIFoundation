//
//  SegmentedCollectionDataSourceMetricsHelper.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/24/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

// FIXME: Code duplication with the composed metrics helper
public class SegmentedCollectionDataSourceMetricsHelper: CollectionDataSourceMetricsHelper {

	public init(segmentedDataSource: SegmentedCollectionDataSource) {
		super.init(dataSource: segmentedDataSource)
	}
	
	public var segmentedDataSource: SegmentedCollectionDataSource {
		return dataSource as! SegmentedCollectionDataSource
	}
	
	var selectedDataSource: CollectionDataSource? {
		return segmentedDataSource.selectedDataSource
	}
	
	public override func numberOfSupplementaryItemsOfKind(kind: String, inSectionAtIndex sectionIndex: Int, shouldIncludeChildDataSources: Bool) -> Int {
		var numberOfItems = super.numberOfSupplementaryItemsOfKind(kind, inSectionAtIndex: sectionIndex, shouldIncludeChildDataSources: false)
		if shouldIncludeChildDataSources {
			numberOfItems += selectedDataSource?.numberOfSupplementaryItemsOfKind(kind, inSectionAtIndex: sectionIndex, shouldIncludeChildDataSources: true) ?? 0
		}
		return numberOfItems
	}
	
	public override func indexPaths(for supplementaryItem: SupplementaryItem) -> [NSIndexPath] {
		var result = super.indexPaths(for: supplementaryItem)
		if !result.isEmpty {
			return result
		}
		
		// If the metrics aren't defined on this data source, check the selected data source
		guard let selectedDataSource = self.selectedDataSource else {
			return []
		}
		result = selectedDataSource.indexPaths(for: supplementaryItem)
		
		// Need to update the index paths of the selected data source to reflect any items defined in this data source
		var adjusted: [NSIndexPath] = []
		let kind = supplementaryItem.elementKind
		
		for indexPath in result {
			let sectionIndex = indexPath.layoutSection
			let itemIndex = indexPath.itemIndex
			
			let numberOfItems = numberOfSupplementaryItemsOfKind(kind, inSectionAtIndex: sectionIndex, shouldIncludeChildDataSources: false)
			let elementIndex = itemIndex + numberOfItems
			let newIndexPath = layoutIndexPathForItemIndex(elementIndex, sectionIndex: sectionIndex)
			adjusted.append(newIndexPath)
		}
		return adjusted
	}
	
	public override func findSupplementaryItemOfKind(kind: String, at indexPath: NSIndexPath, using block: (dataSource: CollectionDataSource, localIndexPath: NSIndexPath, supplementaryItem: SupplementaryItem) -> Void) {
		let sectionIndex = indexPath.layoutSection
		var itemIndex = indexPath.itemIndex
		
		let numberOfElements = numberOfSupplementaryItemsOfKind(kind, inSectionAtIndex: sectionIndex, shouldIncludeChildDataSources: false)
		if itemIndex < numberOfElements {
			return super.findSupplementaryItemOfKind(kind, at: indexPath, using: block)
		}
		
		itemIndex -= numberOfElements
		let childIndexPath = layoutIndexPathForItemIndex(itemIndex, sectionIndex: sectionIndex)
		selectedDataSource?.findSupplementaryItemOfKind(kind, at: childIndexPath, using: block)
	}
	
	public override func snapshotMetricsForSectionAtIndex(sectionIndex: Int) -> DataSourceSectionMetricsProviding? {
		guard var enclosingMetrics = super.snapshotMetricsForSectionAtIndex(sectionIndex) else {
			return nil
		}
		if let metrics = snapshotChildMetrics(forSectionAt: sectionIndex) {
			enclosingMetrics.applyValues(from: metrics)
		}
		return enclosingMetrics
	}
	
	private func snapshotChildMetrics(forSectionAt sectionIndex: Int) -> DataSourceSectionMetricsProviding? {
		guard let selectedDataSource = self.selectedDataSource else {
			return nil
		}
		if sectionIndex == globalSectionIndex {
			return selectedDataSource.snapshotContributedGlobalMetrics()
		}
		else {
			return selectedDataSource.snapshotMetricsForSectionAtIndex(sectionIndex)
		}
	}
	
}
