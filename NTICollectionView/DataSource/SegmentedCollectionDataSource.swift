//
//  SegmentedCollectionDataSource.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/24/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public protocol SegmentedCollectionDataSourceProtocol: ParentCollectionDataSource {
	
	var selectedDataSource: CollectionDataSource? { get set }
	
	var selectedDataSourceIndex: Int? { get set }
	
	func removeAllDataSources()
	
}

private let SegmentedDataSourceHeaderKey = "SegmentedDataSourceHeaderKey"

public class SegmentedCollectionDataSource: AbstractCollectionDataSource, SegmentedCollectionDataSourceProtocol, SegmentedControlDelegate {
	
	public private(set) var dataSources: [CollectionDataSource] = []
	
	public func add(dataSource: CollectionDataSource) {
		if dataSources.isEmpty {
			_selectedDataSource = dataSource
		}
		dataSources.append(dataSource)
		dataSource.delegate = self
		notifyDidAddChild(dataSource)
	}
	
	public func remove(dataSource: CollectionDataSource) {
		guard let index = dataSourcesIndexOf(dataSource) else {
			return
		}
		dataSources.removeAtIndex(index)
		if dataSource.delegate === self {
			dataSource.delegate = nil
		}
	}
	
	public func removeAllDataSources() {
		for dataSource in dataSources where dataSource.delegate === self {
			dataSource.delegate = nil
		}
		dataSources = []
		_selectedDataSource = nil
	}
	
	private func dataSourcesIndexOf(dataSource: CollectionDataSource) -> Int? {
		return dataSources.indexOf({ $0 === dataSource })
	}
	
	private func dataSourcesContains(dataSource: CollectionDataSource) -> Bool {
		return dataSources.contains({ $0 === selectedDataSource })
	}
	
	public var selectedDataSource: CollectionDataSource? {
		get {
			return _selectedDataSource
		}
		set {
			setSelectedDataSource(newValue, isAnimated: false)
		}
	}
	private var _selectedDataSource: CollectionDataSource? {
		didSet {
			segmentedCollectionDataSourceDelegate?.segmentedCollectionDataSourceDidChangeSelectedDataSource(self)
		}
	}
	
	public weak var segmentedCollectionDataSourceDelegate: SegmentedCollectionDataSourceDelegate?
	
	public func setSelectedDataSource(selectedDataSource: CollectionDataSource?, isAnimated: Bool) {
		setSelectedDataSource(selectedDataSource, isAnimated: isAnimated, completionHandler: nil)
	}
	
	public func setSelectedDataSource(selectedDataSource: CollectionDataSource?, isAnimated: Bool, completionHandler: dispatch_block_t?) {
		guard selectedDataSource !== self.selectedDataSource else {
			completionHandler?()
			return
		}
		if selectedDataSource != nil {
			precondition(dataSourcesContains(selectedDataSource!), "Selected data source must be contained in this data source")
		}
		
		let oldDataSource = self.selectedDataSource
		
		var direction: SectionOperationDirection?
		if isAnimated,
			let oldSelectedDataSource = oldDataSource,
			newSelectedDataSource = selectedDataSource {
			let oldIndex = dataSourcesIndexOf(oldSelectedDataSource)!
			let newIndex = dataSourcesIndexOf(newSelectedDataSource)!
			direction = (oldIndex < newIndex) ? .Right : .Left
		}
		
		let numberOfOldSections = oldDataSource?.numberOfSections ?? 0
		let numberOfNewSections = selectedDataSource?.numberOfSections ?? 0
		let removedSet = NSIndexSet(indexesInRange: NSMakeRange(0, numberOfOldSections))
		let insertedSet = NSIndexSet(indexesInRange: NSMakeRange(0, numberOfNewSections))
		
		performUpdate({
			oldDataSource?.willResignActive()
			
			if removedSet.count > 0 {
				self.notifySectionsRemoved(removedSet, direction: direction)
			}
			
			self.willChangeValueForKey("selectedDataSource")
			self.willChangeValueForKey("selectedDataSourceIndex")
			
			self._selectedDataSource = selectedDataSource
			
			self.didChangeValueForKey("selectedDataSource")
			self.didChangeValueForKey("selectedDataSourceIndex")
			
			self.segmentedCollectionDataSourceDelegate?.segmentedCollectionDataSourceDidChangeSelectedDataSource(self)
			
			if insertedSet.count > 0 {
				self.notifySectionsInserted(insertedSet, direction: direction)
			}
			
			selectedDataSource?.didBecomeActive()
			}, complete: completionHandler)
	}
	
