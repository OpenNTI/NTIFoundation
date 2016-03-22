//
//  CollectionViewWrapper.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/24/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

/// An object that pretends to be (or actually is) a `UICollectionView` that handles transparently mapping from local to global index paths
public protocol CollectionViewWrapper: NSObjectProtocol {
	
	var collectionView: UICollectionView { get }
	
	var dataSource: UICollectionViewDataSource? { get }
	
	var mapping: DataSourceMapping? { get }
	
	var isUsedForMeasuring: Bool { get }
	
}

extension CollectionViewWrapper {
	
	public func localSectionForGlobalSection(globalSection: Int) -> Int {
		return mapping?.localSectionForGlobalSection(globalSection) ?? globalSection
	}
	
	public func localSectionsForGlobalSections(globalSections: NSIndexSet) -> NSIndexSet {
		return mapping?.localSectionsForGlobalSections(globalSections) ?? globalSections
	}
	
	public func globalSectionForLocalSection(section: Int) -> Int {
		return mapping?.globalSectionForLocalSection(section) ?? section
	}
	
	public func globalSectionsForLocalSections(sections: NSIndexSet) -> NSIndexSet {
		return mapping?.globalSectionsForLocalSections(sections) ?? sections
	}
	
	public func localIndexPathForGlobal(indexPath: NSIndexPath) -> NSIndexPath {
		return mapping?.localIndexPathForGlobal(indexPath) ?? indexPath
	}
	
	public func localIndexPathsForGlobal(indexPaths: [NSIndexPath]) -> [NSIndexPath] {
		return mapping?.localIndexPathsForGlobal(indexPaths) ?? indexPaths
	}
	
	public func globalIndexPathForLocal(indexPath: NSIndexPath) -> NSIndexPath {
		return mapping?.globalIndexPathForLocal(indexPath) ?? indexPath
	}
	
	public func globalIndexPathsForLocal(indexPaths: [NSIndexPath]) -> [NSIndexPath] {
		return mapping?.globalIndexPathsForLocal(indexPaths) ?? indexPaths
	}
	
}


/// Handles transparently mapping from local to global index paths.
public class WrapperCollectionView: UICollectionView, CollectionViewWrapper {

	public init(collectionView: UICollectionView, mapping: DataSourceMapping?, isUsedForMeasuring: Bool) {
		self.collectionView = collectionView
		self.mapping = mapping
		self.isUsedForMeasuring = isUsedForMeasuring
		super.init(frame: CGRectZero, collectionViewLayout: UICollectionViewLayout())
		
		if let registrarVendor = collectionView.collectionViewLayout as? ShadowRegistrarVending {
			shadowRegistrar = registrarVendor.shadowRegistrar
		}
	}
	
	public convenience init(collectionView: UICollectionView, mapping: DataSourceMapping?) {
		var isUsedForMeasuring = false
		if let wrapper = collectionView as? CollectionViewWrapper {
			isUsedForMeasuring = wrapper.isUsedForMeasuring
		}
		self.init(collectionView: collectionView, mapping: mapping, isUsedForMeasuring: isUsedForMeasuring)
	}

	public required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
	public private(set) var collectionView: UICollectionView
	
	public override var dataSource: UICollectionViewDataSource? {
		get {
			return collectionView.dataSource
		}
		set {
			collectionView.dataSource = newValue
		}
	}
	
	public private(set) var mapping: DataSourceMapping?
	
	public private(set) var isUsedForMeasuring: Bool
	
	private var shadowRegistrar: ShadowRegistrar?
	
	// MARK: - Forwarding to internal representation
	
	public override func forwardingTargetForSelector(aSelector: Selector) -> AnyObject? {
		return collectionView
	}
	
	// MARK: - UICollectionView registration methods
	
	public override func registerClass(cellClass: AnyClass?, forCellWithReuseIdentifier identifier: String) {
		shadowRegistrar?.registerClass(cellClass as! UICollectionReusableView.Type, forCellWith: identifier)
		collectionView.registerClass(cellClass, forCellWithReuseIdentifier: identifier)
	}
	
	public override func registerNib(nib: UINib?, forCellWithReuseIdentifier identifier: String) {
		shadowRegistrar?.registerNib(nib!, forCellWith: identifier)
		collectionView.registerNib(nib, forCellWithReuseIdentifier: identifier)
	}
	
