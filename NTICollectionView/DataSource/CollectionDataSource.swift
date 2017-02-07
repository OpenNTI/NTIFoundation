//
//  CollectionDataSource.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/22/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

open class CollectionDataSource: NSObject, UICollectionViewDataSource, CollectionDataSourceMetrics, LoadableContentStateMachineDelegate {
	
	public override init() {
		super.init()
		stateMachine.delegate = self
	}

	open var title: String?
	
	open weak var delegate: CollectionDataSourceDelegate?
	
	open weak var controller: CollectionDataSourceController?
	
	open var delegatesLoadingToController = false
	
	open var allowsSelection: Bool {
		return true
	}
	
	open var isRootDataSource: Bool {
		return !(delegate is CollectionDataSource)
	}
	
	open func dataSourceForSectionAtIndex(_ sectionIndex: Int) -> CollectionDataSource {
		return self
	}
	
	open func localIndexPathForGlobal(_ globalIndexPath: IndexPath) -> IndexPath? {
		return globalIndexPath
	}
	
	/// The number of sections in this data source.
	open var numberOfSections: Int {
		return 1
	}
	
	/// Return the number of items in a specific section. Implement this instead of the UICollectionViewDataSource method.
	open func numberOfItemsInSection(_ sectionIndex: Int) -> Int {
		return 0
	}
	
	open func item(at indexPath: IndexPath) -> AnyItem? {
		return nil
	}
	
	open func indexPath(for item: AnyItem) -> IndexPath? {
		return nil
	}
	
	/// Removes an object from the data source. This method should only be called as the result of a user action, such as tapping the "Delete" button in a swipe-to-delete gesture. Automatic removal of items due to outside changes should instead be handled by the data source itself — not the controller. Data sources must implement this to support swipe-to-delete.
	open func removeItem(at indexPath: IndexPath) {
		// Subclasses should override
	}
	
	// MARK: - Notifications
	
	/// Called when a data source becomes active in a collection view. If the data source is in the `Initial` state, it will be sent a `-loadContent` message.
	open func didBecomeActive() {
		if loadingState == .Initial {
			setNeedsLoadContent()
			return
		}
		if shouldShowActivityIndicator {
			presentActivityIndicator()
			return
		}
		// If there's a placeholder, we assume it needs to be re-presented; this means the placeholder ivar must be cleared when the placeholder is dismissed
		if let placeholder = self.placeholder {
			present(placeholder)
		}
	}
	
	/// Called when a data source becomes inactive in a collection view.
	open func willResignActive() {
		// We need to hang onto the placeholder, because dismiss clears it
		if let placeholder = self.placeholder {
			dismissPlaceholder()
			self.placeholder = placeholder
		}
	}
	
	/// Update the state of the data source in a safe manner. This ensures the collection view will be updated appropriately.
	open func performUpdate(_ update: @escaping () -> Void, complete: ((Void) -> ())? = nil) {
		requireMainThread()
		
		 // If this data source is loading, wait until we're done before we execute the update
		guard loadingState != .LoadingContent else {
			enqueueUpdate { [unowned self] in
				self.performUpdate(update, complete: complete)
			}
			return
		}
		internalPerformUpdate(update, complete: complete!)
	}
	
	fileprivate func internalPerformUpdate(_ block: @escaping ()->(), complete: (()->())? = nil) {
		let update = block
		if let delegate = self.delegate {
			delegate.dataSource(self, performBatchUpdate: update, complete: complete)
		} else {
			update()
			complete?()
		}
	}
	
	fileprivate func enqueueUpdate(_ block: @escaping ()->()) {
		let update: ()->()
		if let pendingUpdate = self.pendingUpdate {
			let oldPendingUpdate = pendingUpdate
			update = {
				oldPendingUpdate()
				block()
			}
		} else {
			update = block
		}
		pendingUpdate = update
	}
	
	// MARK: - Metrics
	
	/// The default metrics for all sections in this data source.
	open var defaultMetrics: DataSourceSectionMetricsProviding?
	
