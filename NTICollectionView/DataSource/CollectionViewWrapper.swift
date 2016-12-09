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
	
	public func localSectionForGlobalSection(_ globalSection: Int) -> Int {
		return mapping?.localSectionForGlobalSection(globalSection) ?? globalSection
	}
	
	public func localSectionsForGlobalSections(_ globalSections: IndexSet) -> IndexSet {
		return mapping?.localSectionsForGlobalSections(globalSections) ?? globalSections
	}
	
	public func globalSectionForLocalSection(_ section: Int) -> Int {
		return mapping?.globalSectionForLocalSection(section) ?? section
	}
	
	public func globalSectionsForLocalSections(_ sections: IndexSet) -> IndexSet {
		return mapping?.globalSectionsForLocalSections(sections) ?? sections
	}
	
	public func localIndexPathForGlobal(_ indexPath: IndexPath) -> IndexPath {
		return mapping?.localIndexPathForGlobal(indexPath) ?? indexPath
	}
	
	public func localIndexPathsForGlobal(_ indexPaths: [IndexPath]) -> [IndexPath] {
		return mapping?.localIndexPathsForGlobal(indexPaths) ?? indexPaths
	}
	
	public func globalIndexPathForLocal(_ indexPath: IndexPath) -> IndexPath {
		return mapping?.globalIndexPathForLocal(indexPath) ?? indexPath
	}
	
	public func globalIndexPathsForLocal(_ indexPaths: [IndexPath]) -> [IndexPath] {
		return mapping?.globalIndexPathsForLocal(indexPaths) ?? indexPaths
	}
	
}


/// Handles transparently mapping from local to global index paths.
open class WrapperCollectionView: UICollectionView, CollectionViewWrapper {

	public init(collectionView: UICollectionView, mapping: DataSourceMapping?, isUsedForMeasuring: Bool) {
		self.collectionView = collectionView
		self.mapping = mapping
		self.isUsedForMeasuring = isUsedForMeasuring
		super.init(frame: CGRect.zero, collectionViewLayout: UICollectionViewLayout())
		
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
	
	open fileprivate(set) var collectionView: UICollectionView
	
	open override var dataSource: UICollectionViewDataSource? {
		get {
			return collectionView.dataSource
		}
		set {
			collectionView.dataSource = newValue
		}
	}
	
	open fileprivate(set) var mapping: DataSourceMapping?
	
	open fileprivate(set) var isUsedForMeasuring: Bool
	
	fileprivate var shadowRegistrar: ShadowRegistrar?
	
	// MARK: - Forwarding to internal representation
	
	open override func forwardingTarget(for aSelector: Selector) -> Any? {
		return collectionView
	}
	
	// MARK: - UICollectionView registration methods
	
	open override func register(_ cellClass: AnyClass?, forCellWithReuseIdentifier identifier: String) {
		shadowRegistrar?.registerClass(cellClass as! UICollectionReusableView.Type, forCellWith: identifier)
		collectionView.register(cellClass, forCellWithReuseIdentifier: identifier)
	}
	
	open override func register(_ nib: UINib?, forCellWithReuseIdentifier identifier: String) {
		shadowRegistrar?.registerNib(nib!, forCellWith: identifier)
		collectionView.register(nib, forCellWithReuseIdentifier: identifier)
	}
	
	open override func register(_ viewClass: AnyClass?, forSupplementaryViewOfKind elementKind: String, withReuseIdentifier identifier: String) {
		shadowRegistrar?.registerClass(viewClass as! UICollectionReusableView.Type, forSupplementaryViewOf: elementKind, with: identifier)
		collectionView.register(viewClass, forSupplementaryViewOfKind: elementKind, withReuseIdentifier: identifier)
	}
	
	open override func register(_ nib: UINib?, forSupplementaryViewOfKind kind: String, withReuseIdentifier identifier: String) {
		shadowRegistrar?.registerNib(nib!, forSupplementaryViewOf: kind, with: identifier)
		collectionView.register(nib, forSupplementaryViewOfKind: kind, withReuseIdentifier: identifier)
	}
	
	// MARK: - UICollectionView deque methods
	
	open override func dequeueReusableCell(withReuseIdentifier identifier: String, for indexPath: IndexPath) -> UICollectionViewCell {
		let globalIndexPath = globalIndexPathForLocal(indexPath)
		if isUsedForMeasuring, let shadowRegistrar = shadowRegistrar {
			return shadowRegistrar.dequeReusableCell(with: identifier, for: globalIndexPath, collectionView: collectionView) as! UICollectionViewCell
		}
		return collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: globalIndexPath)
	}
	
