//
//  CollectionUpdateInfo.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/25/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

// MARK: - CollectionUpdateProvider

/// A container for keeping track of collection view updates.
public protocol CollectionUpdateProvider {
	
	var insertedIndexPaths: Set<IndexPath> { get set }
	var removedIndexPaths: Set<IndexPath> { get set }
	var reloadedIndexPaths: Set<IndexPath> { get set }
	
	var insertedSections: Set<Int> { get set }
	var removedSections: Set<Int> { get set }
	var reloadedSections: Set<Int> { get set }
	
	/// Additional index paths to delete for given kinds of elements during updates.
	var additionalDeletedIndexPathsByKind: [String: [IndexPath]] { get set }
	/// Additional index paths to insert for given kinds of elements during updates.
	var additionalInsertedIndexPathsByKind: [String: [IndexPath]] { get set }
	
	mutating func reset()
}

extension CollectionUpdateProvider {
	
	public mutating func reset() {
		insertedIndexPaths = []
		removedIndexPaths = []
		reloadedIndexPaths = []
		insertedSections = []
		removedSections = []
		reloadedSections = []
		additionalDeletedIndexPathsByKind = [:]
		additionalInsertedIndexPathsByKind = [:]
	}
	
}

// MARK: - CollectionUpdateInfo

/// A container for keeping track of collection view updates.
public struct CollectionUpdateInfo: CollectionUpdateProvider {
	
	public var insertedIndexPaths: Set<IndexPath> = []
	public var removedIndexPaths: Set<IndexPath> = []
	public var reloadedIndexPaths: Set<IndexPath> = []
	
	public var insertedSections: Set<Int> = []
	public var removedSections: Set<Int> = []
	public var reloadedSections: Set<Int> = []
	
	public var additionalDeletedIndexPathsByKind: [String: [IndexPath]] = [:]
	public var additionalInsertedIndexPathsByKind: [String: [IndexPath]] = [:]
	
}

// MARK: - CollectionUpdateInfoWrapper

public protocol CollectionUpdateInfoWrapper: CollectionUpdateProvider {
	
	var updateInfo: CollectionUpdateInfo { get set }
	
}

extension CollectionUpdateInfoWrapper {
	
	public var insertedIndexPaths: Set<IndexPath> {
		get {
			return updateInfo.insertedIndexPaths
		}
		set {
			updateInfo.insertedIndexPaths = newValue
		}
	}
	
	public var removedIndexPaths: Set<IndexPath> {
		get {
			return updateInfo.removedIndexPaths
		}
		set {
			updateInfo.removedIndexPaths = newValue
		}
	}
	
	public var reloadedIndexPaths: Set<IndexPath> {
		get {
			return updateInfo.reloadedIndexPaths
		}
		set {
			updateInfo.reloadedIndexPaths = newValue
		}
	}
	
	public var insertedSections: Set<Int> {
		get {
			return updateInfo.insertedSections
		}
		set {
			updateInfo.insertedSections = newValue
		}
	}
	
	public var removedSections: Set<Int> {
		get {
			return updateInfo.removedSections
		}
		set {
			updateInfo.removedSections = newValue
		}
	}
	
	public var reloadedSections: Set<Int> {
		get {
			return updateInfo.reloadedSections
		}
		set {
			updateInfo.reloadedSections = newValue
		}
	}
	
	public var additionalDeletedIndexPathsByKind: [String: [IndexPath]] {
		get {
			return updateInfo.additionalDeletedIndexPathsByKind
		}
		set {
			updateInfo.additionalDeletedIndexPathsByKind = newValue
		}
	}
	
	public var additionalInsertedIndexPathsByKind: [String: [IndexPath]] {
		get {
			return updateInfo.additionalInsertedIndexPathsByKind
		}
		set {
			updateInfo.additionalInsertedIndexPathsByKind = newValue
		}
	}
	
}
