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
	
	func mappingForGlobalSection(_ section: Int) -> DataSourceMapping?
	
}

/// A data source that is composed of other data sources.
open class ComposedCollectionDataSource: CollectionDataSource, CollectionDataSourceDelegate {
	
	fileprivate var _numberOfSections = 0
	
	open fileprivate(set) var mappings: [DataSourceMapping] = []
	fileprivate var dataSourceToMappings = NSMapTable<AnyObject, AnyObject>(keyOptions: NSMapTableObjectPointerPersonality, valueOptions: NSMapTableStrongMemory, capacity: 1)
	fileprivate var globalSectionToMappings: [Int: DataSourceMapping] = [:]
	
	open var dataSources: [CollectionDataSource] {
		var dataSources: [CollectionDataSource] = []
		for key in dataSourceToMappings.keyEnumerator() {
			let mapping = dataSourceToMappings.object(forKey: key as AnyObject?) as! DataSourceMapping
			dataSources.append(mapping.dataSource)
		}
		return dataSources
	}
	
	/// Add a data source to the data source.
	open func add(_ dataSource: CollectionDataSource) {
		dataSource.delegate = self
		
		assert(mapping(for: dataSource) == nil, "Tried to add data source more than once: \(dataSource)")
		
		let mappingForDataSource = BasicDataSourceMapping(dataSource: dataSource)
		mappings.append(mappingForDataSource)
		dataSourceToMappings.setObject(mappingForDataSource, forKey: dataSource)
		notifyDidAddChild(dataSource)
		
		updateMappings()
		var addedSections = IndexSet()
		let numberOfSections = dataSource.numberOfSections
		for sectionIdx in 0..<numberOfSections {
			let section = mappingForDataSource.globalSectionForLocalSection(sectionIdx)
			addedSections.insert(section)
		}
		notifySectionsInserted(addedSections)
	}
	
	/// Remove the specified data source from this data source.
	open func remove(_ dataSource: CollectionDataSource) {
		guard let mappingForDataSoure = mapping(for: dataSource) else {
			preconditionFailure("Data source not found in mapping")
		}
		
		var removedSections = IndexSet()
		let numberOfSections = dataSource.numberOfSections
		
		for sectionIdx in 0..<numberOfSections {
			let section = mappingForDataSoure.globalSectionForLocalSection(sectionIdx)
			removedSections.insert(section)
		}
		
		dataSourceToMappings.removeObject(forKey: dataSource)
		if let idx = mappings.index(where: { $0 === mappingForDataSoure }) {
			mappings.remove(at: idx)
		}
		
		dataSource.delegate = nil
		
		updateMappings()
		
		notifySectionsRemoved(removedSections)
	}
	
	fileprivate func updateMappings() {
		_numberOfSections = 0
		globalSectionToMappings.removeAll(keepingCapacity: true)
		
		for mapping in mappings {
			mapping.updateMappingStartingAtGlobalSection(_numberOfSections, withUpdater: { sectionIndex in
				self.globalSectionToMappings[sectionIndex] = mapping
			})
			_numberOfSections += mapping.numberOfSections
		}
	}
	
	fileprivate func section(for dataSource: CollectionDataSource) -> Int? {
		let mapping = self.mapping(for: dataSource)
		return mapping?.globalSectionForLocalSection(0)
	}
	
	open override func dataSourceForSectionAtIndex(_ sectionIndex: Int) -> CollectionDataSource {
		let mapping = globalSectionToMappings[sectionIndex]!
		return mapping.dataSource
	}
	
	open override func localIndexPathForGlobal(_ globalIndexPath: IndexPath) -> IndexPath? {
		let mapping = mappingForGlobalSection(globalIndexPath.section)!
		return mapping.localIndexPathForGlobal(globalIndexPath)
	}
	
	open func mappingForGlobalSection(_ section: Int) -> DataSourceMapping? {
		let mapping = globalSectionToMappings[section]
		return mapping
	}
	
	fileprivate func mapping(for dataSource: CollectionDataSource) -> DataSourceMapping? {
		return dataSourceToMappings.object(forKey: dataSource) as? DataSourceMapping
	}
	
	fileprivate func globalSectionsForLocal(_ localSections: IndexSet, dataSource: CollectionDataSource) -> [Int] {
		guard let mapping = self.mapping(for: dataSource) else {
			return []
		}
		return localSections.flatMap { mapping.globalSectionForLocalSection($0) }
	}
	