	public var selectedDataSourceIndex: Int? {
		get {
			guard let selectedDataSource = self.selectedDataSource else {
				return nil
			}
			return dataSourcesIndexOf(selectedDataSource)!
		}
		set {
			setSelectedDataSourceIndex(newValue, isAnimated: false)
		}
	}
	public func setSelectedDataSourceIndex(selectedDataSourceIndex: Int?, isAnimated: Bool) {
		guard let index = selectedDataSourceIndex else {
			selectedDataSource = nil
			return
		}
		let dataSource = dataSources[index]
		selectedDataSource = dataSource
	}
	
	private func dataSourceAtIndex(dataSourceIndex: Int) -> CollectionDataSource {
		return dataSources[dataSourceIndex]
	}
	
	public override var numberOfSections: Int {
		return selectedDataSource?.numberOfSections ?? 0
	}
	
	public override func dataSourceForSectionAtIndex(sectionIndex: Int) -> CollectionDataSource {
		return selectedDataSource?.dataSourceForSectionAtIndex(sectionIndex) ?? super.dataSourceForSectionAtIndex(sectionIndex)
	}
	
	public override func localIndexPathForGlobal(globalIndexPath: NSIndexPath) -> NSIndexPath? {
		return selectedDataSource?.localIndexPathForGlobal(globalIndexPath)
	}
	
	public override func item(at indexPath: NSIndexPath) -> Item? {
		return selectedDataSource?.item(at: indexPath)
	}
	
	public override func indexPath(for item: Item) -> NSIndexPath? {
		return selectedDataSource?.indexPath(for: item)
	}
	
	public override func removeItem(at indexPath: NSIndexPath) {
		selectedDataSource?.removeItem(at: indexPath)
	}
	
	public override func registerReusableViews(with collectionView: UICollectionView) {
		super.registerReusableViews(with: collectionView)
		for dataSource in dataSources {
			dataSource.registerReusableViews(with: collectionView)
		}
	}
	
	// TODO: Action stuff?
	
	public override func didBecomeActive() {
		super.didBecomeActive()
		selectedDataSource?.didBecomeActive()
	}
	
	public override func willResignActive() {
		super.willResignActive()
		selectedDataSource?.willResignActive()
	}
	
	public override var allowsSelection: Bool {
		return selectedDataSource?.allowsSelection ?? super.allowsSelection
	}
	
	// TODO: Make computed property for item-by-key?
	public var segmentedControlHeader: SegmentedControlSupplementaryItem? {
		didSet {
			guard let segmentedControlHeader = self.segmentedControlHeader else {
				return removeSupplementaryItemForKey(SegmentedDataSourceHeaderKey)
			}
			
			guard let oldValue = oldValue else {
				return add(segmentedControlHeader, forKey: SegmentedDataSourceHeaderKey)
			}
			
			guard !segmentedControlHeader.isEqual(to: oldValue) else {
				return
			}
			
			replaceSupplementaryItemForKey(SegmentedDataSourceHeaderKey, with: segmentedControlHeader)
			configureSegmentedControlHeader()
		}
	}
	