	open override func dequeueReusableSupplementaryView(ofKind elementKind: String, withReuseIdentifier identifier: String, for indexPath: IndexPath) -> UICollectionReusableView {
		let globalIndexPath = globalIndexPathForLocal(indexPath)
		if isUsedForMeasuring, let shadowRegistrar = shadowRegistrar {
			return shadowRegistrar.dequeReusableSupplementaryView(of: elementKind, with: identifier, for: globalIndexPath, collectionView: collectionView)
		}
		return collectionView.dequeueReusableSupplementaryView(ofKind: elementKind, withReuseIdentifier: identifier, for: globalIndexPath)
	}
	
	// MARK: - UICollectionView helper methods
	
	open func dequeueReusableCellWithClass(_ viewClass: UICollectionReusableView.Type, for indexPath: IndexPath) -> UICollectionViewCell {
		let reuseIdentifier = NSStringFromClass(viewClass)
		return dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
	}
	
	open func dequeueReusableSupplementaryViewOfKind(_ elementKind: String, withClass viewClass: UICollectionReusableView.Type, forIndexPath indexPath: IndexPath) -> UICollectionReusableView {
		let reuseIdentifier = NSStringFromClass(viewClass)
		return dequeueReusableSupplementaryView(ofKind: elementKind, withReuseIdentifier: reuseIdentifier, for: indexPath)
	}
	
	// MARK: - UICollectionView methods that accept index paths
	
	open override func indexPath(for cell: UICollectionViewCell) -> IndexPath? {
		guard let globalIndexPath = collectionView.indexPath(for: cell) else {
			return nil
		}
		return localIndexPathForGlobal(globalIndexPath)
	}
	
	open override func moveSection(_ section: Int, toSection newSection: Int) {
		let globalSection = globalSectionForLocalSection(section)
		let globalNewSection = globalSectionForLocalSection(newSection)
		collectionView.moveSection(globalSection, toSection: globalNewSection)
	}
	
	open override var indexPathsForSelectedItems : [IndexPath]? {
		guard let globalIndexPaths = collectionView.indexPathsForSelectedItems else {
			return nil
		}
		return localIndexPathsForGlobal(globalIndexPaths)
	}
	
	open override func selectItem(at indexPath: IndexPath?, animated: Bool, scrollPosition: UICollectionViewScrollPosition) {
		var globalIndexPath: IndexPath?
		if let indexPath = indexPath {
			globalIndexPath = globalIndexPathForLocal(indexPath)
		}
		collectionView.selectItem(at: globalIndexPath, animated: animated, scrollPosition: scrollPosition)
	}
	
	open override func deselectItem(at indexPath: IndexPath, animated: Bool) {
		let globalIndexPath = globalIndexPathForLocal(indexPath)
		collectionView.deselectItem(at: globalIndexPath, animated: animated)
	}
	
	open override func numberOfItems(inSection section: Int) -> Int {
		let globalSection = globalSectionForLocalSection(section)
		return collectionView.numberOfItems(inSection: globalSection)
	}
	
