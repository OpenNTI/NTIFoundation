//
//  ComposedCollectionDataSource.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/23/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public protocol ComposedCollectionDataSourceProtocol: ParentCollectionDataSource {
	
	var mappings: [DataSourceMapping] { get }
	
	func mappingForGlobalSection(section: Int) -> DataSourceMapping?
	
}

/// A data source that is composed of other data sources.
public class ComposedCollectionDataSource: AbstractCollectionDataSource, ComposedCollectionDataSourceProtocol {
	
	private var _numberOfSections = 0
	
	public private(set) var mappings: [DataSourceMapping] = []
	private var dataSourceToMappings = NSMapTable(keyOptions: NSMapTableObjectPointerPersonality, valueOptions: NSMapTableStrongMemory, capacity: 1)
	private var globalSectionToMappings: [Int: DataSourceMapping] = [:]
	
	public var dataSources: [CollectionDataSource] {
		var dataSources: [CollectionDataSource] = []
		for key in dataSourceToMappings.keyEnumerator() {
			let mapping = dataSourceToMappings.objectForKey(key) as! DataSourceMapping
			dataSources.append(mapping.dataSource)
		}
		return dataSources
	}
	
	/// Add a data source to the data source.
	public func add(dataSource: CollectionDataSource) {
		dataSource.delegate = self
		
		assert(mapping(`for`: dataSource) == nil, "Tried to add data source more than once: \(dataSource)")
		
		let mappingForDataSource = BasicDataSourceMapping(dataSource: dataSource)
		mappings.append(mappingForDataSource)
		dataSourceToMappings.setObject(mappingForDataSource, forKey: dataSource)
		
		updateMappings()
		let addedSections = NSMutableIndexSet()
		let numberOfSections = dataSource.numberOfSections
		for sectionIdx in 0..<numberOfSections {
			let section = mappingForDataSource.globalSectionForLocalSection(sectionIdx)
			addedSections.addIndex(section)
		}
		notifySectionsInserted(addedSections)
	}
	
	/// Remove the specified data source from this data source.
	public func remove(dataSource: CollectionDataSource) {
		guard let mappingForDataSoure = mapping(`for`: dataSource) else {
			preconditionFailure("Data source not found in mapping")
		}
		
		let removedSections = NSMutableIndexSet()
		let numberOfSections = dataSource.numberOfSections
		
		for sectionIdx in 0..<numberOfSections {
			let section = mappingForDataSoure.globalSectionForLocalSection(sectionIdx)
			removedSections.addIndex(section)
		}
		
		dataSourceToMappings.removeObjectForKey(dataSource)
		if let idx = mappings.indexOf({ $0 === mappingForDataSoure }) {
			mappings.removeAtIndex(idx)
		}
		
		dataSource.delegate = nil
		
		updateMappings()
		
		notifySectionsRemoved(removedSections)
	}
	
	private func updateMappings() {
		_numberOfSections = 0
		globalSectionToMappings.removeAll(keepCapacity: true)
		
		for mapping in mappings {
			mapping.updateMappingStartingAtGlobalSection(_numberOfSections, withUpdater: { sectionIndex in
				self.globalSectionToMappings[sectionIndex] = mapping
			})
			_numberOfSections += mapping.numberOfSections
		}
	}
	
	private func section(`for` dataSource: CollectionDataSource) -> Int? {
		let mapping = self.mapping(`for`: dataSource)
		return mapping?.globalSectionForLocalSection(0)
	}
	
	public override func dataSourceForSectionAtIndex(sectionIndex: Int) -> CollectionDataSource {
		let mapping = globalSectionToMappings[sectionIndex]!
		return mapping.dataSource
	}
	
	public override func localIndexPathForGlobal(globalIndexPath: NSIndexPath) -> NSIndexPath {
		let mapping = mappingForGlobalSection(globalIndexPath.section)!
		return mapping.localIndexPathForGlobal(globalIndexPath)
	}
	
	public func mappingForGlobalSection(section: Int) -> DataSourceMapping? {
		let mapping = globalSectionToMappings[section]
		return mapping
	}
	
	private func mapping(`for` dataSource: CollectionDataSource) -> DataSourceMapping? {
		return dataSourceToMappings.objectForKey(dataSource) as? DataSourceMapping
	}
	
	private func globalSectionsForLocal(localSections: NSIndexSet, dataSource: CollectionDataSource) -> [Int] {
		guard let mapping = self.mapping(`for`: dataSource) else {
			return []
		}
		return localSections.flatMap { mapping.globalSectionForLocalSection($0) }
	}
	