	private func configureSegmentedControlHeader() {
		guard segmentedControlHeader != nil else {
			return
		}
		
		segmentedControlHeader?.isVisibleWhileShowingPlaceholder = true
		segmentedControlHeader?.shouldPin = true
		
		segmentedControlHeader?.configure { [weak self] (view, dataSource, indexPath) -> Void in
			guard let `self` = self else {
				return
			}
			guard let segmentedDataSource = dataSource as? SegmentedCollectionDataSource else {
				return
			}
			guard let segmentedControl = self.segmentedControlHeader?.segmentedControl else {
				return
			}
			
			segmentedDataSource.configure(segmentedControl)
		}
	}
	
	public func configure(segmentedControl: SegmentedControlProtocol) {
		let titles = dataSources.map { $0.title ?? "" }
		
		segmentedControl.setSegments(with: titles, animated: false)
		
		segmentedControl.segmentedControlDelegate = self
		segmentedControl.selectedSegmentIndex = selectedDataSourceIndex ?? UISegmentedControlNoSegment
	}
	
	// MARK: - Metrics
	
	public override var metricsHelper: CollectionDataSourceMetrics {
		return SegmentedCollectionDataSourceMetricsHelper(segmentedDataSource: self)
	}
	
	// MARK: - Subclass hooks
	
	public override func collectionView(collectionView: UICollectionView, canEditItemAt indexPath: NSIndexPath) -> Bool {
		return selectedDataSource?.collectionView(collectionView, canEditItemAt: indexPath) ?? super.collectionView(collectionView, canEditItemAt: indexPath)
	}
	
	public override func collectionView(collectionView: UICollectionView, canMoveItemAt indexPath: NSIndexPath) -> Bool {
		return selectedDataSource?.collectionView(collectionView, canMoveItemAt: indexPath) ?? super.collectionView(collectionView, canMoveItemAt: indexPath)
	}
	
	// MARK: - ContentLoading
	
	public override func beginLoadingContent(with progress: LoadingProgress) {
		selectedDataSource?.loadContent()
		super.beginLoadingContent(with: progress)
	}
	
	public override func resetContent() {
		for dataSource in dataSources {
			dataSource.resetContent()
		}
		super.resetContent()
	}
	
	// MARK: - Placeholders
	
	public override func update(placeholderView: CollectionPlaceholderView?, forSectionAtIndex sectionIndex: Int) {
		selectedDataSource?.update(placeholderView, forSectionAtIndex: sectionIndex)
	}
	
	// MARK: - SegmentedControlDelegate
	
	public func segmentedControlDidChangeValue(segmentedControl: SegmentedControlProtocol) {
		segmentedControl.userInteractionEnabled = false
		let selectedSegmentIndex = segmentedControl.selectedSegmentIndex
		let dataSource = dataSources[selectedSegmentIndex]
		setSelectedDataSource(dataSource, isAnimated: true) {
			segmentedControl.userInteractionEnabled = true
		}
	}
	
	// MARK: - UICollectionViewDataSource
	
