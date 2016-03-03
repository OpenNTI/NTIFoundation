//
//  CollectionViewController.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/25/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

private var KVODataSourceContext = "DataSourceContext"
private var UpdateNumber = 0

public class CollectionViewController: UICollectionViewController, CollectionDataSourceDelegate, CollectionViewSupplementaryViewTracking {
	
	private var updateCompletionHandler: dispatch_block_t?
	private let reloadedSections = NSMutableIndexSet()
	private let deletedSections = NSMutableIndexSet()
	private let insertedSections = NSMutableIndexSet()
	private var isPerformingUpdates = false
	private var isObservingDataSource = false
	private var visibleSupplementaryViews: [String: [NSIndexPath: UICollectionReusableView]] = [:]
	
	public var contentInsets: UIEdgeInsets {
		get {
			if hasAssignedContentInsets {
				return _contentInsets
			}
			
			let orientation = UIApplication.sharedApplication().statusBarOrientation
			let bounds = UIScreen.mainScreen().bounds
			
			let isNavigationBarHidden = navigationController?.navigationBar.hidden ?? true
			let isTabBarHidden = tabBarController?.tabBar.hidden ?? true
			
			// If the content insets were calculated, and the orientation is the same, return calculated value
			guard !hasCalculatedContentInsets
				|| orientation != orientationForCalculatedInsets
				|| bounds != applicationFrameForCalculatedInsets
				|| isNavigationBarHidden == calculatedNavigationBarHiddenValue
				|| isTabBarHidden == calculatedTabBarHiddenValue else {
					return _contentInsets
			}
			
			// Grab our frame in window coordinates
			let rect = view.convertRect(view.bounds, toView: nil)
			
			// No value has been assigned, so we need to compute it
			let application = UIApplication.sharedApplication()
			
			var insets = UIEdgeInsetsZero
			
			if !application.statusBarHidden {
				// The status bar doesn't seem to adjust when rotated
				let height = orientation == .Portrait ? application.statusBarFrame.height : application.statusBarFrame.width
				if rect.minY < height {
					insets.top += 20
				}
			}
			
			// If the navigation bar ISN'T hidden, we'll set our top inset to the bottom of the navigation bar. This allows the system to position things correctly to account for the double height status bar.
			if !isNavigationBarHidden, let navigationBar = navigationController?.navigationBar {
				// During rotation, the navigation bar (and possibly tab bar) doesn't resize immediately. Force it to have its new size.
				navigationBar.sizeToFit()
				let frame = navigationBar.convertRect(navigationBar.bounds, toView: nil)
				
				if rect.intersects(frame) {
					insets.top += frame.maxY - frame.minY
				}
			}
			
			if !isTabBarHidden, let tabBar = tabBarController?.tabBar {
				// During rotation, the navigation bar (and possibly tab bar) doesn't resize immediately. Force it to have its new size.
				tabBar.sizeToFit()
				let frame = tabBar.convertRect(tabBar.bounds, toView: nil)
				
				if rect.intersects(frame) {
					insets.bottom += frame.height
				}
			}
			
			hasCalculatedContentInsets = true
			orientationForCalculatedInsets = orientation
			applicationFrameForCalculatedInsets = bounds
			calculatedNavigationBarHiddenValue = isNavigationBarHidden
			calculatedTabBarHiddenValue = isTabBarHidden
			_contentInsets = insets
			
			return insets
		}
		set {
			_contentInsets = newValue
			hasCalculatedContentInsets = false
			hasAssignedContentInsets = true
			
			view.setNeedsLayout()
		}
	}
	private var _contentInsets = UIEdgeInsetsZero
	private var hasAssignedContentInsets = false
	private var hasCalculatedContentInsets = false
	private var calculatedTabBarHiddenValue = false
	private var calculatedNavigationBarHiddenValue = false
	private var orientationForCalculatedInsets: UIInterfaceOrientation = .Unknown
	private var applicationFrameForCalculatedInsets = CGRectZero
	private var keyboardIsShowing = false
	private var contentInsetsBeforeShowingKeyboard = UIEdgeInsetsZero
	
