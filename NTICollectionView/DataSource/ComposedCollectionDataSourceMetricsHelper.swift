//
//  ComposedCollectionDataSourceMetricsHelper.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/24/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

// FIXME: Code duplication with the segmented metrics helper
open class ComposedCollectionDataSourceMetricsHelper: CollectionDataSourceMetricsHelper {

	public init(composedDataSource: ComposedCollectionDataSource) {
		super.init(dataSource: composedDataSource)
	}
	
	open var composedDataSource: ComposedCollectionDataSource {
		return dataSource as! ComposedCollectionDataSource
	}
	
	open override func numberOfSupplementaryItemsOfKind(_ kind: String, inSectionAtIndex sectionIndex: Int, shouldIncludeChildDataSources: Bool) -> Int {
		var numberOfElements = super.numberOfSupplementaryItemsOfKind(kind, inSectionAtIndex: sectionIndex, shouldIncludeChildDataSources: false)
		if shouldIncludeChildDataSources,
			let mapping = composedDataSource.mappingForGlobalSection(sectionIndex),
			let localSection = mapping.localSectionForGlobalSection(sectionIndex) {
				let dataSource = mapping.dataSource
				numberOfElements += dataSource.numberOfSupplementaryItemsOfKind(kind, inSectionAtIndex: localSection, shouldIncludeChildDataSources: true)
		}
		return numberOfElements
	}
	
	open override func indexPaths(for supplementaryItem: SupplementaryItem) -> [IndexPath] {
		var result = super.indexPaths(for: supplementaryItem)
		if !result.isEmpty {
			return result as [IndexPath]
		}
		
		let kind = supplementaryItem.elementKind
		for mapping in composedDataSource.mappings {
			let dataSource = mapping.dataSource
			result = dataSource.indexPaths(for: supplementaryItem)
			result = mapping.globalIndexPathsForLocal(result)
			
			var adjusted: [IndexPath] = []
			for indexPath in result {
				let sectionIndex = indexPath.layoutSection
				let itemIndex = indexPath.itemIndex
				
				let numberOfElements = numberOfSupplementaryItemsOfKind(kind, inSectionAtIndex: sectionIndex, shouldIncludeChildDataSources: false)
				let elementIndex = itemIndex + numberOfElements
				let newIndexPath = layoutIndexPathForItemIndex(elementIndex, sectionIndex: sectionIndex)
				adjusted.append(newIndexPath)
			}
			
			guard adjusted.isEmpty else {
				break
			}
		}
		
		return result as [IndexPath]
	}
	
	open override func findSupplementaryItemOfKind(_ kind: String, at indexPath: IndexPath, using block: (_ dataSource: CollectionDataSource, _ localIndexPath: IndexPath, _ supplementaryItem: SupplementaryItem) -> Void) {
		let sectionIndex = indexPath.layoutSection
		var itemIndex = indexPath.itemIndex
		
		let numberOfElements = numberOfSupplementaryItemsOfKind(kind, inSectionAtIndex: sectionIndex, shouldIncludeChildDataSources: false)
		if itemIndex < numberOfElements {
			return super.findSupplementaryItemOfKind(kind, at: indexPath, using: block)
		}
		
		itemIndex -= numberOfElements
		
		guard let mapping = composedDataSource.mappingForGlobalSection(sectionIndex),
			let localSection = mapping.localSectionForGlobalSection(sectionIndex) else {
				return
		}
		
		let localIndexPath = IndexPath(item: itemIndex, section: localSection)
		let dataSource = mapping.dataSource
		dataSource.findSupplementaryItemOfKind(kind, at: localIndexPath, using: block)
	}
	
	open override func snapshotMetricsForSectionAtIndex(_ sectionIndex: Int) -> DataSourceSectionMetricsProviding? {
		guard var enclosingMetrics = super.snapshotMetricsForSectionAtIndex(sectionIndex) else {
			return nil
		}
		
		guard let mapping = composedDataSource.mappingForGlobalSection(sectionIndex) else {
			return enclosingMetrics
		}
		let dataSource = mapping.dataSource
		if let localSection = mapping.localSectionForGlobalSection(sectionIndex),
			let metrics = dataSource.snapshotMetricsForSectionAtIndex(localSection)  {
				enclosingMetrics.applyValues(from: metrics)
		}
		return enclosingMetrics
	}
	
}
