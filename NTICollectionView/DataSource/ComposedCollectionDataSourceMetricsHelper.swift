//
//  ComposedCollectionDataSourceMetricsHelper.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/24/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

// FIXME: Code duplication with the segmented metrics helper
public class ComposedCollectionDataSourceMetricsHelper: CollectionDataSourceMetricsHelper {

	public init(composedDataSource: ComposedCollectionDataSourceProtocol) {
		super.init(dataSource: composedDataSource)
	}
	
	public var composedDataSource: ComposedCollectionDataSourceProtocol {
		return dataSource as! ComposedCollectionDataSourceProtocol
	}
	
	public override func numberOfSupplementaryItemsOfKind(kind: String, inSectionAtIndex sectionIndex: Int, shouldIncludeChilDataSources: Bool) -> Int {
		var numberOfElements = super.numberOfSupplementaryItemsOfKind(kind, inSectionAtIndex: sectionIndex, shouldIncludeChilDataSources: false)
		if shouldIncludeChilDataSources, let mapping = composedDataSource.mappingForGlobalSection(sectionIndex) {
			let localSection = mapping.localSectionForGlobalSection(sectionIndex)
			let dataSource = mapping.dataSource
			numberOfElements += dataSource.numberOfSupplementaryItemsOfKind(kind, inSectionAtIndex: localSection, shouldIncludeChilDataSources: true)
		}
		return numberOfElements
	}
	
	public override func indexPaths(`for` supplementaryItem: SupplementaryItem) -> [NSIndexPath] {
		var result = super.indexPaths(`for`: supplementaryItem)
		if !result.isEmpty {
			return result
		}
		
		let kind = supplementaryItem.elementKind
		for mapping in composedDataSource.mappings {
			let dataSource = mapping.dataSource
			result = dataSource.indexPaths(`for`: supplementaryItem)
			result = mapping.globalIndexPathsForLocal(result)
			
			var adjusted: [NSIndexPath] = []
			for indexPath in result {
				let sectionIndex = indexPath.layoutSection
				let itemIndex = indexPath.itemIndex
				
				let numberOfElements = numberOfSupplementaryItemsOfKind(kind, inSectionAtIndex: sectionIndex, shouldIncludeChilDataSources: false)
				let elementIndex = itemIndex + numberOfElements
				let newIndexPath = layoutIndexPathForItemIndex(elementIndex, sectionIndex: sectionIndex)
				adjusted.append(newIndexPath)
			}
			
			guard adjusted.isEmpty else {
				break
			}
		}
		
		return result
	}
	
	public override func findSupplementaryItemOfKind(kind: String, at indexPath: NSIndexPath, using block: (dataSource: CollectionDataSource, localIndexPath: NSIndexPath, supplementaryItem: SupplementaryItem) -> Void) {
		let sectionIndex = indexPath.layoutSection
		var itemIndex = indexPath.itemIndex
		
		let numberOfElements = numberOfSupplementaryItemsOfKind(kind, inSectionAtIndex: sectionIndex, shouldIncludeChilDataSources: false)
		if itemIndex < numberOfElements {
			return super.findSupplementaryItemOfKind(kind, at: indexPath, using: block)
		}
		
		itemIndex -= numberOfElements
		
		guard let mapping = composedDataSource.mappingForGlobalSection(sectionIndex) else {
			return
		}
		let localSection = mapping.localSectionForGlobalSection(sectionIndex)
		
		let localIndexPath = NSIndexPath(forItem: itemIndex, inSection: localSection)
		let dataSource = mapping.dataSource
		dataSource.findSupplementaryItemOfKind(kind, at: localIndexPath, using: block)
	}
	
	public override func snapshotMetricsForSectionAtIndex(sectionIndex: Int) -> DataSourceSectionMetrics? {
		guard let mapping = composedDataSource.mappingForGlobalSection(sectionIndex) else {
			return nil
		}
		let dataSource = mapping.dataSource
		
		guard let enclosingMetrics = super.snapshotMetricsForSectionAtIndex(sectionIndex) else {
			return nil
		}
		let localSection = mapping.localSectionForGlobalSection(sectionIndex)
		if let metrics = dataSource.snapshotMetricsForSectionAtIndex(localSection)  {
			enclosingMetrics.applyValues(from: metrics)
		}
		return enclosingMetrics
	}
	
}