	public override var collectionView: UICollectionView? {
		willSet {
			endObservingDataSource()
		}
		didSet {
			beginObservingDataSource()
		}
	}
	
	public override var editing: Bool {
		didSet {
			guard editing != oldValue else {
				return
			}
			if let layout = collectionView?.collectionViewLayout as? CollectionViewLayout {
				layout.isEditing = editing
			}
		}
	}
	
	deinit {
		if isViewLoaded() {
			endObservingDataSource()
		}
	}
	
	private func beginObservingDataSource() {
		guard !isObservingDataSource else {
			return
		}
		collectionView!.addObserver(self, forKeyPath: "dataSource", options: [.Initial, .New], context: &KVODataSourceContext)
		isObservingDataSource = true
	}
	
	private func endObservingDataSource() {
		guard isObservingDataSource else {
			return
		}
		collectionView!.removeObserver(self, forKeyPath: "dataSource")
		isObservingDataSource = false
	}
	
	public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
		guard context == &KVODataSourceContext else {
			super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
			return
		}
		
		let collectionView = object as! UICollectionView
		guard let dataSource = collectionView.dataSource as? CollectionDataSource else {
			return
		}
		
		if dataSource.delegate == nil {
			dataSource.delegate = self
		}
	}
	
	public override func loadView() {
		super.loadView()
		beginObservingDataSource()
	}
	
	public override func viewDidLoad() {
		super.viewDidLoad()
//		automaticallyAdjustsScrollViewInsets = false
		let insets = contentInsets
		collectionView?.contentInset = insets
		collectionView?.scrollIndicatorInsets = insets
	}
	
	public override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		let collectionView = self.collectionView!
		
		if let dataSource = collectionView.dataSource as? CollectionDataSource {
			let wrapper = WrapperCollectionView(collectionView: collectionView, mapping: nil)
			dataSource.registerReusableViews(with: wrapper)
			dataSource.setNeedsLoadContent()
		}
	}

	public override func viewDidDisappear(animated: Bool) {
		super.viewDidDisappear(animated)
		editing = false
	}
	
	public override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		let insets = contentInsets
		let oldInsets = collectionView!.contentInset
		
		collectionView!.contentInset = insets
		collectionView!.scrollIndicatorInsets = insets
		if insets != oldInsets {
			collectionView!.collectionViewLayout.invalidateLayout()
		}
	}
	
	// MARK: - UICollectionViewDelegate
	
	public override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
		return _collectionView(collectionView, shouldSelectItemAtIndexPath: indexPath)
	}
	
	public override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
		guard !editing else {
			return false
		}
		return _collectionView(collectionView, shouldSelectItemAtIndexPath: indexPath)
	}
	
	private func _collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
		guard let dataSource = collectionView.dataSource as? CollectionDataSource else {
			return shouldSelectItemsByDefault
		}
		let sectionDataSource = dataSource.dataSourceForSectionAtIndex(indexPath.section)
		return sectionDataSource.allowsSelection
	}
	
	private var shouldSelectItemsByDefault: Bool {
		return false
	}
	
	public override func collectionView(collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, atIndexPath indexPath: NSIndexPath) {
		if #available(iOS 9, *) {
			return
		}
		if visibleSupplementaryViews[elementKind] == nil {
			visibleSupplementaryViews[elementKind] = [:]
		}
		visibleSupplementaryViews[elementKind]![indexPath] = view
	}
	
	public override func collectionView(collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, atIndexPath indexPath: NSIndexPath) {
		if #available(iOS 9, *) {
			return
		}
		visibleSupplementaryViews[elementKind]?[indexPath] = nil
	}
	
	// MARK: - CollectionSupplementaryViewTracking
	
	public func collectionView(collectionView: UICollectionView, visibleViewForSupplementaryElementOfKind kind: String, at indexPath: NSIndexPath) -> UICollectionReusableView? {
		if #available(iOS 9, *) {
			return collectionView.supplementaryViewForElementKind(kind, atIndexPath: indexPath)
		}
		return visibleSupplementaryViews[kind]?[indexPath]
	}
	
	// MARK: - CollectionDataSourceDelegate
	
	private func clearSectionUpdateInfo() {
		reloadedSections.removeAllIndexes()
		deletedSections.removeAllIndexes()
		insertedSections.removeAllIndexes()
	}
	
	public func dataSource(dataSource: CollectionDataSource, didInsertItemsAt indexPaths: [NSIndexPath]) {
		updateLog("\(__FUNCTION__) INSERT ITEMS: \(indexPaths)")
		collectionView!.insertItemsAtIndexPaths(indexPaths)
	}
	
	public func dataSource(dataSource: CollectionDataSource, didRemoveItemsAt indexPaths: [NSIndexPath]) {
		updateLog("\(__FUNCTION__) REMOVE ITEMS: \(indexPaths)")
		collectionView!.deleteItemsAtIndexPaths(indexPaths)
	}
	
	public func dataSource(dataSource: CollectionDataSource, didRefreshItemsAt indexPaths: [NSIndexPath]) {
		updateLog("\(__FUNCTION__) REFRESH ITEMS: \(indexPaths)")
		collectionView!.reloadItemsAtIndexPaths(indexPaths)
	}
	
	public func dataSource(dataSource: CollectionDataSource, didMoveItemAt oldIndexPath: NSIndexPath, to newIndexPath: NSIndexPath) {
		updateLog("\(__FUNCTION__) MOVE ITEM: \(oldIndexPath.debugLogDescription) TO: \(newIndexPath.debugLogDescription)")
		collectionView!.moveItemAtIndexPath(oldIndexPath, toIndexPath: newIndexPath)
	}
	
	public func dataSource(dataSource: CollectionDataSource, didInsertSections sections: NSIndexSet, direction: SectionOperationDirection?) {
		updateLog("\(__FUNCTION__) INSERT SECTIONS: \(sections.debugLogDescription)")
		let layout = collectionView!.collectionViewLayout
		if let collectionLayout = layout as? CollectionViewLayout {
			collectionLayout.dataSource(dataSource, didInsertSections: sections, direction: direction)
		}
		collectionView!.insertSections(sections)
		insertedSections.addIndexes(sections)
	}
	
	public func dataSource(dataSource: CollectionDataSource, didRemoveSections sections: NSIndexSet, direction: SectionOperationDirection?) {
		updateLog("\(__FUNCTION__) REMOVE SECTIONS: \(sections.debugLogDescription)")
		let layout = collectionView!.collectionViewLayout
		if let collectionLayout = layout as? CollectionViewLayout {
			collectionLayout.dataSource(dataSource, didRemoveSections: sections, direction: direction)
		}
		collectionView!.deleteSections(sections)
		deletedSections.addIndexes(sections)
	}
	
	public func dataSource(dataSource: CollectionDataSource, didRefreshSections sections: NSIndexSet) {
		updateLog("\(__FUNCTION__) REFRESH SECTIONS: \(sections.debugLogDescription)")
		// It's not "legal" to reload a section if you also delete the section later in the same batch update. So we'll just remember that we want to reload these sections when we're performing a batch update and reload them only if they weren't also deleted.
		if isPerformingUpdates {
			reloadedSections.addIndexes(sections)
		} else {
			collectionView!.reloadSections(sections)
		}
	}
	
	public func dataSource(dataSource: CollectionDataSource, didMoveSectionFrom oldSection: Int, to newSection: Int, direction: SectionOperationDirection?) {
		updateLog("\(__FUNCTION__) MOVE SECTION: \(oldSection) TO: \(newSection)")
		let layout = collectionView!.collectionViewLayout
		if let collectionLayout = layout as? CollectionViewLayout {
			collectionLayout.dataSource(dataSource, didMoveSectionFrom: oldSection, to: newSection, direction: direction)
		}
		collectionView!.moveSection(oldSection, toSection: newSection)
	}
	
	public func dataSourceDidReloadData(dataSource: CollectionDataSource) {
		updateLog("\(__FUNCTION__) RELOAD")
		collectionView!.reloadData()
	}
	
	public func dataSource(dataSource: CollectionDataSource, performBatchUpdate update: () -> Void, complete: (() -> Void)?) {
		performBatchUpdates(update, completion: complete)
	}
	
	private func performBatchUpdates(updates: dispatch_block_t, completion: dispatch_block_t? = nil) {
		requireMainThread()
		// We're currently updating the collection view, so we can't call -performBatchUpdates:completion: on it
		guard !isPerformingUpdates else {
			updateLog("\(__FUNCTION__) PERFORMING UPDATES IMMEDIATELy")
			// Chain the completion handler if one was given
			if completion != nil {
				let oldCompletion = updateCompletionHandler
				updateCompletionHandler = {
					oldCompletion?()
					completion?()
				}
			}
			// Now immediately execute the new updates
			updates()
			return
		}
		
		if UpdateDebugging {
			UpdateNumber += 1
			updateLog("\(__FUNCTION__) \(UpdateNumber): PERFORMING BATCH UPDATE")
		}
		
		clearSectionUpdateInfo()
		
		var completionHandler: dispatch_block_t?
		
		collectionView!.performBatchUpdates({
			updateLog("\(__FUNCTION__) \(UpdateNumber): BEGIN UPDATE")
			self.isPerformingUpdates = true
			self.updateCompletionHandler = completion
			
			updates()
			
			// Perform delayed reloadSections calls
			let sectionsToReload = NSMutableIndexSet(indexSet: self.reloadedSections)
			
			// UICollectionView doesn't like it if you reload a section that was either inserted or deleted
			sectionsToReload.removeIndexes(self.deletedSections)
			sectionsToReload.removeIndexes(self.insertedSections)
			
			self.collectionView!.reloadSections(sectionsToReload)
			updateLog("\(__FUNCTION__) \(UpdateNumber): RELOADED SECTIONS: \(sectionsToReload.debugLogDescription)")
			
			updateLog("\(__FUNCTION__) \(UpdateNumber): END UPDATE")
			self.isPerformingUpdates = false
			completionHandler = self.updateCompletionHandler
			self.updateCompletionHandler = nil
			self.clearSectionUpdateInfo()
			}) { (_: Bool) in
				updateLog("\(__FUNCTION__) \(UpdateNumber): BEGIN COMPLETION HANDLER")
				completionHandler?()
				updateLog("\(__FUNCTION__) \(UpdateNumber): END COMPLETION HANDLER")
		}
	}
	
	public func dataSource(dataSource: CollectionDataSource, didPresentActivityIndicatorForSections sections: NSIndexSet) {
		updateLog("\(__FUNCTION__) Present activity indicator: sections=\(sections.debugLogDescription)")
		reloadedSections.addIndexes(sections)
	}
	
	public func dataSource(dataSource: CollectionDataSource, didPresentPlaceholderForSections sections: NSIndexSet) {
		updateLog("\(__FUNCTION__) Present placeholder: sections=\(sections.debugLogDescription)")
		reloadedSections.addIndexes(sections)
	}
	
	public func dataSource(dataSource: CollectionDataSource, didDismissPlaceholderForSections sections: NSIndexSet) {
		updateLog("\(__FUNCTION__) Dismiss placeholder: sections=\(sections.debugLogDescription)")
		reloadedSections.addIndexes(sections)
	}
	
	public func dataSource(dataSource: CollectionDataSource, didUpdate supplementaryItem: SupplementaryItem, at indexPaths: [NSIndexPath]) {
		let collectionView = self.collectionView!
		let kind = supplementaryItem.elementKind
		
		performBatchUpdates({
			let contextClass = collectionView.collectionViewLayout.dynamicType.invalidationContextClass() as! UICollectionViewLayoutInvalidationContext.Type
			let context = contextClass.init()
			
			for indexPath in indexPaths {
				let localDataSource = dataSource.dataSourceForSectionAtIndex(indexPath.section)
				guard let view = self.collectionView(collectionView, visibleViewForSupplementaryElementOfKind: kind, at: indexPath) else {
					continue
				}
				let localIndexPath = dataSource.localIndexPathForGlobal(indexPath)
				supplementaryItem.configureView?(view: view, dataSource: localDataSource, indexPath: localIndexPath)
			}
			
			context.invalidateSupplementaryElementsOfKind(kind, atIndexPaths: indexPaths)
			// XXX: Do we need to invalidate the layout here?
		})
	}
	
}