	open override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
		let globalIndexPath = globalIndexPathForLocal(indexPath)
		return collectionView.layoutAttributesForItem(at: globalIndexPath)
	}
	
	open override func layoutAttributesForSupplementaryElement(ofKind kind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
		let globalIndexPath = globalIndexPathForLocal(indexPath)
		return collectionView.layoutAttributesForSupplementaryElement(ofKind: kind, at: globalIndexPath)
	}
	
	open override func indexPathForItem(at point: CGPoint) -> IndexPath? {
		guard let globalIndexPath = collectionView.indexPathForItem(at: point) else {
			return nil
		}
		return localIndexPathForGlobal(globalIndexPath)
	}
	
	open override func cellForItem(at indexPath: IndexPath) -> UICollectionViewCell? {
		let globalIndexPath = globalIndexPathForLocal(indexPath)
		return collectionView.cellForItem(at: globalIndexPath)
	}
	
	open override var indexPathsForVisibleItems : [IndexPath] {
		let globalIndexPaths = collectionView.indexPathsForVisibleItems
		return localIndexPathsForGlobal(globalIndexPaths)
	}
	
	open override func scrollToItem(at indexPath: IndexPath, at scrollPosition: UICollectionViewScrollPosition, animated: Bool) {
		let globalIndexPath = globalIndexPathForLocal(indexPath)
		collectionView.scrollToItem(at: globalIndexPath, at: scrollPosition, animated: animated)
	}
	
	open override func insertSections(_ sections: IndexSet) {
		let globalSections = globalSectionsForLocalSections(sections)
		collectionView.insertSections(globalSections)
	}
	
	open override func deleteSections(_ sections: IndexSet) {
		let globalSections = globalSectionsForLocalSections(sections)
		collectionView.deleteSections(globalSections)
	}
	
	open override func reloadSections(_ sections: IndexSet) {
		let globalSections = globalSectionsForLocalSections(sections)
		collectionView.reloadSections(globalSections)
	}
	
	open override func insertItems(at indexPaths: [IndexPath]) {
		let globalIndexPaths = globalIndexPathsForLocal(indexPaths)
		collectionView.insertItems(at: globalIndexPaths)
	}
	
	open override func deleteItems(at indexPaths: [IndexPath]) {
		let globalIndexPaths = globalIndexPathsForLocal(indexPaths)
		collectionView.deleteItems(at: globalIndexPaths)
	}
	
	open override func reloadItems(at indexPaths: [IndexPath]) {
		let globalIndexPaths = globalIndexPathsForLocal(indexPaths)
		collectionView.reloadItems(at: globalIndexPaths)
	}
	
	open override func moveItem(at indexPath: IndexPath, to newIndexPath: IndexPath) {
		let globalIndexPath = globalIndexPathForLocal(indexPath)
		let globalNewIndexPath = globalIndexPathForLocal(newIndexPath)
		collectionView.moveItem(at: globalIndexPath, to: globalNewIndexPath)
	}
	
	@available(iOS 9.0, *)
	open override func supplementaryView(forElementKind elementKind: String, at indexPath: IndexPath) -> UICollectionReusableView? {
		let globalIndexPath = globalIndexPathForLocal(indexPath)
		return collectionView.supplementaryView(forElementKind: elementKind, at: globalIndexPath)
	}
	
	@available(iOS 9.0, *)
	open override func indexPathsForVisibleSupplementaryElements(ofKind elementKind: String) -> [IndexPath] {
		let globalIndexPaths = collectionView.indexPathsForVisibleSupplementaryElements(ofKind: elementKind)
		let localIndexPaths = localIndexPathsForGlobal(globalIndexPaths)
		return localIndexPaths
	}
	
	@available(iOS 9.0, *)
	open override func beginInteractiveMovementForItem(at indexPath: IndexPath) -> Bool {
		let globalIndexPath = globalIndexPathForLocal(indexPath)
		return collectionView.beginInteractiveMovementForItem(at: globalIndexPath)
	}
	
}