	fileprivate func globalIndexPathsForLocal(_ localIndexPaths: [IndexPath], dataSource: CollectionDataSource) -> [IndexPath] {
		guard let mapping = self.mapping(for: dataSource) else {
			return []
		}
		return localIndexPaths.flatMap { mapping.globalIndexPathForLocal($0) }
	}
	
	open override func item(at indexPath: IndexPath) -> AnyItem? {
		guard let mapping = mappingForGlobalSection(indexPath.section),
			let mappedIndexPath = mapping.localIndexPathForGlobal(indexPath) else {
				return nil
		}
		return mapping.dataSource.item(at: mappedIndexPath)
	}
	
	open override func indexPath(for item: AnyItem) -> IndexPath? {
		for dataSource in dataSources {
			guard let indexPath = dataSource.indexPath(for: item),
				let mapping = self.mapping(for: dataSource) else {
					continue
			}
			return mapping.globalIndexPathForLocal(indexPath)
		}
		return nil
	}
	
	open override func removeItem(at indexPath: IndexPath) {
		guard let mapping = mappingForGlobalSection(indexPath.section),
			let localIndexPath = mapping.localIndexPathForGlobal(indexPath) else {
				return
		}
		let dataSource = mapping.dataSource
		dataSource.removeItem(at: localIndexPath)
	}
	
	open override func registerReusableViews(with collectionView: UICollectionView) {
		super.registerReusableViews(with: collectionView)
		for dataSource in dataSources {
			dataSource.registerReusableViews(with: collectionView)
		}
	}
	
	open override func didBecomeActive() {
		super.didBecomeActive()
		for dataSource in dataSources {
			dataSource.didBecomeActive()
		}
	}
	
	open override func willResignActive() {
		super.willResignActive()
		for dataSource in dataSources {
			dataSource.willResignActive()
		}
	}
	
	open override func presentActivityIndicator(forSections sections: IndexSet?) {
		var sections = sections
		if loadingState == .LoadingContent {
			sections = indexesOfAllSections as IndexSet
		}
		super.presentActivityIndicator(forSections: sections)
	}
	
	open override func update(_ placeholderView: CollectionPlaceholderView?, forSectionAtIndex sectionIndex: Int) {
		if sectionIndex == 0 && (shouldShowActivityIndicator || shouldShowPlaceholder) {
			super.update(placeholderView, forSectionAtIndex: sectionIndex)
			return
		}
		
		guard let mapping = mappingForGlobalSection(sectionIndex),
			let localSectionIndex = mapping.localSectionForGlobalSection(sectionIndex) else {
				return
		}
		let dataSource = mapping.dataSource
		dataSource.update(placeholderView, forSectionAtIndex: localSectionIndex)
	}
	
	// MARK: - CollectionDataSource
	
	open override var numberOfSections: Int {
		updateMappings()
		return _numberOfSections
	}
	
	// MARK: - Metrics
	
	open override var metricsHelper: CollectionDataSourceMetrics {
		return ComposedCollectionDataSourceMetricsHelper(composedDataSource: self)
	}
	
	// MARK: - Subclass hooks
	
	open override func collectionView(_ collectionView: UICollectionView, canEditItemAt indexPath: IndexPath) -> Bool {
		let info = mappingInfoForGlobalIndexPath(indexPath, collectionView: collectionView)!
		return info.dataSource.collectionView(info.wrapper, canEditItemAt: info.localIndexPath)
	}
	