	open fileprivate(set) var sectionMetrics: [Int: DataSourceSectionMetricsProviding] = [:]
	open fileprivate(set) var supplementaryItemsByKind: [String: [SupplementaryItem]] = [:]
	fileprivate var supplementaryItemsByKey: [String: SupplementaryItem] = [:]
	
	open func supplementaryItem(for key: String) -> SupplementaryItem? {
		return supplementaryItemsByKey[key]
	}
	
	/// Retrieve the layout metrics for a specific section within this data source.
	open func metricsForSectionAtIndex(_ sectionIndex: Int) -> DataSourceSectionMetricsProviding? {
		return sectionMetrics[sectionIndex]
	}
	
	/// Store customized layout metrics for a section in this data source. The values specified in metrics will override values specified by the data source's `defaultMetrics`.
	open func setMetrics(_ metrics: DataSourceSectionMetricsProviding?, forSectionAtIndex sectionIndex: Int) {
		sectionMetrics[sectionIndex] = metrics
	}
	
	open var metricsHelper: CollectionDataSourceMetrics {
		return CollectionDataSourceMetricsHelper(dataSource: self)
	}
	
	open func numberOfSupplementaryItemsOfKind(_ kind: String, inSectionAtIndex sectionIndex: Int, shouldIncludeChildDataSources: Bool) -> Int {
		return metricsHelper.numberOfSupplementaryItemsOfKind(kind, inSectionAtIndex: sectionIndex, shouldIncludeChildDataSources: shouldIncludeChildDataSources)
	}
	
	open func indexPaths(for supplementaryItem: SupplementaryItem) -> [IndexPath] {
		return metricsHelper.indexPaths(for: supplementaryItem) as [IndexPath]
	}
	
	open func findSupplementaryItemOfKind(_ kind: String, at indexPath: IndexPath, using block: (_ dataSource: CollectionDataSource, _ localIndexPath: IndexPath, _ supplementaryItem: SupplementaryItem) -> Void) {
		metricsHelper.findSupplementaryItemOfKind(kind, at: indexPath, using: block)
	}
	
	open func snapshotMetrics() -> [Int: DataSourceSectionMetricsProviding] {
		return metricsHelper.snapshotMetrics()
	}
	
	open func snapshotMetricsForSectionAtIndex(_ sectionIndex: Int) -> DataSourceSectionMetricsProviding? {
		return metricsHelper.snapshotMetricsForSectionAtIndex(sectionIndex)
	}
	
	open var contributesGlobalMetrics = true
	
	open func snapshotContributedGlobalMetrics() -> DataSourceSectionMetricsProviding? {
		return metricsHelper.snapshotContributedGlobalMetrics()
	}
	
	open func add(_ supplementaryItem: SupplementaryItem) {
		let kind = supplementaryItem.elementKind
		var items = supplementaryItemsOfKind(kind)
		items.append(supplementaryItem)
		supplementaryItemsByKind[kind] = items
	}
	
	open func add(_ supplementaryItem: SupplementaryItem, forSectionAtIndex sectionIndex: Int) {
		guard var metrics = sectionMetrics[sectionIndex] else {
			assertionFailure("There are no metrics for section \(sectionIndex)")
			return
		}
		metrics.add(supplementaryItem)
	}
	
	open func add(_ supplementaryItem: SupplementaryItem, forKey key: String) {
		add(supplementaryItem)
		supplementaryItemsByKey[key] = supplementaryItem
	}
	
	open func supplementaryItemsOfKind(_ kind: String) -> [SupplementaryItem] {
		return supplementaryItemsByKind[kind] ?? []
	}
	
	open func supplementaryItemForKey(_ key: String) -> SupplementaryItem? {
		return supplementaryItemsByKey[key]
	}
	
	open func removeSupplementaryItemForKey(_ key: String) {
		guard let oldSupplementaryItem = supplementaryItemForKey(key) else {
			return
		}
		supplementaryItemsByKey.removeValue(forKey: key)
		remove(oldSupplementaryItem)
	}
	
	fileprivate func remove(_ supplementaryItem: SupplementaryItem) {
		let kind = supplementaryItem.elementKind
		var items = supplementaryItemsOfKind(kind)
		if let index = items.index(where: { $0.isEqual(to: supplementaryItem) }) {
			items.remove(at: index)
			supplementaryItemsByKind[kind] = items
		}
	}
	