	public override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return shouldShowPlaceholder ? 0 : selectedDataSource?.collectionView(collectionView, numberOfItemsInSection: section) ?? super.collectionView(collectionView, numberOfItemsInSection: section)
	}
	
	public override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		return selectedDataSource?.collectionView(collectionView, cellForItemAtIndexPath: indexPath) ?? super.collectionView(collectionView, cellForItemAtIndexPath: indexPath)
	}
	
	public override func collectionView(collectionView: UICollectionView, canMoveItemAt indexPath: NSIndexPath, to destinationIndexPath: NSIndexPath) -> Bool {
		return selectedDataSource?.collectionView(collectionView, canMoveItemAt: indexPath, to: destinationIndexPath) ?? super.collectionView(collectionView, canMoveItemAt: indexPath, to: destinationIndexPath)
	}
	
	public override func collectionView(collectionView: UICollectionView, moveItemAt sourceIndexPath: NSIndexPath, to destinationIndexPath: NSIndexPath) {
		selectedDataSource?.collectionView(collectionView, moveItemAt: sourceIndexPath, to: destinationIndexPath)
	}
	
	// MARK: - CollectionDataSourceDelegate
	
	public func dataSource(dataSource: CollectionDataSource, didInsertItemsAt indexPaths: [NSIndexPath]) {
		guard dataSource === selectedDataSource else {
			return
		}
		notifyItemsInserted(at: indexPaths)
	}
	
	public func dataSource(dataSource: CollectionDataSource, didRemoveItemsAt indexPaths: [NSIndexPath]) {
		guard dataSource === selectedDataSource else {
			return
		}
		notifyItemsRemoved(at: indexPaths)
	}
	
	public func dataSource(dataSource: CollectionDataSource, didRefreshItemsAt indexPaths: [NSIndexPath]) {
		guard dataSource === selectedDataSource else {
			return
		}
		notifyItemsRefreshed(at: indexPaths)
	}
	
	public func dataSource(dataSource: CollectionDataSource, didMoveItemAt oldIndexPath: NSIndexPath, to newIndexPath: NSIndexPath) {
		guard dataSource === selectedDataSource else {
			return
		}
		notifyItemMoved(from: oldIndexPath, to: newIndexPath)
	}
	
	public func dataSource(dataSource: CollectionDataSource, didInsertSections sections: NSIndexSet, direction: SectionOperationDirection?) {
		guard dataSource === selectedDataSource else {
			return
		}
		notifySectionsInserted(sections, direction: direction)
	}
	
	public func dataSource(dataSource: CollectionDataSource, didRemoveSections sections: NSIndexSet, direction: SectionOperationDirection?) {
		guard dataSource === selectedDataSource else {
			return
		}
		notifySectionsRemoved(sections, direction: direction)
	}
	
	public func dataSource(dataSource: CollectionDataSource, didRefreshSections sections: NSIndexSet) {
		guard dataSource === selectedDataSource else {
			return
		}
		notifySectionsRefreshed(sections)
	}
	
	public func dataSource(dataSource: CollectionDataSource, didMoveSectionFrom oldSection: Int, to newSection: Int, direction: SectionOperationDirection?) {
		guard dataSource === selectedDataSource else {
			return
		}
		notifySectionsMoved(from: oldSection, to: newSection, direction: direction)
	}
	
	public func dataSourceDidReloadData(dataSource: CollectionDataSource) {
		guard dataSource === selectedDataSource else {
			return
		}
		notifyDidReloadData()
	}
	
	public func dataSource(dataSource: CollectionDataSource, performBatchUpdate update: () -> Void, complete: (() -> Void)?) {
		guard dataSource === selectedDataSource else {
			update()
			complete?()
			return
		}
		performUpdate(update, complete: complete)
	}
	
	public func dataSource(dataSource: CollectionDataSource, didPresentActivityIndicatorForSections sections: NSIndexSet) {
		guard dataSource === selectedDataSource else {
			return
		}
		presentActivityIndicator(forSections: sections)
	}
	
	public func dataSource(dataSource: CollectionDataSource, didPresentPlaceholderForSections sections: NSIndexSet) {
		guard dataSource === selectedDataSource else {
			return
		}
		present(nil, forSections: sections)
	}
	
	public func dataSource(dataSource: CollectionDataSource, didDismissPlaceholderForSections sections: NSIndexSet) {
		guard dataSource === selectedDataSource else {
			return
		}
		dismissPlaceholder(forSections: sections)
	}
	
	public func dataSource(dataSource: CollectionDataSource, didUpdate supplementaryItem: SupplementaryItem, at indexPaths: [NSIndexPath]) {
		guard dataSource === selectedDataSource else {
			return
		}
		notifyContentUpdated(for: supplementaryItem, at: indexPaths)
	}
	
	public func dataSource(dataSource: CollectionDataSource, perform update: UICollectionView -> Void) {
		delegate?.dataSource(dataSource, perform: update)
	}
	
}

public protocol SegmentedCollectionDataSourceDelegate: class {
	
	func segmentedCollectionDataSourceDidChangeSelectedDataSource(segmentedCollectionDataSource: SegmentedCollectionDataSourceProtocol)
	
}