	private func globalIndexPathsForLocal(localIndexPaths: [NSIndexPath], dataSource: CollectionDataSource) -> [NSIndexPath] {
		guard let mapping = self.mapping(`for`: dataSource) else {
			return []
		}
		return localIndexPaths.flatMap { mapping.globalIndexPathForLocal($0) }
	}
	
	public override func item(at indexPath: NSIndexPath) -> Item? {
		let mapping = mappingForGlobalSection(indexPath.section)!
		let mappedIndexPath = mapping.localIndexPathForGlobal(indexPath)
		return mapping.dataSource.item(at: mappedIndexPath)
	}
	
	public override func indexPath(`for` item: Item) -> NSIndexPath? {
		for dataSource in dataSources {
			guard let indexPath = dataSource.indexPath(`for`: item),
				mapping = self.mapping(`for`: dataSource) else {
					continue
			}
			return mapping.globalIndexPathForLocal(indexPath)
		}
		return nil
	}
	
	public override func removeItem(at indexPath: NSIndexPath) {
		let mapping = mappingForGlobalSection(indexPath.section)!
		let dataSource = mapping.dataSource
		let localIndexPath = mapping.localIndexPathForGlobal(indexPath)
		dataSource.removeItem(at: localIndexPath)
	}
	
	public override func registerReusableViews(with collectionView: UICollectionView) {
		super.registerReusableViews(with: collectionView)
		for dataSource in dataSources {
			dataSource.registerReusableViews(with: collectionView)
		}
	}
	
	public override func didBecomeActive() {
		super.didBecomeActive()
		for dataSource in dataSources {
			dataSource.didBecomeActive()
		}
	}
	
	public override func willResignActive() {
		super.willResignActive()
		for dataSource in dataSources {
			dataSource.willResignActive()
		}
	}
	
	public override func presentActivityIndicator(forSections sections: NSIndexSet?) {
		var sections = sections
		if loadingState == .LoadingContent {
			sections = indexesOfAllSections
		}
		super.presentActivityIndicator(forSections: sections)
	}
	
	public override func update(placeholderView: CollectionPlaceholderView?, forSectionAtIndex sectionIndex: Int) {
		if sectionIndex == 0 && (shouldShowActivityIndicator || shouldShowPlaceholder) {
			super.update(placeholderView, forSectionAtIndex: sectionIndex)
			return
		}
		
		let mapping = mappingForGlobalSection(sectionIndex)!
		let dataSource = mapping.dataSource
		let localSectionIndex = mapping.localSectionForGlobalSection(sectionIndex)
		dataSource.update(placeholderView, forSectionAtIndex: localSectionIndex)
	}
	
	// MARK: - CollectionDataSource
	
	public override var numberOfSections: Int {
		updateMappings()
		return _numberOfSections
	}
	
	// MARK: - Metrics
	
	public override var metricsHelper: CollectionDataSourceMetrics {
		return ComposedCollectionDataSourceMetricsHelper(composedDataSource: self)
	}
	
	// MARK: - Subclass hooks
	
	public override func collectionView(collectionView: UICollectionView, canEditItemAt indexPath: NSIndexPath) -> Bool {
		let info = mappingInfoForGlobalIndexPath(indexPath, collectionView: collectionView)!
		return info.dataSource.collectionView(info.wrapper, canEditItemAt: info.localIndexPath)
	}
	
	public override func collectionView(collectionView: UICollectionView, canMoveItemAt indexPath: NSIndexPath, to destinationIndexPath: NSIndexPath) -> Bool {
		// If the move is between data sources, assume false
		let fromMapping = mappingForGlobalSection(indexPath.section)!
		let toMapping = mappingForGlobalSection(destinationIndexPath.section)!
		guard fromMapping === toMapping else {
			return false
		}
		let wrapper = WrapperCollectionView(collectionView: collectionView, mapping: fromMapping)
		
		let localFromIndexPath = fromMapping.localIndexPathForGlobal(indexPath)
		let localToIndexPath = fromMapping.localIndexPathForGlobal(destinationIndexPath)
		
		let dataSource = fromMapping.dataSource
		return dataSource.collectionView(wrapper, canMoveItemAt: localFromIndexPath, to: localToIndexPath)
	}
	
	// MARK: - UICollectionViewDataSource
	
	public override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		updateMappings()
		
		guard !shouldShowPlaceholder else {
			return 0
		}
		
		let mapping = mappingForGlobalSection(section)!
		let wrapper = WrapperCollectionView(collectionView: collectionView, mapping: mapping)
		let localSection = mapping.localSectionForGlobalSection(section)
		let dataSource = mapping.dataSource
		