	open func replaceSupplementaryItemForKey(_ key: String, with supplementaryItem: SupplementaryItem) {
		guard let oldSupplementaryItem = supplementaryItemForKey(key) else {
			add(supplementaryItem, forKey: key)
			return
		}
		supplementaryItemsByKey[key] = supplementaryItem
		replace(oldSupplementaryItem, with: supplementaryItem)
	}
	
	fileprivate func replace(_ oldSupplementaryItem: SupplementaryItem, with supplementaryItem: SupplementaryItem) {
		let kind = oldSupplementaryItem.elementKind
		var items = supplementaryItemsOfKind(kind)
		if let index = items.index(where: { $0.isEqual(to: oldSupplementaryItem) }) {
			items[index] = supplementaryItem
		} else {
			items.append(supplementaryItem)
		}
		supplementaryItemsByKind[kind] = items
	}
	
	// MARK: - Placeholders
	
	/// The placeholder to show when the data source is in the "No Content" state.
	open var noContentPlaceholder: DataSourcePlaceholder?
	
	/// The placeholder to show when the data source is in the "Error" state.
	open var errorPlaceholder: DataSourcePlaceholder?
	
	open var placeholder: DataSourcePlaceholder?
	
	open var showsActivityIndicatorWhileRefreshingContent = false
	
	open var shouldShowActivityIndicator: Bool {
		return (showsActivityIndicatorWhileRefreshingContent && loadingState == .RefreshingContent)
			|| loadingState == .LoadingContent
	}
	
	open var shouldShowPlaceholder: Bool {
		return placeholder != nil
	}
	
	open func presentActivityIndicator(forSections sections: IndexSet? = nil) {
		guard let delegate = self.delegate else {
			return
		}
		let sections = sections ?? indexesOfAllSections
		internalPerformUpdate({
			if sections.contains(integersIn: self.rangeOfAllSections.toRange() ?? 0..<0) {
				self.placeholder = BasicDataSourcePlaceholder.placeholderWithActivityIndicator()
			}
			delegate.dataSource(self, didPresentActivityIndicatorForSections: sections)
		})
	}
	
	open func present(_ placeholder: DataSourcePlaceholder?, forSections sections: IndexSet? = nil) {
		guard let delegate = self.delegate else {
			return
		}
		let sections = sections ?? indexesOfAllSections
		internalPerformUpdate({
			if sections.contains(integersIn: self.rangeOfAllSections.toRange() ?? 0..<0),
				let placeholder = placeholder {
					self.placeholder = placeholder
			}
			delegate.dataSource(self, didPresentPlaceholderForSections: sections)
		})
	}
	
	open func dismissPlaceholder(forSections sections: IndexSet? = nil) {
		guard let delegate = self.delegate else {
			return
		}
		let sections = sections ?? indexesOfAllSections
		internalPerformUpdate({
			if sections.contains(integersIn: self.rangeOfAllSections.toRange() ?? 0..<0) {
				self.placeholder = nil
			}
			delegate.dataSource(self, didDismissPlaceholderForSections: sections)
		})
	}
	
	var indexesOfAllSections: IndexSet {
		return IndexSet(integersIn: rangeOfAllSections.toRange() ?? 0..<0)
	}
	
	var rangeOfAllSections: NSRange {
		return NSMakeRange(0, numberOfSections)
	}
	
	open func update(_ placeholderView: CollectionPlaceholderView?, forSectionAtIndex sectionIndex: Int) {
		guard let placeholderView = placeholderView else {
			return
		}
		
		if shouldShowActivityIndicator {
			placeholderView.showActivityIndicator(true)
			placeholderView.hidePlaceholder(isAnimated: true)
			return
		}
		
		placeholderView.showActivityIndicator(false)
		
		let title = placeholder?.title,
		message = placeholder?.message,
		image = placeholder?.image
		
		if title != nil || message != nil || image != nil {
			placeholderView.showPlaceholderWithTitle(title, message: message, image: image, isAnimated: true)
		} else {
			placeholderView.hidePlaceholder(isAnimated: true)
		}
	}
	
