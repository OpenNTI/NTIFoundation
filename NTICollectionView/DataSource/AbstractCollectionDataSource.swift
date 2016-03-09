//
//  AbstractCollectionDataSource.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/22/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public class AbstractCollectionDataSource: NSObject, LoadableContentStateMachineDelegate, CollectionDataSource {
	
	public override init() {
		super.init()
		stateMachine.delegate = self
	}

	public var title: String?
	
	public weak var delegate: CollectionDataSourceDelegate?
	
	public var allowsSelection: Bool {
		return true
	}
	
	public var isRootDataSource: Bool {
		return !(delegate is CollectionDataSource)
	}
	
	public func dataSourceForSectionAtIndex(sectionIndex: Int) -> CollectionDataSource {
		return self
	}
	
	public func localIndexPathForGlobal(globalIndexPath: NSIndexPath) -> NSIndexPath? {
		return globalIndexPath
	}
	
	/// The number of sections in this data source.
	public var numberOfSections: Int {
		return 1
	}
	
	/// Return the number of items in a specific section. Implement this instead of the UICollectionViewDataSource method.
	public func numberOfItemsInSection(sectionIndex: Int) -> Int {
		return 0
	}
	
	public func item(at indexPath: NSIndexPath) -> Item? {
		return nil
	}
	
	public func indexPath(`for` item: Item) -> NSIndexPath? {
		return nil
	}
	
	/// Removes an object from the data source. This method should only be called as the result of a user action, such as tapping the "Delete" button in a swipe-to-delete gesture. Automatic removal of items due to outside changes should instead be handled by the data source itself — not the controller. Data sources must implement this to support swipe-to-delete.
	public func removeItem(at indexPath: NSIndexPath) {
		// Subclasses should override
	}
	
	// MARK: - Notifications
	
	/// Called when a data source becomes active in a collection view. If the data source is in the `Initial` state, it will be sent a `-loadContent` message.
	public func didBecomeActive() {
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
	public func willResignActive() {
		// We need to hang onto the placeholder, because dismiss clears it
		if let placeholder = self.placeholder {
			dismissPlaceholder()
			self.placeholder = placeholder
		}
	}
	
	/// Update the state of the data source in a safe manner. This ensures the collection view will be updated appropriately.
	public func performUpdate(update: () -> Void, complete: (Void -> ())? = nil) {
		requireMainThread()
		
		 // If this data source is loading, wait until we're done before we execute the update
		guard loadingState != .LoadingContent else {
			enqueueUpdate { [unowned self] in
				self.performUpdate(update, complete: complete)
			}
			return
		}
		internalPerformUpdate(update, complete: complete)
	}
	
	private func internalPerformUpdate(block: dispatch_block_t, complete: dispatch_block_t? = nil) {
		let update = block
		if let delegate = self.delegate {
			delegate.dataSource(self, performBatchUpdate: update, complete: complete)
		} else {
			update()
			complete?()
		}
	}
	
	private func enqueueUpdate(block: dispatch_block_t) {
		let update: dispatch_block_t
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
	
	public func notifyContentLoaded(with error: NSError? = nil) {
		requireMainThread()
		if let loadingCompletion = self.loadingCompletion {
			self.loadingCompletion = nil
			loadingCompletion()
		}
		delegate?.dataSourceDidLoadContent(self, error: error)
	}
	
	// MARK: - Metrics
	
	/// The default metrics for all sections in this data source.
	public var defaultMetrics: DataSourceSectionMetrics?
	
	public private(set) var sectionMetrics: [Int: DataSourceSectionMetrics] = [:]
	public private(set) var supplementaryItemsByKind: [String: [SupplementaryItem]] = [:]
	private var supplementaryItemsByKey: [String: SupplementaryItem] = [:]
	
	/// Retrieve the layout metrics for a specific section within this data source.
	public func metricsForSectionAtIndex(sectionIndex: Int) -> DataSourceSectionMetrics? {
		return sectionMetrics[sectionIndex]
	}
	
	/// Store customized layout metrics for a section in this data source. The values specified in metrics will override values specified by the data source's `defaultMetrics`.
	public func setMetrics(metrics: DataSourceSectionMetrics?, forSectionAtIndex sectionIndex: Int) {
		sectionMetrics[sectionIndex] = metrics
	}
	
	public var metricsHelper: CollectionDataSourceMetrics {
		return CollectionDataSourceMetricsHelper(dataSource: self)
	}
	
	public func numberOfSupplementaryItemsOfKind(kind: String, inSectionAtIndex sectionIndex: Int, shouldIncludeChildDataSources: Bool) -> Int {
		return metricsHelper.numberOfSupplementaryItemsOfKind(kind, inSectionAtIndex: sectionIndex, shouldIncludeChildDataSources: shouldIncludeChildDataSources)
	}
	
	public func indexPaths(`for` supplementaryItem: SupplementaryItem) -> [NSIndexPath] {
		return metricsHelper.indexPaths(`for`: supplementaryItem)
	}
	
	public func findSupplementaryItemOfKind(kind: String, at indexPath: NSIndexPath, using block: (dataSource: CollectionDataSource, localIndexPath: NSIndexPath, supplementaryItem: SupplementaryItem) -> Void) {
		metricsHelper.findSupplementaryItemOfKind(kind, at: indexPath, using: block)
	}
	
	public func snapshotMetrics() -> [Int: DataSourceSectionMetrics] {
		return metricsHelper.snapshotMetrics()
	}
	
	public func snapshotMetricsForSectionAtIndex(sectionIndex: Int) -> DataSourceSectionMetrics? {
		return metricsHelper.snapshotMetricsForSectionAtIndex(sectionIndex)
	}
	
	public func add(supplementaryItem: SupplementaryItem) {
		let kind = supplementaryItem.elementKind
		var items = supplementaryItemsOfKind(kind)
		items.append(supplementaryItem)
		supplementaryItemsByKind[kind] = items
	}
	
	public func add(supplementaryItem: SupplementaryItem, forSectionAtIndex sectionIndex: Int) {
		guard let metrics = sectionMetrics[sectionIndex] else {
			assertionFailure("There are no metrics for section \(sectionIndex)")
			return
		}
		metrics.add(supplementaryItem)
	}
	
	public func add(supplementaryItem: SupplementaryItem, forKey key: String) {
		add(supplementaryItem)
		supplementaryItemsByKey[key] = supplementaryItem
	}
	
	public func supplementaryItemsOfKind(kind: String) -> [SupplementaryItem] {
		return supplementaryItemsByKind[kind] ?? []
	}
	
	public func supplementaryItemForKey(key: String) -> SupplementaryItem? {
		return supplementaryItemsByKey[key]
	}
	
	public func removeSupplementaryItemForKey(key: String) {
		guard let oldSupplementaryItem = supplementaryItemForKey(key) else {
			return
		}
		supplementaryItemsByKey.removeValueForKey(key)
		remove(oldSupplementaryItem)
	}
	
	private func remove(supplementaryItem: SupplementaryItem) {
		let kind = supplementaryItem.elementKind
		var items = supplementaryItemsOfKind(kind)
		if let index = items.indexOf({ $0 === supplementaryItem }) {
			items.removeAtIndex(index)
			supplementaryItemsByKind[kind] = items
		}
	}
	
	public func replaceSupplementaryItemForKey(key: String, with supplementaryItem: SupplementaryItem) {
		guard let oldSupplementaryItem = supplementaryItemForKey(key) else {
			add(supplementaryItem, forKey: key)
			return
		}
		supplementaryItemsByKey[key] = supplementaryItem
		replace(oldSupplementaryItem, with: supplementaryItem)
	}
	
	private func replace(oldSupplementaryItem: SupplementaryItem, with supplementaryItem: SupplementaryItem) {
		let kind = oldSupplementaryItem.elementKind
		var items = supplementaryItemsOfKind(kind)
		if let index = items.indexOf({ $0 === oldSupplementaryItem }) {
			items[index] = supplementaryItem
		} else {
			items.append(supplementaryItem)
		}
		supplementaryItemsByKind[kind] = items
	}
	
	// MARK: - Placeholders
	
	/// The placeholder to show when the data source is in the "No Content" state.
	public var noContentPlaceholder: DataSourcePlaceholder?
	
	/// The placeholder to show when the data source is in the "Error" state.
	public var errorPlaceholder: DataSourcePlaceholder?
	
	public var placeholder: DataSourcePlaceholder?
	
	public var showsActivityIndicatorWhileRefreshingContent = false
	
	public var shouldShowActivityIndicator: Bool {
		return (showsActivityIndicatorWhileRefreshingContent && loadingState == .RefreshingContent)
			|| loadingState == .LoadingContent
	}
	
	public var shouldShowPlaceholder: Bool {
		return placeholder != nil
	}
	
	public func presentActivityIndicator(forSections sections: NSIndexSet? = nil) {
		guard let delegate = self.delegate else {
			return
		}
		let sections = sections ?? indexesOfAllSections
		internalPerformUpdate({
			if sections.containsIndexesInRange(self.rangeOfAllSections) {
				self.placeholder = BasicDataSourcePlaceholder.placeholderWithActivityIndicator()
			}
			delegate.dataSource(self, didPresentActivityIndicatorForSections: sections)
		})
	}
	
	public func present(placeholder: DataSourcePlaceholder?, forSections sections: NSIndexSet? = nil) {
		guard let delegate = self.delegate else {
			return
		}
		let sections = sections ?? indexesOfAllSections
		internalPerformUpdate({
			if sections.containsIndexesInRange(self.rangeOfAllSections),
				let placeholder = placeholder {
					self.placeholder = placeholder
			}
			delegate.dataSource(self, didPresentPlaceholderForSections: sections)
		})
	}
	
	public func dismissPlaceholder(forSections sections: NSIndexSet? = nil) {
		guard let delegate = self.delegate else {
			return
		}
		let sections = sections ?? indexesOfAllSections
		internalPerformUpdate({
			if sections.containsIndexesInRange(self.rangeOfAllSections) {
				self.placeholder = nil
			}
			delegate.dataSource(self, didDismissPlaceholderForSections: sections)
		})
	}
	
	var indexesOfAllSections: NSIndexSet {
		return NSIndexSet(indexesInRange: rangeOfAllSections)
	}
	
	var rangeOfAllSections: NSRange {
		return NSMakeRange(0, numberOfSections)
	}
	
	public func update(placeholderView: CollectionPlaceholderView?, forSectionAtIndex sectionIndex: Int) {
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
	
	public func dequePlaceholderView(`for` collectionView: UICollectionView, at indexPath: NSIndexPath) -> CollectionPlaceholderView {
		let placeholderView = collectionView.dequeueReusableSupplementaryViewOfKind(CollectionElementKindPlaceholder, withReuseIdentifier: NSStringFromClass(CollectionPlaceholderView.self), forIndexPath: indexPath) as! CollectionPlaceholderView
		update(placeholderView, forSectionAtIndex: indexPath.section)
		return placeholderView
	}
	
	// MARK: - Subclass hooks
	
	public func collectionView(collectionView: UICollectionView, configure cell: UICollectionViewCell, `for` indexPath: NSIndexPath) {
		// Subclasses should override
	}
	
	public func collectionView(collectionView: UICollectionView, identifierForCellAt indexPath: NSIndexPath) -> String {
		preconditionFailure("Subclasses must override this method.")
	}
	
	/// Register reusable views needed by this data source.
	public func registerReusableViews(with collectionView: UICollectionView) {
		func registerReusableViewsForSectionAtIndex(sectionIndex: Int) {
			guard let sectionMetrics = snapshotMetricsForSectionAtIndex(sectionIndex) else {
				return
			}
			for itemMetrics in sectionMetrics.supplementaryItems {
				collectionView.registerClass(itemMetrics.supplementaryViewClass, forSupplementaryViewOfKind: itemMetrics.elementKind, withReuseIdentifier: itemMetrics.reuseIdentifier)
			}
		}
		
		registerReusableViewsForSectionAtIndex(GlobalSectionIndex)
		
		for sectionIndex in 0..<numberOfSections {
			registerReusableViewsForSectionAtIndex(sectionIndex)
		}
		
		collectionView.registerClass(CollectionPlaceholderView.self, forSupplementaryViewOfKind: CollectionElementKindPlaceholder, withReuseIdentifier: NSStringFromClass(CollectionPlaceholderView.self))
	}
	
	/// Determine whether or not a cell is editable. Default implementation returns `false`.
	public func collectionView(collectionView: UICollectionView, canEditItemAt indexPath: NSIndexPath) -> Bool {
		return false
	}
	
	public func collectionView(collectionView: UICollectionView, canMoveItemAt indexPath: NSIndexPath) -> Bool {
		return false
	}
	
	/// Determine whether an item may be moved from its original location to a proposed location. Default implementation returns `false`.
	public func collectionView(collectionView: UICollectionView, canMoveItemAt indexPath: NSIndexPath, to destinationIndexPath: NSIndexPath) -> Bool {
		return false
	}
	
	public func collectionView(collectionView: UICollectionView, moveItemAt sourceIndexPath: NSIndexPath, to destinationIndexPath: NSIndexPath) {
		
	}
	
	// MARK: - ContentLoading
	
	public var loadingState: LoadState {
		get {
			return stateMachine.currentState
		}
		set {
			try! stateMachine.apply(newValue)
		}
	}
	
	public var loadingError: NSError?
	
	private let stateMachine = LoadableContentStateMachine()
	
	private var pendingUpdate: (() -> Void)?
	private var loadingCompletion: (() -> Void)?
	private weak var loadingProgress: LoadingProgress?
	private var isResettingContent = false
	
	/// Signal that the datasource should reload its content.
	public func setNeedsLoadContent() {
		NSObject.cancelPreviousPerformRequestsWithTarget(self, selector: "loadContent", object: nil)
		performSelector("loadContent", withObject: nil, afterDelay: 0)
	}
	
	/// Reset the content and loading state.
	public func resetContent() {
		isResettingContent = true
		// This ONLY works because the resettingContent flag is set to YES; this will be checked in -missingTransitionFromState:toState: to decide whether to allow the transition
		loadingState = .Initial
		isResettingContent = false
		
		// Content has been reset; if we're loading something, chances are we don't need it
		loadingProgress?.ignore()
	}
	
	public func loadContent() {
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
	
	public func startNewLoadingProgress() -> LoadingProgress {
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
	
	public func beginLoadingContent(with progress: LoadingProgress){
		loadContent(with: progress)
	}
	
	public func loadContent(with progress: LoadingProgress) {
		// This default implementation just signals that the load completed
		progress.done()
	}
	
	/// Use this method to wait for content to load. The block will be called once the loadingState has transitioned to the ContentLoaded, NoContent, or Error states. If the data source is already in that state, the block will be called immediately.
	public func whenLoaded(onLoad: () -> Void) {
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
	
	public func endLoadingContent(with state: LoadState, error: NSError?, update: (() -> Void)?) {
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
	
	public func canEnter(state: LoadState) -> Bool {
		return stateMachine.canTransition(to: state)
	}
	
	public func stateWillChange(to newState: LoadState) {
		willChangeValueForKey("loadingState")
	}
	
	public func stateDidChange(to newState: LoadState, from oldState: LoadState) {
		didChangeValueForKey("loadingState")
		didExit(oldState)
		didEnter(newState)
	}
	
	private func didExit(state: LoadState) {
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
	
	private func didEnter(state: LoadState) {
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
	
	public func didEnterLoadingState() {
		presentActivityIndicator()
	}
	
	public func didExitLoadingState() {
		dismissPlaceholder()
	}
	
	public func didEnterNoContentState() {
		guard let noContentPlaceholder = self.noContentPlaceholder else {
			return
		}
		present(noContentPlaceholder)
	}
	
	public func didExitNoContentState() {
		guard noContentPlaceholder != nil else {
			return
		}
		dismissPlaceholder()
	}
	
	public func didEnterErrorState() {
		guard let errorPlaceholder = self.errorPlaceholder else {
			return
		}
		present(errorPlaceholder)
	}
	
	public func didExitErrorState() {
		guard errorPlaceholder != nil else {
			return
		}
		dismissPlaceholder()
	}
	
	public func missingTransition(from fromState: LoadState, to toState: LoadState) throws -> LoadState? {
		guard isResettingContent && toState == .Initial else {
			return nil
		}
		return toState
	}
	
	// MARK: - UICollectionViewDataSource
	
	public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		// When we're showing a placeholder, we have to lie to the collection view about the number of items we have; otherwise, it will ask for layout attributes that we don't have
		return placeholder == nil ? numberOfItemsInSection(section) : 0
	}
	
	public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let identifier = self.collectionView(collectionView, identifierForCellAt: indexPath)
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath)
		self.collectionView(collectionView, configure: cell, `for`: indexPath)
		return cell
	}
	
	public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
		return numberOfSections
	}
	
	public func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
		if kind == CollectionElementKindPlaceholder {
			return dequePlaceholderView(`for`: collectionView, at: indexPath)
		}
		
		var metrics: SupplementaryItem?
		var localIndexPath: NSIndexPath?
		var dataSource: CollectionDataSource = self
		
		findSupplementaryItemOfKind(kind, at: indexPath) { (foundDataSource, foundIndexPath, foundMetrics) in
			dataSource = foundDataSource
			localIndexPath = foundIndexPath
			metrics = foundMetrics
		}
		
		guard let viewMetrics = metrics else {
			preconditionFailure("Couldn't find metrics for the supplementary view of kind \(kind) at indexPath \(indexPath.debugLogDescription)")
		}
		
		let view = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: viewMetrics.reuseIdentifier, forIndexPath: indexPath)
		
		viewMetrics.configureView?(view: view, dataSource: dataSource, indexPath: localIndexPath!)
		
		return view
	}
	
	public func collectionView(collectionView: UICollectionView, canMoveItemAtIndexPath indexPath: NSIndexPath) -> Bool {
		return false
	}
	
}