	open override func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath, to destinationIndexPath: IndexPath) -> Bool {
		// If the move is between data sources, assume false
		guard let fromMapping = mappingForGlobalSection(indexPath.section),
			let toMapping = mappingForGlobalSection(destinationIndexPath.section),
			let localFromIndexPath = fromMapping.localIndexPathForGlobal(indexPath),
			let localToIndexPath = fromMapping.localIndexPathForGlobal(destinationIndexPath), fromMapping === toMapping else {
				return false
		}
		let wrapper = WrapperCollectionView(collectionView: collectionView, mapping: fromMapping)
		
		let dataSource = fromMapping.dataSource
		return dataSource.collectionView(wrapper, canMoveItemAt: localFromIndexPath, to: localToIndexPath)
	}
	
	// MARK: - UICollectionViewDataSource
	
	open override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		updateMappings()
		
		guard !shouldShowPlaceholder else {
			return 0
		}
		
		guard let mapping = mappingForGlobalSection(section),
			let localSection = mapping.localSectionForGlobalSection(section) else {
				assertionFailure("Asked for number of items in unmapped section: \(section)")
				return 0
		}
		let wrapper = WrapperCollectionView(collectionView: collectionView, mapping: mapping)
		let dataSource = mapping.dataSource
		
		let numberOfSections = dataSource.numberOfSections(in: wrapper)
		precondition(localSection < numberOfSections, "Local section \(localSection) is out of bounds for composed data source with \(numberOfSections) sections.")
		
		return dataSource.collectionView(wrapper, numberOfItemsInSection: localSection)
	}
	
	open override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let info = mappingInfoForGlobalIndexPath(indexPath, collectionView: collectionView)!
		return info.dataSource.collectionView(collectionView: info.wrapper, cellForItemAtIndexPath: info.localIndexPath)
	}
	
	open override func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
		let info = mappingInfoForGlobalIndexPath(indexPath, collectionView: collectionView)!
		return info.dataSource.collectionView(info.wrapper, canMoveItemAt: info.localIndexPath)
	}
	
	open override func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
		// Don't allow moves between data sources
		guard let fromMapping = mappingForGlobalSection(sourceIndexPath.section),
			let toMapping = mappingForGlobalSection(destinationIndexPath.section),
			let localFromIndexPath = fromMapping.localIndexPathForGlobal(sourceIndexPath),
			let localToIndexPath = fromMapping.localIndexPathForGlobal(destinationIndexPath), fromMapping === toMapping else {
				return
		}
		let wrapper = WrapperCollectionView(collectionView: collectionView, mapping: fromMapping)
		let dataSource = fromMapping.dataSource

		
		dataSource.collectionView(wrapper, moveItemAt: localFromIndexPath, to: localToIndexPath)
	}
	
	// MARK: - ContentLoading
	
	open override func endLoadingContent(with state: LoadState, error: NSError?, update: (() -> Void)?) {
		guard state != .NoContent && state != .Error else {
			super.endLoadingContent(with: state, error: error, update: update)
			return
		}
		
		assert(state == .ContentLoaded, "Expect to be in loaded state")
		
		// We need to wait for all the loading child data sources to complete
		let loadingGroup = DispatchGroup()
		for dataSource in dataSources {
			let loadingState = dataSource.loadingState
			// Skip data sources that aren't loading
			guard loadingState == .LoadingContent || loadingState == .RefreshingContent else {
				continue
			}
			loadingGroup.enter()
			dataSource.whenLoaded {
				loadingGroup.leave()
			}
		}
		
		// When all the child data sources have loaded, we need to figure out what the result state is.
		loadingGroup.notify(queue: DispatchQueue.main) {
			let resultSet = Set<LoadState>(self.dataSources.map { $0.loadingState })
			var finalState = state
			if resultSet.count == 1 && resultSet.contains(.NoContent) {
				finalState = .NoContent
			}
			super.endLoadingContent(with: finalState, error: error, update: update)
		}
	}
	
	open override func beginLoadingContent(with progress: LoadingProgress) {
		for dataSource in dataSources {
			dataSource.loadContent()
		}
		super.beginLoadingContent(with: progress)
	}
	
	open override func resetContent() {
		super.resetContent()
		for dataSource in dataSources {
			dataSource.resetContent()
		}
	}
	
	// MARK: - CollectionDataSourceDelegate
	
	open func dataSource(_ dataSource: CollectionDataSource, didInsertItemsAt indexPaths: [IndexPath]) {
		let globalIndexPaths = self.globalIndexPaths(for: dataSource, localIndexPaths: indexPaths)
		notifyItemsInserted(at: globalIndexPaths)
	}
	
	open func dataSource(_ dataSource: CollectionDataSource, didRemoveItemsAt indexPaths: [IndexPath]) {
		let globalIndexPaths = self.globalIndexPaths(for: dataSource, localIndexPaths: indexPaths)
		notifyItemsRemoved(at: globalIndexPaths)
	}
	
	open func dataSource(_ dataSource: CollectionDataSource, didRefreshItemsAt indexPaths: [IndexPath]) {
		let globalIndexPaths = self.globalIndexPaths(for: dataSource, localIndexPaths: indexPaths)
		notifyItemsRefreshed(at: globalIndexPaths)
	}
	
	fileprivate func globalIndexPaths(for dataSource: CollectionDataSource, localIndexPaths: [IndexPath]) -> [IndexPath] {
		return mapping(for: dataSource)!.globalIndexPathsForLocal(localIndexPaths)
	}
	
	open func dataSource(_ dataSource: CollectionDataSource, didMoveItemAt oldIndexPath: IndexPath, to newIndexPath: IndexPath) {
		let mapping = self.mapping(for: dataSource)!
		let globalFromIndexPath = mapping.globalIndexPathForLocal(oldIndexPath)
		let globalToIndexPath = mapping.globalIndexPathForLocal(newIndexPath)
		notifyItemMoved(from: globalFromIndexPath, to: globalToIndexPath)
	}
	
	open func dataSource(_ dataSource: CollectionDataSource, didInsertSections sections: IndexSet, direction: SectionOperationDirection?) {
		let mapping = self.mapping(for: dataSource)!
		updateMappings()
		let globalSections = mapping.globalSectionsForLocalSections(sections)
		notifySectionsInserted(globalSections, direction: direction)
	}
	
	open func dataSource(_ dataSource: CollectionDataSource, didRemoveSections sections: IndexSet, direction: SectionOperationDirection?) {
		let mapping = self.mapping(for: dataSource)!
		updateMappings()
		let globalSections = mapping.globalSectionsForLocalSections(sections)
		notifySectionsRemoved(globalSections, direction: direction)
	}
	
	open func dataSource(_ dataSource: CollectionDataSource, didRefreshSections sections: IndexSet) {
		let mapping = self.mapping(for: dataSource)!
		let globalSections = mapping.globalSectionsForLocalSections(sections)
		notifySectionsRefreshed(globalSections)
		updateMappings()
	}
	
	open func dataSource(_ dataSource: CollectionDataSource, didMoveSectionFrom oldSection: Int, to newSection: Int, direction: SectionOperationDirection?) {
		let mapping = self.mapping(for: dataSource)!
		let globalOldSection = mapping.globalSectionForLocalSection(oldSection)
		let globalNewSection = mapping.globalSectionForLocalSection(newSection)
		updateMappings()
		notifySectionsMoved(from: globalOldSection, to: globalNewSection, direction: direction)
	}
	
	open func dataSourceDidReloadData(_ dataSource: CollectionDataSource) {
		notifyDidReloadData()
	}
	
	open func dataSource(_ dataSource: CollectionDataSource, performBatchUpdate update: @escaping () -> Void, complete: (() -> Void)?) {
		performUpdate(update, complete: complete)
	}
	
	open func dataSource(_ dataSource: CollectionDataSource, didPresentActivityIndicatorForSections sections: IndexSet) {
		let mapping = self.mapping(for: dataSource)!
		let globalSections = mapping.globalSectionsForLocalSections(sections)
		presentActivityIndicator(forSections: globalSections)
	}
	
	open func dataSource(_ dataSource: CollectionDataSource, didPresentPlaceholderForSections sections: IndexSet) {
		let mapping = self.mapping(for: dataSource)!
		let globalSections = mapping.globalSectionsForLocalSections(sections)
		present(nil, forSections: globalSections)
	}
	
	open func dataSource(_ dataSource: CollectionDataSource, didDismissPlaceholderForSections sections: IndexSet) {
		let mapping = self.mapping(for: dataSource)!
		let globalSections = mapping.globalSectionsForLocalSections(sections)
		dismissPlaceholder(forSections: globalSections)
	}
	
	open func dataSource(_ dataSource: CollectionDataSource, didUpdate supplementaryItem: SupplementaryItem, at indexPaths: [IndexPath]) {
		let mapping = self.mapping(for: dataSource)!
		let globalIndexPaths = mapping.globalIndexPathsForLocal(indexPaths)
		notifyContentUpdated(for: supplementaryItem, at: globalIndexPaths)
	}
	
	open func dataSource(_ dataSource: CollectionDataSource, perform update: (UICollectionView) -> Void) {
		delegate?.dataSource(dataSource, perform: update)
	}
	
}

// MARK: - Helpers

private typealias MappingInfo = (dataSource: CollectionDataSource, localIndexPath: IndexPath, wrapper: WrapperCollectionView)

extension ComposedCollectionDataSource {
	
	fileprivate func mappingInfoForGlobalIndexPath(_ globalIndexPath: IndexPath, collectionView: UICollectionView) -> MappingInfo? {
		guard let mapping = mappingForGlobalSection(globalIndexPath.section),
			let localIndexPath = mapping.localIndexPathForGlobal(globalIndexPath) else {
				return nil
		}
		let dataSource = mapping.dataSource
		let wrapper = WrapperCollectionView(collectionView: collectionView, mapping: mapping)
		return (dataSource, localIndexPath, wrapper)
	}
	
}