	open func dequePlaceholderView(for collectionView: UICollectionView, at indexPath: IndexPath) -> CollectionPlaceholderView {
		let placeholderView = collectionView.dequeueReusableSupplementaryView(ofKind: collectionElementKindPlaceholder, withReuseIdentifier: NSStringFromClass(CollectionPlaceholderView.self), for: indexPath) as! CollectionPlaceholderView
		update(placeholderView, forSectionAtIndex: indexPath.section)
		return placeholderView
	}
	
	// MARK: - Subclass hooks
	
	open func collectionView(_ collectionView: UICollectionView, configure cell: UICollectionViewCell, for indexPath: IndexPath) {
		// Subclasses should override
	}
	
	open func collectionView(_ collectionView: UICollectionView, identifierForCellAt indexPath: IndexPath) -> String {
		preconditionFailure("Subclasses must override this method.")
	}
	
	/// Register reusable views needed by this data source.
	open func registerReusableViews(with collectionView: UICollectionView) {
		func registerReusableViewsForSectionAtIndex(_ sectionIndex: Int) {
			guard let sectionMetrics = snapshotMetricsForSectionAtIndex(sectionIndex) else {
				return
			}
			for itemMetrics in sectionMetrics.supplementaryItems {
				collectionView.register(itemMetrics.supplementaryViewClass, forSupplementaryViewOfKind: itemMetrics.elementKind, withReuseIdentifier: itemMetrics.reuseIdentifier)
			}
		}
		
		registerReusableViewsForSectionAtIndex(globalSectionIndex)
		
		for sectionIndex in 0..<numberOfSections {
			registerReusableViewsForSectionAtIndex(sectionIndex)
		}
		
		collectionView.register(CollectionPlaceholderView.self, forSupplementaryViewOfKind: collectionElementKindPlaceholder, withReuseIdentifier: NSStringFromClass(CollectionPlaceholderView.self))
		
		registerControllerReusableViews(with: collectionView)
	}
	
	fileprivate func registerControllerReusableViews(with collectionView: UICollectionView) {
		guard let controller = self.controller else {
			return
		}
		
		for registration in controller.supplementaryViewRegistrations {
			collectionView.register(registration.viewClass, forSupplementaryViewOfKind: registration.elementKind, withReuseIdentifier: registration.identifier)
		}
	}
	
	/// Determine whether or not a cell is editable. Default implementation returns `false`.
	open func collectionView(_ collectionView: UICollectionView, canEditItemAt indexPath: IndexPath) -> Bool {
		return true
	}
	
