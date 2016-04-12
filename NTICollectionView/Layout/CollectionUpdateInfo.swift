//
//  CollectionUpdateInfo.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/25/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

/// A container for keeping track of collection view updates.
public protocol CollectionUpdateProvider {
	
	var insertedIndexPaths: Set<NSIndexPath> { get set }
	var removedIndexPaths: Set<NSIndexPath> { get set }
	var reloadedIndexPaths: Set<NSIndexPath> { get set }
	
	var insertedSections: Set<Int> { get set }
	var removedSections: Set<Int> { get set }
	var reloadedSections: Set<Int> { get set }
	
	/// Additional index paths to delete for given kinds of elements during updates.
	var additionalDeletedIndexPathsByKind: [String: [NSIndexPath]] { get set }
	/// Additional index paths to insert for given kinds of elements during updates.
	var additionalInsertedIndexPathsByKind: [String: [NSIndexPath]] { get set }
	
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

/// A container for keeping track of collection view updates.
public struct CollectionUpdateInfo: CollectionUpdateProvider {
	
	public var insertedIndexPaths: Set<NSIndexPath> = []
	public var removedIndexPaths: Set<NSIndexPath> = []
	public var reloadedIndexPaths: Set<NSIndexPath> = []
	
	public var insertedSections: Set<Int> = []
	public var removedSections: Set<Int> = []
	public var reloadedSections: Set<Int> = []
	
	public var additionalDeletedIndexPathsByKind: [String: [NSIndexPath]] = [:]
	public var additionalInsertedIndexPathsByKind: [String: [NSIndexPath]] = [:]
	
}
