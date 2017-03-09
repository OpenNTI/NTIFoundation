//
//  CollectionViewController.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/25/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

private var kvoDataSourceContext = "DataSourceContext"
private var updateNumber = 0

open class CollectionViewController: UICollectionViewController, CollectionDataSourceDelegate, CollectionViewSupplementaryViewTracking {
	
	fileprivate var updateCompletionHandler: (()->())?
	fileprivate var reloadedSections = IndexSet()
	fileprivate var deletedSections = IndexSet()
	fileprivate var insertedSections = IndexSet()
	fileprivate var isPerformingUpdates = false
	fileprivate var isObservingDataSource = false
	fileprivate var visibleSupplementaryViews: [String: [IndexPath: UICollectionReusableView]] = [:]
	
	open var contentInsets: UIEdgeInsets {
		get {
			if hasAssignedContentInsets {
				return _contentInsets
			}
			
			let orientation = UIApplication.shared.statusBarOrientation
			let bounds = UIScreen.main.bounds
			
			let isNavigationBarHidden = navigationController?.navigationBar.isHidden ?? true
			let isTabBarHidden = tabBarController?.tabBar.isHidden ?? true
			
			// If the content insets were calculated, and the orientation is the same, return calculated value
			guard !hasCalculatedContentInsets
				|| orientation != orientationForCalculatedInsets
				|| bounds != applicationFrameForCalculatedInsets
				|| isNavigationBarHidden == calculatedNavigationBarHiddenValue
				|| isTabBarHidden == calculatedTabBarHiddenValue else {
					return _contentInsets
			}
			
			// Grab our frame in window coordinates
			let rect = view.convert(view.bounds, to: nil)
			
			// No value has been assigned, so we need to compute it
			let application = UIApplication.shared
			
			var insets = UIEdgeInsets.zero
			
			if !application.isStatusBarHidden {
				// The status bar doesn't seem to adjust when rotated
				let height = orientation == .portrait ? application.statusBarFrame.height : application.statusBarFrame.width
				if rect.minY < height {
					insets.top += 20
				}
			}
			
			// If the navigation bar ISN'T hidden, we'll set our top inset to the bottom of the navigation bar. This allows the system to position things correctly to account for the double height status bar.
			if !isNavigationBarHidden, let navigationBar = navigationController?.navigationBar {
				// During rotation, the navigation bar (and possibly tab bar) doesn't resize immediately. Force it to have its new size.
				navigationBar.sizeToFit()
				let frame = navigationBar.convert(navigationBar.bounds, to: nil)
				
				if rect.intersects(frame) {
					insets.top += frame.maxY - frame.minY
				}
			}
			
			if !isTabBarHidden, let tabBar = tabBarController?.tabBar {
				// During rotation, the navigation bar (and possibly tab bar) doesn't resize immediately. Force it to have its new size.
				tabBar.sizeToFit()
				let frame = tabBar.convert(tabBar.bounds, to: nil)
				
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
	fileprivate var _contentInsets = UIEdgeInsets.zero
	fileprivate var hasAssignedContentInsets = false
	fileprivate var hasCalculatedContentInsets = false
	fileprivate var calculatedTabBarHiddenValue = false
	fileprivate var calculatedNavigationBarHiddenValue = false
	fileprivate var orientationForCalculatedInsets: UIInterfaceOrientation = .unknown
	fileprivate var applicationFrameForCalculatedInsets = CGRect.zero
	fileprivate var keyboardIsShowing = false
	fileprivate var contentInsetsBeforeShowingKeyboard = UIEdgeInsets.zero
	
	open override var collectionView: UICollectionView? {
		willSet {
			endObservingDataSource()
		}
		didSet {
			beginObservingDataSource()
		}
	}
	
	open override var isEditing: Bool {
		didSet {
			guard isEditing != oldValue else {
				return
			}
			if let layout = collectionView?.collectionViewLayout as? CollectionViewLayout {
				layout.isEditing = isEditing
			}
		}
	}
	
	deinit {
		if isViewLoaded {
			endObservingDataSource()
		}
	}
	
	fileprivate func beginObservingDataSource() {
		guard !isObservingDataSource else {
			return
		}
		collectionView!.addObserver(self, forKeyPath: "dataSource", options: [.initial, .new], context: &kvoDataSourceContext)
		isObservingDataSource = true
	}
	
	fileprivate func endObservingDataSource() {
		guard isObservingDataSource else {
			return
		}
		collectionView!.removeObserver(self, forKeyPath: "dataSource")
		isObservingDataSource = false
	}
	
	open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		guard context == &kvoDataSourceContext else {
			super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
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
	
	open override func loadView() {
		super.loadView()
		beginObservingDataSource()
	}
	
	open override func viewDidLoad() {
		super.viewDidLoad()
//		automaticallyAdjustsScrollViewInsets = false
		let insets = contentInsets
		collectionView?.contentInset = insets
		collectionView?.scrollIndicatorInsets = insets
	}
	
	open override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		guard let collectionView = self.collectionView else {
			return
		}
		
		if let dataSource = collectionView.dataSource as? CollectionDataSource {
			let wrapper = WrapperCollectionView(collectionView: collectionView, mapping: nil)
			dataSource.registerReusableViews(with: wrapper)
			dataSource.setNeedsLoadContent()
		}
	}

	open override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		isEditing = false
	}
	
	open override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		let insets = contentInsets
		let oldInsets = collectionView!.contentInset
		
		collectionView!.contentInset = insets
		collectionView!.scrollIndicatorInsets = insets
		if insets != oldInsets {
			collectionView!.collectionViewLayout.invalidateLayout()
		}
	}
	
	open override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
		clearCalculatedInsetInfo()
		super.willTransition(to: newCollection, with: coordinator)
	}
	