	/// Determine whether an item may be moved from its original location to a proposed location. Default implementation returns `false`.
	open func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath, to destinationIndexPath: IndexPath) -> Bool {
		return false
	}
	
	open func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
		
	}
	
	// MARK: - ContentLoading
	
	open var loadingState: LoadState {
		get {
			return stateMachine.currentState
		}
		set {
			try! stateMachine.apply(newValue)
		}
	}
	
	open var loadingError: Error?
	
	fileprivate let stateMachine = LoadableContentStateMachine()
	
	fileprivate var pendingUpdate: (() -> Void)?
	fileprivate var loadingCompletion: (() -> Void)?
	fileprivate weak var loadingProgress: LoadingProgress?
	fileprivate var isResettingContent = false
	
	/// Signal that the datasource should reload its content.
	open func setNeedsLoadContent() {
		setNeedsLoadContent(0)
	}
	
	open func setNeedsLoadContent(_ delay: TimeInterval) {
		cancelNeedsLoadContent()
		perform(#selector(CollectionDataSource.loadContent as (CollectionDataSource) -> () -> ()), with: nil, afterDelay: delay)
	}
	
	open func cancelNeedsLoadContent() {
		NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(CollectionDataSource.loadContent as (CollectionDataSource) -> () -> ()), object: nil)
	}
	
	/// Reset the content and loading state.
	open func resetContent() {
		isResettingContent = true
		// This ONLY works because the resettingContent flag is set to YES; this will be checked in -missingTransitionFromState:toState: to decide whether to allow the transition
		loadingState = .Initial
		isResettingContent = false
		
		// Content has been reset; if we're loading something, chances are we don't need it
		loadingProgress?.ignore()
	}
	
	open func loadContent() {
		let loadingState = self.loadingState
		switch loadingState {
		case .Initial, .LoadingContent:
			self.loadingState = .LoadingContent
		default:
			self.loadingState = .RefreshingContent
		}
		
		notifyWillLoadContent()
		
		let loadingProgress = startNewLoadingProgress()
		
		beginLoadingContent(with: loadingProgress)
	}
	
	open func startNewLoadingProgress() -> LoadingProgress {
		let loadingProgress = BasicLoadingProgress { (newState, error, update) in
			guard let newState = newState else {
				return
			}
			self.endLoadingContent(with: newState, error: error) {
				update?(self)
			}
		}
		
		// Tell previous loading instance it's no longer current and remember this loading instance
		self.loadingProgress?.ignore()
		self.loadingProgress = loadingProgress
		
		return loadingProgress
	}
	
	open func beginLoadingContent(with progress: LoadingProgress) {
		if delegatesLoadingToController,
			let controller = self.controller {
			return controller.loadContent(with: progress)
		}
		loadContent(with: progress)
	}
	
	open func loadContent(with progress: LoadingProgress) {
		// This default implementation just signals that the load completed
		progress.done()
	}
	
	/// Use this method to wait for content to load. The block will be called once the loadingState has transitioned to the ContentLoaded, NoContent, or Error states. If the data source is already in that state, the block will be called immediately.
	open func whenLoaded(_ onLoad: @escaping () -> Void) {
		var complete: Int32 = 0
		
		let oldLoadingCompletion = loadingCompletion
		
		loadingCompletion = {
			// Already called the completion handler
			guard OSAtomicCompareAndSwap32(0, 1, &complete) else {
				return
			}
			// Call the previous completion block if there was one
			oldLoadingCompletion?()
			
			onLoad()
		}
	}
	
	open func endLoadingContent(with state: LoadState, error: Error?, update: (() -> Void)?) {
		loadingError = error
		loadingState = state
		
		let pendingUpdates = pendingUpdate
		pendingUpdate = nil
		
		performUpdate({
			pendingUpdates?()
			update?()
		})
		
		notifyContentLoaded(with: error)
	}
	
	open func setNeedsLoadNextContent() {
		setNeedsLoadNextContent(0)
	}
	
	open func setNeedsLoadNextContent(_ delay: TimeInterval) {
		cancelNeedsLoadNextContent()
		perform(#selector(CollectionDataSource.loadNextContent as (CollectionDataSource) -> () -> ()), with: nil, afterDelay: delay)
	}
	
	open func cancelNeedsLoadNextContent() {
		NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(CollectionDataSource.loadNextContent as (CollectionDataSource) -> () -> ()), object: nil)
	}
	
	open func loadNextContent() {
		guard canEnter(.LoadingNextContent) else {
			return
		}
		
		loadingState = .LoadingNextContent
		
		let loadingProgress = startNewLoadingProgress()
		
		beginLoadingNextContent(with: loadingProgress)
	}
	
	open func beginLoadingNextContent(with progress: LoadingProgress) {
		if delegatesLoadingToController,
			let controller = self.controller {
			return controller.loadNextContent(with: progress)
		}
		loadNextContent(with: progress)
	}
	
	open func loadNextContent(with progress: LoadingProgress) {
		progress.done()
	}
	
	open func setNeedsLoadPreviousContent() {
		setNeedsLoadPreviousContent(0)
	}
	
	open func setNeedsLoadPreviousContent(_ delay: TimeInterval) {
		cancelNeedsLoadPreviousContent()
		perform(#selector(CollectionDataSource.loadPreviousContent as (CollectionDataSource) -> () -> ()), with: nil, afterDelay: delay)
	}
	
	open func cancelNeedsLoadPreviousContent() {
		NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(CollectionDataSource.loadPreviousContent as (CollectionDataSource) -> () -> ()), object: nil)
	}
	
	open func loadPreviousContent() {
		guard canEnter(.LoadingPreviousContent) else {
			return
		}
		
		loadingState = .LoadingPreviousContent
		
		let loadingProgress = startNewLoadingProgress()
		
		beginLoadingPreviousContent(with: loadingProgress)
	}
	
	open func beginLoadingPreviousContent(with progress: LoadingProgress) {
		if delegatesLoadingToController,
			let controller = self.controller {
			return controller.loadPreviousContent(with: progress)
		}
		loadPreviousContent(with: progress)
	}
	
	open func loadPreviousContent(with progress: LoadingProgress) {
		progress.done()
	}
	
	open func canEnter(_ state: LoadState) -> Bool {
		return stateMachine.canTransition(to: state)
	}
	
	open func stateWillChange(to newState: LoadState) {
		willChangeValue(forKey: "loadingState")
	}
	
	open func stateDidChange(to newState: LoadState, from oldState: LoadState) {
		didChangeValue(forKey: "loadingState")
		didExit(oldState)
		didEnter(newState)
	}
	
	fileprivate func didExit(_ state: LoadState) {
		switch state {
		case .LoadingContent:
			didExitLoadingState()
		case .NoContent:
			didExitNoContentState()
		case .Error:
			didExitErrorState()
		default:
			break
		}
	}
	
	fileprivate func didEnter(_ state: LoadState) {
		switch state {
		case .LoadingContent:
			didEnterLoadingState()
		case .NoContent:
			didEnterNoContentState()
		case .Error:
			didEnterErrorState()
		default:
			break
		}
	}
	
	open func didEnterLoadingState() {
		presentActivityIndicator()
	}
	
	open func didExitLoadingState() {
		dismissPlaceholder()
	}
	
	open func didEnterNoContentState() {
		guard let noContentPlaceholder = self.noContentPlaceholder else {
			return
		}
		present(noContentPlaceholder)
	}
	
	open func didExitNoContentState() {
		guard noContentPlaceholder != nil else {
			return
		}
		dismissPlaceholder()
	}
	
	open func didEnterErrorState() {
		guard let errorPlaceholder = self.errorPlaceholder else {
			return
		}
		present(errorPlaceholder)
	}
	
	open func didExitErrorState() {
		guard errorPlaceholder != nil else {
			return
		}
		dismissPlaceholder()
	}
	
	open func missingTransition(from fromState: LoadState, to toState: LoadState) throws -> LoadState? {
		guard isResettingContent && toState == .Initial else {
			return nil
		}
		return toState
	}
	
	// MARK: - UICollectionViewDataSource
	
	open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		// When we're showing a placeholder, we have to lie to the collection view about the number of items we have; otherwise, it will ask for layout attributes that we don't have
		return placeholder == nil ? numberOfItemsInSection(section) : 0
	}
	
	open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let identifier = self.collectionView(collectionView, identifierForCellAt: indexPath)
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
		self.collectionView(collectionView, configure: cell, for: indexPath)
		return cell
	}
	
	open func numberOfSections(in collectionView: UICollectionView) -> Int {
		return numberOfSections
	}
	
	open func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
		if kind == collectionElementKindPlaceholder {
			return dequePlaceholderView(for: collectionView, at: indexPath)
		}
		
		var metrics: SupplementaryItem?
		var localIndexPath: IndexPath?
		var dataSource: CollectionDataSource = self
		
		findSupplementaryItemOfKind(kind, at: indexPath) { (foundDataSource, foundIndexPath, foundMetrics) in
			dataSource = foundDataSource
			localIndexPath = foundIndexPath
			metrics = foundMetrics
		}
		
		guard let viewMetrics = metrics else {
			preconditionFailure("Couldn't find metrics for the supplementary view of kind \(kind) at indexPath \(indexPath.debugLogDescription)")
		}
		
		layoutLog("\(#function) \(kind) \(indexPath) \(viewMetrics.reuseIdentifier) \(viewMetrics.supplementaryViewClass)")
		
		let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: viewMetrics.reuseIdentifier, for: indexPath)
		
		viewMetrics.configureView?(view, dataSource, localIndexPath!)
		
		return view
	}
	
	open func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
		return false
	}
	
}