	public override func registerClass(viewClass: AnyClass?, forSupplementaryViewOfKind elementKind: String, withReuseIdentifier identifier: String) {
		shadowRegistrar?.registerClass(viewClass as! UICollectionReusableView.Type, forSupplementaryViewOf: elementKind, with: identifier)
		collectionView.registerClass(viewClass, forSupplementaryViewOfKind: elementKind, withReuseIdentifier: identifier)
	}
	
	public override func registerNib(nib: UINib?, forSupplementaryViewOfKind kind: String, withReuseIdentifier identifier: String) {
		shadowRegistrar?.registerNib(nib!, forSupplementaryViewOf: kind, with: identifier)
		collectionView.registerNib(nib, forSupplementaryViewOfKind: kind, withReuseIdentifier: identifier)
	}
	
	// MARK: - UICollectionView deque methods
	
	public override func dequeueReusableCellWithReuseIdentifier(identifier: String, forIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let globalIndexPath = globalIndexPathForLocal(indexPath)
		if isUsedForMeasuring, let shadowRegistrar = shadowRegistrar {
			return shadowRegistrar.dequeReusableCell(with: identifier, for: globalIndexPath, collectionView: collectionView) as! UICollectionViewCell
		}
		return collectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: globalIndexPath)
	}
	
	public override func dequeueReusableSupplementaryViewOfKind(elementKind: String, withReuseIdentifier identifier: String, forIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
		let globalIndexPath = globalIndexPathForLocal(indexPath)
		if isUsedForMeasuring, let shadowRegistrar = shadowRegistrar {
			return shadowRegistrar.dequeReusableSupplementaryView(of: elementKind, with: identifier, for: globalIndexPath, collectionView: collectionView)
		}
		return collectionView.dequeueReusableSupplementaryViewOfKind(elementKind, withReuseIdentifier: identifier, forIndexPath: globalIndexPath)
	}
	
	// MARK: - UICollectionView helper methods
	
	public func dequeueReusableCellWithClass(viewClass: UICollectionReusableView.Type, for indexPath: NSIndexPath) -> UICollectionViewCell {
		let reuseIdentifier = NSStringFromClass(viewClass)
		return dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath)
	}
	
	public func dequeueReusableSupplementaryViewOfKind(elementKind: String, withClass viewClass: UICollectionReusableView.Type, forIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
		let reuseIdentifier = NSStringFromClass(viewClass)
		return dequeueReusableSupplementaryViewOfKind(elementKind, withReuseIdentifier: reuseIdentifier, forIndexPath: indexPath)
	}
	
	// MARK: - UICollectionView methods that accept index paths
	
	public override func indexPathForCell(cell: UICollectionViewCell) -> NSIndexPath? {
		guard let globalIndexPath = collectionView.indexPathForCell(cell) else {
			return nil
		}
		return localIndexPathForGlobal(globalIndexPath)
	}
	
	public override func moveSection(section: Int, toSection newSection: Int) {
		let globalSection = globalSectionForLocalSection(section)
		let globalNewSection = globalSectionForLocalSection(newSection)
		collectionView.moveSection(globalSection, toSection: globalNewSection)
	}
	
	public override func indexPathsForSelectedItems() -> [NSIndexPath]? {
		guard let globalIndexPaths = collectionView.indexPathsForSelectedItems() else {
			return nil
		}
		return localIndexPathsForGlobal(globalIndexPaths)
	}
	
	public override func selectItemAtIndexPath(indexPath: NSIndexPath?, animated: Bool, scrollPosition: UICollectionViewScrollPosition) {
		var globalIndexPath: NSIndexPath?
		if let indexPath = indexPath {
			globalIndexPath = globalIndexPathForLocal(indexPath)
		}
		collectionView.selectItemAtIndexPath(globalIndexPath, animated: animated, scrollPosition: scrollPosition)
	}
	
	public override func deselectItemAtIndexPath(indexPath: NSIndexPath, animated: Bool) {
		let globalIndexPath = globalIndexPathForLocal(indexPath)
		collectionView.deselectItemAtIndexPath(globalIndexPath, animated: animated)
	}
	
	public override func numberOfItemsInSection(section: Int) -> Int {
		let globalSection = globalSectionForLocalSection(section)
		return collectionView.numberOfItemsInSection(globalSection)
	}
	
	public override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
		let globalIndexPath = globalIndexPathForLocal(indexPath)
		return collectionView.layoutAttributesForItemAtIndexPath(globalIndexPath)
	}
	
	public override func layoutAttributesForSupplementaryElementOfKind(kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
		let globalIndexPath = globalIndexPathForLocal(indexPath)
		return collectionView.layoutAttributesForSupplementaryElementOfKind(kind, atIndexPath: globalIndexPath)
	}
	
	public override func indexPathForItemAtPoint(point: CGPoint) -> NSIndexPath? {
		guard let globalIndexPath = collectionView.indexPathForItemAtPoint(point) else {
			return nil
		}
		return localIndexPathForGlobal(globalIndexPath)
	}
	
	public override func cellForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewCell? {
		let globalIndexPath = globalIndexPathForLocal(indexPath)
		return collectionView.cellForItemAtIndexPath(globalIndexPath)
	}
	
	public override func indexPathsForVisibleItems() -> [NSIndexPath] {
		let globalIndexPaths = collectionView.indexPathsForVisibleItems()
		return localIndexPathsForGlobal(globalIndexPaths)
	}
	
	public override func scrollToItemAtIndexPath(indexPath: NSIndexPath, atScrollPosition scrollPosition: UICollectionViewScrollPosition, animated: Bool) {
		let globalIndexPath = globalIndexPathForLocal(indexPath)
		collectionView.scrollToItemAtIndexPath(globalIndexPath, atScrollPosition: scrollPosition, animated: animated)
	}
	
	public override func insertSections(sections: NSIndexSet) {
		let globalSections = globalSectionsForLocalSections(sections)
		collectionView.insertSections(globalSections)
	}
	
	public override func deleteSections(sections: NSIndexSet) {
		let globalSections = globalSectionsForLocalSections(sections)
		collectionView.deleteSections(globalSections)
	}
	
	public override func reloadSections(sections: NSIndexSet) {
		let globalSections = globalSectionsForLocalSections(sections)
		collectionView.reloadSections(globalSections)
	}
	
	public override func insertItemsAtIndexPaths(indexPaths: [NSIndexPath]) {
		let globalIndexPaths = globalIndexPathsForLocal(indexPaths)
		collectionView.insertItemsAtIndexPaths(globalIndexPaths)
	}
	
	public override func deleteItemsAtIndexPaths(indexPaths: [NSIndexPath]) {
		let globalIndexPaths = globalIndexPathsForLocal(indexPaths)
		collectionView.deleteItemsAtIndexPaths(globalIndexPaths)
	}
	
	public override func reloadItemsAtIndexPaths(indexPaths: [NSIndexPath]) {
		let globalIndexPaths = globalIndexPathsForLocal(indexPaths)
		collectionView.reloadItemsAtIndexPaths(globalIndexPaths)
	}
	
	public override func moveItemAtIndexPath(indexPath: NSIndexPath, toIndexPath newIndexPath: NSIndexPath) {
		let globalIndexPath = globalIndexPathForLocal(indexPath)
		let globalNewIndexPath = globalIndexPathForLocal(newIndexPath)
		collectionView.moveItemAtIndexPath(globalIndexPath, toIndexPath: globalNewIndexPath)
	}
	
	@available(iOS 9.0, *)
	public override func supplementaryViewForElementKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
		let globalIndexPath = globalIndexPathForLocal(indexPath)
		return collectionView.supplementaryViewForElementKind(elementKind, atIndexPath: globalIndexPath)
	}
	
	@available(iOS 9.0, *)
	public override func indexPathsForVisibleSupplementaryElementsOfKind(elementKind: String) -> [NSIndexPath] {
		let globalIndexPaths = collectionView.indexPathsForVisibleSupplementaryElementsOfKind(elementKind)
		let localIndexPaths = localIndexPathsForGlobal(globalIndexPaths)
		return localIndexPaths
	}
	
	@available(iOS 9.0, *)
	public override func beginInteractiveMovementForItemAtIndexPath(indexPath: NSIndexPath) -> Bool {
		let globalIndexPath = globalIndexPathForLocal(indexPath)
		return collectionView.beginInteractiveMovementForItemAtIndexPath(globalIndexPath)
	}
	
}