	open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		clearCalculatedInsetInfo()
		super.viewWillTransition(to: size, with: coordinator)
	}
	
	fileprivate func clearCalculatedInsetInfo() {
		guard !hasAssignedContentInsets else {
			return
		}
		orientationForCalculatedInsets = .unknown
		applicationFrameForCalculatedInsets = CGRect.zero
	}
	
	open func register(_ supplementaryItem: SupplementaryItem) {
		guard let collectionView = self.collectionView else {
			return
		}
		let wrapper = WrapperCollectionView(collectionView: collectionView, mapping: nil)
		wrapper.register(supplementaryItem.supplementaryViewClass, forSupplementaryViewOfKind: supplementaryItem.elementKind, withReuseIdentifier: supplementaryItem.reuseIdentifier)
	}
	
	// MARK: - UICollectionViewDelegate
	
	open override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
		return _collectionView(collectionView, shouldSelectItemAtIndexPath: indexPath)
	}
	
	open override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
		guard !isEditing else {
			return false
		}
		return _collectionView(collectionView, shouldSelectItemAtIndexPath: indexPath)
	}
	
	fileprivate func _collectionView(_ collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: IndexPath) -> Bool {
		guard let dataSource = collectionView.dataSource as? CollectionDataSource else {
			return shouldSelectItemsByDefault
		}
		let sectionDataSource = dataSource.dataSourceForSectionAtIndex(indexPath.section)
		return sectionDataSource.allowsSelection
	}
	
	fileprivate var shouldSelectItemsByDefault: Bool {
		return false
	}
	
	open override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		guard let cell = collectionView.cellForItem(at: indexPath) else {
			return
		}
		if let selectableCell = cell as? Selectable {
			selectableCell.didBecomeSelected()
		}
	}
	
	open override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
		guard let cell = collectionView.cellForItem(at: indexPath) else {
			return
		}
		if let selectableCell = cell as? Selectable {
			selectableCell.didBecomeDeselected()
		}
	}
	
	open override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		if let cell = cell as? CollectionViewCell {
			cell.onWillDisplay?()
		}
	}
	
	open override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		if let cell = cell as? CollectionViewCell {
			cell.onDidEndDisplaying?()
		}
	}
	
	open override func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
		if let supplementaryView = view as? CollectionSupplementaryView {
			supplementaryView.onWillDisplay?()
		}
		
		if #available(iOS 9, *) {
			return
		}
		if visibleSupplementaryViews[elementKind] == nil {
			visibleSupplementaryViews[elementKind] = [:]
		}
		visibleSupplementaryViews[elementKind]![indexPath] = view
	}
	
	open override func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath) {
		if let supplementaryView = view as? CollectionSupplementaryView {
			supplementaryView.onWillEndDisplaying?()
		}
		
		if #available(iOS 9, *) {
			return
		}
		visibleSupplementaryViews[elementKind]?[indexPath] = nil
	}
	
	// MARK: - CollectionSupplementaryViewTracking
	
	open func collectionView(_ collectionView: UICollectionView, visibleViewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView? {
		if #available(iOS 9, *) {
			return collectionView.supplementaryView(forElementKind: kind, at: indexPath)
		}
		return visibleSupplementaryViews[kind]?[indexPath]
	}
	
	// MARK: - CollectionDataSourceDelegate
	
	fileprivate func clearSectionUpdateInfo() {
		reloadedSections.removeAll()
		deletedSections.removeAll()
		insertedSections.removeAll()
	}
	
	open func dataSource(_ dataSource: CollectionDataSource, didInsertItemsAt indexPaths: [IndexPath]) {
		updateLog("\(#function) INSERT ITEMS: \(indexPaths)")
		collectionView!.insertItems(at: indexPaths)
	}
	
	open func dataSource(_ dataSource: CollectionDataSource, didRemoveItemsAt indexPaths: [IndexPath]) {
		updateLog("\(#function) REMOVE ITEMS: \(indexPaths)")
		collectionView!.deleteItems(at: indexPaths)
	}
	
	open func dataSource(_ dataSource: CollectionDataSource, didRefreshItemsAt indexPaths: [IndexPath]) {
		updateLog("\(#function) REFRESH ITEMS: \(indexPaths)")
		collectionView!.reloadItems(at: indexPaths)
	}
	
	open func dataSource(_ dataSource: CollectionDataSource, didMoveItemAt oldIndexPath: IndexPath, to newIndexPath: IndexPath) {
		updateLog("\(#function) MOVE ITEM: \(oldIndexPath.debugLogDescription) TO: \(newIndexPath.debugLogDescription)")
		collectionView!.moveItem(at: oldIndexPath, to: newIndexPath)
	}
	
	open func dataSource(_ dataSource: CollectionDataSource, didInsertSections sections: IndexSet, direction: SectionOperationDirection?) {
		updateLog("\(#function) INSERT SECTIONS: \(sections.debugLogDescription)")
		let layout = collectionView!.collectionViewLayout
		if let collectionLayout = layout as? CollectionViewLayout {
			collectionLayout.dataSource(dataSource, didInsertSections: sections, direction: direction)
		}
		collectionView!.insertSections(sections)
		insertedSections.formUnion(sections)
	}
	
	open func dataSource(_ dataSource: CollectionDataSource, didRemoveSections sections: IndexSet, direction: SectionOperationDirection?) {
		updateLog("\(#function) REMOVE SECTIONS: \(sections.debugLogDescription)")
		let layout = collectionView!.collectionViewLayout
		if let collectionLayout = layout as? CollectionViewLayout {
			collectionLayout.dataSource(dataSource, didRemoveSections: sections, direction: direction)
		}
		collectionView!.deleteSections(sections)
		deletedSections.formUnion(sections)
	}
	
	open func dataSource(_ dataSource: CollectionDataSource, didRefreshSections sections: IndexSet) {
		updateLog("\(#function) REFRESH SECTIONS: \(sections.debugLogDescription)")
		// It's not "legal" to reload a section if you also delete the section later in the same batch update. So we'll just remember that we want to reload these sections when we're performing a batch update and reload them only if they weren't also deleted.
		if isPerformingUpdates {
			reloadedSections.formUnion(sections)
		} else {
			collectionView!.reloadSections(sections)
		}
	}
	
	open func dataSource(_ dataSource: CollectionDataSource, didMoveSectionFrom oldSection: Int, to newSection: Int, direction: SectionOperationDirection?) {
		updateLog("\(#function) MOVE SECTION: \(oldSection) TO: \(newSection)")
		let layout = collectionView!.collectionViewLayout
		if let collectionLayout = layout as? CollectionViewLayout {
			collectionLayout.dataSource(dataSource, didMoveSectionFrom: oldSection, to: newSection, direction: direction)
		}
		collectionView!.moveSection(oldSection, toSection: newSection)
	}
	
	open func dataSourceDidReloadData(_ dataSource: CollectionDataSource) {
		updateLog("\(#function) RELOAD")
		collectionView!.reloadData()
	}
	
	open func dataSource(_ dataSource: CollectionDataSource, performBatchUpdate update: @escaping () -> Void, complete: (() -> Void)?) {
		performBatchUpdates(update, completion: complete)
	}
	
	fileprivate func performBatchUpdates(_ updates: @escaping ()->(), completion: (()->())? = nil) {
		requireMainThread()
		// We're currently updating the collection view, so we can't call -performBatchUpdates:completion: on it
		guard !isPerformingUpdates else {
			updateLog("\(#function) PERFORMING UPDATES IMMEDIATELy")
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
		
		if updateDebugging {
			updateNumber += 1
			updateLog("\(#function) \(updateNumber): PERFORMING BATCH UPDATE")
		}
		
		clearSectionUpdateInfo()
		
		var completionHandler: (()->())?
		
		collectionView!.performBatchUpdates({
			updateLog("\(#function) \(updateNumber): BEGIN UPDATE")
			self.isPerformingUpdates = true
			self.updateCompletionHandler = completion
			
			updates()
			
			// Perform delayed reloadSections calls
			var sectionsToReload = IndexSet(self.reloadedSections)
			
			// UICollectionView doesn't like it if you reload a section that was either inserted or deleted
			sectionsToReload.subtract(self.deletedSections)
			sectionsToReload.subtract(self.insertedSections)
			
			self.collectionView!.reloadSections(sectionsToReload)
			updateLog("\(#function) \(updateNumber): RELOADED SECTIONS: \(sectionsToReload.debugLogDescription)")
			
			updateLog("\(#function) \(updateNumber): END UPDATE")
			self.isPerformingUpdates = false
			completionHandler = self.updateCompletionHandler
			self.updateCompletionHandler = nil
			self.clearSectionUpdateInfo()
			}) { (_: Bool) in
				updateLog("\(#function) \(updateNumber): BEGIN COMPLETION HANDLER")
				completionHandler?()
				updateLog("\(#function) \(updateNumber): END COMPLETION HANDLER")
		}
	}
	
	open func dataSource(_ dataSource: CollectionDataSource, didPresentActivityIndicatorForSections sections: IndexSet) {
		updateLog("\(#function) Present activity indicator: sections=\(sections.debugLogDescription)")
		reloadedSections.formUnion(sections)
	}
	
	open func dataSource(_ dataSource: CollectionDataSource, didPresentPlaceholderForSections sections: IndexSet) {
		updateLog("\(#function) Present placeholder: sections=\(sections.debugLogDescription)")
		reloadedSections.formUnion(sections)
	}
	
	open func dataSource(_ dataSource: CollectionDataSource, didDismissPlaceholderForSections sections: IndexSet) {
		updateLog("\(#function) Dismiss placeholder: sections=\(sections.debugLogDescription)")
		reloadedSections.formUnion(sections)
	}
	
	open func dataSource(_ dataSource: CollectionDataSource, didUpdate supplementaryItem: SupplementaryItem, at indexPaths: [IndexPath]) {
		let collectionView = self.collectionView!
		let kind = supplementaryItem.elementKind
		
		performBatchUpdates({
			updateLog("\(#function) Batch updates: indexPaths=[\(indexPaths.map({$0.debugLogDescription}).joined(separator: ", "))]")
			
			let contextClass = type(of: collectionView.collectionViewLayout).invalidationContextClass as! UICollectionViewLayoutInvalidationContext.Type
			let context = contextClass.init()
			
			for indexPath in indexPaths {
				let localDataSource = dataSource.dataSourceForSectionAtIndex(indexPath.layoutSection)
				guard let view = self.collectionView(collectionView, visibleViewForSupplementaryElementOfKind: kind, at: indexPath),
					let localIndexPath = dataSource.localIndexPathForGlobal(indexPath) else {
						continue
				}
				supplementaryItem.configureView?(view, localDataSource, localIndexPath)
			}
			
			context.invalidateSupplementaryElements(ofKind: kind, at: indexPaths)
			
			collectionView.collectionViewLayout.invalidateLayout(with: context)
		})
	}
	
	open func dataSource(_ dataSource: CollectionDataSource, didAddChild childDataSource: CollectionDataSource) {
		guard let collectionView = self.collectionView else {
			return
		}
		let wrapper = WrapperCollectionView(collectionView: collectionView, mapping: nil)
		childDataSource.registerReusableViews(with: wrapper)
	}
	
	open func dataSource(_ dataSource: CollectionDataSource, perform update: @escaping (UICollectionView) -> Void) {
		guard let collectionView = self.collectionView else {
			return
		}
		
		dataSource.performUpdate({
			update(collectionView)
		}, complete: nil)
	}
	
}