extension CollectionDataSource {
	
	public var globalMetrics: DataSourceSectionMetricsProviding? {
		get {
			return metricsForSectionAtIndex(globalSectionIndex)
		}
		set {
			setMetrics(newValue, forSectionAtIndex: globalSectionIndex)
		}
	}
	
}

extension CollectionDataSource {
	
	/// Notify the parent data source and the collection view that new items have been inserted at positions represented by *insertedIndexPaths*.
	public func notifyItemsInserted(at indexPaths: [IndexPath]) {
		requireMainThread()
		delegate?.dataSource(self, didInsertItemsAt: indexPaths)
	}
	
	/// Notify the parent data source and collection view that the items represented by *removedIndexPaths* have been removed from this data source.
	public func notifyItemsRemoved(at indexPaths: [IndexPath]) {
		requireMainThread()
		delegate?.dataSource(self, didRemoveItemsAt: indexPaths)
	}
	
	/// Notify the parent data sources and collection view that the items represented by *refreshedIndexPaths* have been updated and need redrawing.
	public func notifyItemsRefreshed(at indexPaths: [IndexPath]) {
		requireMainThread()
		delegate?.dataSource(self, didRefreshItemsAt: indexPaths)
	}
	
	/// Notify the parent data sources and collection view that the items represented by *refreshedIndexPaths* have been updated and need redrawing.
	public func notifyItemMoved(from oldIndexPath: IndexPath, to newIndexPath: IndexPath) {
		requireMainThread()
		delegate?.dataSource(self, didMoveItemAt: oldIndexPath, to: newIndexPath)
	}
	