		let numberOfSections = dataSource.numberOfSectionsInCollectionView!(wrapper)
		precondition(localSection < numberOfSections, "Local section \(localSection) is out of bounds for composed data source with \(numberOfSections) sections.")
		
		return dataSource.collectionView(wrapper, numberOfItemsInSection: localSection)
	}
	
	public override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let info = mappingInfoForGlobalIndexPath(indexPath, collectionView: collectionView)!
		return info.dataSource.collectionView(info.wrapper, cellForItemAtIndexPath: info.localIndexPath)
	}
	
	public override func collectionView(collectionView: UICollectionView, canMoveItemAt indexPath: NSIndexPath) -> Bool {
		let info = mappingInfoForGlobalIndexPath(indexPath, collectionView: collectionView)!
		return info.dataSource.collectionView(info.wrapper, canMoveItemAt: info.localIndexPath)
	}
	
	public override func collectionView(collectionView: UICollectionView, moveItemAt sourceIndexPath: NSIndexPath, to destinationIndexPath: NSIndexPath) {
		// Don't allow moves between data sources
		let fromMapping = mappingForGlobalSection(sourceIndexPath.section)!
		let toMapping = mappingForGlobalSection(destinationIndexPath.section)!
		guard fromMapping === toMapping else {
			return
		}
		let wrapper = WrapperCollectionView(collectionView: collectionView, mapping: fromMapping)
		let dataSource = fromMapping.dataSource
		
		let localFromIndexPath = fromMapping.localIndexPathForGlobal(sourceIndexPath)
		let localToIndexPath = fromMapping.localIndexPathForGlobal(destinationIndexPath)
		
		dataSource.collectionView(wrapper, moveItemAt: localFromIndexPath, to: localToIndexPath)
	}
	
	// MARK: - ContentLoading
	
	public override func endLoadingContent(with state: LoadState, error: NSError?, update: (() -> Void)?) {
		guard state != .NoContent && state != .Error else {
			super.endLoadingContent(with: state, error: error, update: update)
			return
		}
		
		assert(state == .ContentLoaded, "Expect to be in loaded state")
		
		// We need to wait for all the loading child data sources to complete
		let loadingGroup = dispatch_group_create()
		for dataSource in dataSources {
			let loadingState = dataSource.loadingState
			// Skip data sources that aren't loading
			guard loadingState == .LoadingContent || loadingState == .RefreshingContent else {
				continue
			}
			dispatch_group_enter(loadingGroup)
			dataSource.whenLoaded {
				dispatch_group_leave(loadingGroup)
			}
		}
		
		// When all the child data sources have loaded, we need to figure out what the result state is.
		dispatch_group_notify(loadingGroup, dispatch_get_main_queue()) {
			let resultSet = Set<LoadState>(self.dataSources.map { $0.loadingState })
			var finalState = state
			if resultSet.count == 1 && resultSet.contains(.NoContent) {
				finalState = .NoContent
			}
			super.endLoadingContent(with: finalState, error: error, update: update)
		}
	}
	
	public override func beginLoadingContent(with progress: LoadingProgress) {
		for dataSource in dataSources {
			dataSource.loadContent()
		}
		loadContent(with: progress)
	}
	
	public override func resetContent() {
		super.resetContent()
		for dataSource in dataSources {
			dataSource.resetContent()
		}
	}
	
	// MARK: - CollectionDataSourceDelegate
	
	public func dataSource(dataSource: CollectionDataSource, didInsertItemsAt indexPaths: [NSIndexPath]) {
		let globalIndexPaths = self.globalIndexPaths(`for`: dataSource, localIndexPaths: indexPaths)
		notifyItemsInserted(at: globalIndexPaths)
	}
	
	public func dataSource(dataSource: CollectionDataSource, didRemoveItemsAt indexPaths: [NSIndexPath]) {
		let globalIndexPaths = self.globalIndexPaths(`for`: dataSource, localIndexPaths: indexPaths)
		notifyItemsRemoved(at: globalIndexPaths)
	}
	
	public func dataSource(dataSource: CollectionDataSource, didRefreshItemsAt indexPaths: [NSIndexPath]) {
		let globalIndexPaths = self.globalIndexPaths(`for`: dataSource, localIndexPaths: indexPaths)
		notifyItemsRefreshed(at: globalIndexPaths)
	}
	
	private func globalIndexPaths(`for` dataSource: CollectionDataSource, localIndexPaths: [NSIndexPath]) -> [NSIndexPath] {
		return mapping(`for`: dataSource)!.globalIndexPathsForLocal(localIndexPaths)
	}
	
	public func dataSource(dataSource: CollectionDataSource, didMoveItemAt oldIndexPath: NSIndexPath, to newIndexPath: NSIndexPath) {
		let mapping = self.mapping(`for`: dataSource)!
		let globalFromIndexPath = mapping.globalIndexPathForLocal(oldIndexPath)
		let globalToIndexPath = mapping.globalIndexPathForLocal(newIndexPath)
		notifyItemMoved(from: globalFromIndexPath, to: globalToIndexPath)
	}
	
	public func dataSource(dataSource: CollectionDataSource, didInsertSections sections: NSIndexSet, direction: SectionOperationDirection?) {
		let mapping = self.mapping(`for`: dataSource)!
		updateMappings()
		let globalSections = mapping.globalSectionsForLocalSections(sections)
		notifySectionsInserted(globalSections, direction: direction)
	}
	
	public func dataSource(dataSource: CollectionDataSource, didRemoveSections sections: NSIndexSet, direction: SectionOperationDirection?) {
		let mapping = self.mapping(`for`: dataSource)!
		updateMappings()
		let globalSections = mapping.globalSectionsForLocalSections(sections)
		notifySectionsRemoved(globalSections, direction: direction)
	}
	
	public func dataSource(dataSource: CollectionDataSource, didRefreshSections sections: NSIndexSet) {
		let mapping = self.mapping(`for`: dataSource)!
		let globalSections = mapping.globalSectionsForLocalSections(sections)
		notifySectionsRefreshed(globalSections)
		updateMappings()
	}
	
	public func dataSource(dataSource: CollectionDataSource, didMoveSectionFrom oldSection: Int, to newSection: Int, direction: SectionOperationDirection?) {
		let mapping = self.mapping(`for`: dataSource)!
		let globalOldSection = mapping.globalSectionForLocalSection(oldSection)
		let globalNewSection = mapping.globalSectionForLocalSection(newSection)
		updateMappings()
		notifySectionsMoved(from: globalOldSection, to: globalNewSection, direction: direction)
	}
	
	public func dataSourceDidReloadData(dataSource: CollectionDataSource) {
		notifyDidReloadData()
	}
	
	public func dataSource(dataSource: CollectionDataSource, performBatchUpdate update: () -> Void, complete: (() -> Void)?) {
		performUpdate(update, complete: complete)
	}
	
	public func dataSource(dataSource: CollectionDataSource, didPresentActivityIndicatorForSections sections: NSIndexSet) {
		let mapping = self.mapping(`for`: dataSource)!
		let globalSections = mapping.globalSectionsForLocalSections(sections)
		presentActivityIndicator(forSections: globalSections)
	}
	
	public func dataSource(dataSource: CollectionDataSource, didPresentPlaceholderForSections sections: NSIndexSet) {
		let mapping = self.mapping(`for`: dataSource)!
		let globalSections = mapping.globalSectionsForLocalSections(sections)
		present(nil, forSections: globalSections)
	}
	
	public func dataSource(dataSource: CollectionDataSource, didDismissPlaceholderForSections sections: NSIndexSet) {
		let mapping = self.mapping(`for`: dataSource)!
		let globalSections = mapping.globalSectionsForLocalSections(sections)
		dismissPlaceholder(forSections: globalSections)
	}
	
	public func dataSource(dataSource: CollectionDataSource, didUpdate supplementaryItem: SupplementaryItem, at indexPaths: [NSIndexPath]) {
		let mapping = self.mapping(`for`: dataSource)!
		let globalIndexPaths = mapping.globalIndexPathsForLocal(indexPaths)
		notifyContentUpdated(`for`: supplementaryItem, at: globalIndexPaths)
	}
	
}

// MARK: - Helpers

private typealias MappingInfo = (dataSource: CollectionDataSource, localIndexPath: NSIndexPath, wrapper: WrapperCollectionView)

extension ComposedCollectionDataSource {
	
	private func mappingInfoForGlobalIndexPath(globalIndexPath: NSIndexPath, collectionView: UICollectionView) -> MappingInfo? {
		guard let mapping = mappingForGlobalSection(globalIndexPath.section) else {
			return nil
		}
		let dataSource = mapping.dataSource
		let localIndexPath = mapping.localIndexPathForGlobal(globalIndexPath)
		let wrapper = WrapperCollectionView(collectionView: collectionView, mapping: mapping)
		return (dataSource, localIndexPath, wrapper)
	}
	
}