	/// Notify parent data sources and the collection view that the sections were inserted.
	public func notifySectionsInserted(_ sections: IndexSet, direction: SectionOperationDirection? = nil) {
		requireMainThread()
		delegate?.dataSource(self, didInsertSections: sections, direction: direction)
	}
	
	/// Notify parent data sources and (eventually) the collection view that the sections were removed.
	public func notifySectionsRemoved(_ sections: IndexSet, direction: SectionOperationDirection? = nil) {
		requireMainThread()
		delegate?.dataSource(self, didRemoveSections: sections, direction: direction)
	}
	
	/// Notify parent data sources and the collection view that the section at *oldSectionIndex* was moved to *newSectionIndex*.
	public func notifySectionsMoved(from oldSectionIndex: Int, to newSectionIndex: Int, direction: SectionOperationDirection? = nil) {
		requireMainThread()
		delegate?.dataSource(self, didMoveSectionFrom: oldSectionIndex, to: newSectionIndex, direction: direction)
	}
	
	/// Notify parent data sources and ultimately the collection view the specified sections were refreshed.
	public func notifySectionsRefreshed(_ sections: IndexSet) {
		requireMainThread()
		delegate?.dataSource(self, didRefreshSections: sections)
	}
	
	/// Notify parent data sources and ultimately the collection view that the data in this data source has been reloaded.
	public func notifyDidReloadData() {
		requireMainThread()
		delegate?.dataSourceDidReloadData(self)
	}
	
	public func notifyWillLoadContent() {
		requireMainThread()
		delegate?.dataSourceWillLoadContent(self)
	}
	
	public func notifyContentLoaded(with error: Error? = nil) {
		requireMainThread()
		if let loadingCompletion = self.loadingCompletion {
			self.loadingCompletion = nil
			loadingCompletion()
		}
		delegate?.dataSourceDidLoadContent(self, error: error)
	}
	
	public func notifyContentUpdated(for supplementaryItem: SupplementaryItem, at indexPaths: [IndexPath]) {
		requireMainThread()
		delegate?.dataSource(self, didUpdate: supplementaryItem, at: indexPaths)
	}
	
	public func notifyDidAddChild(_ childDataSource: CollectionDataSource) {
		delegate?.dataSource(self, didAddChild: childDataSource)
	}
	
	public func notifyPerform(_ update: (_ collectionView: UICollectionView) -> Void) {
		delegate?.dataSource(self, perform: update)
	}
	
}
