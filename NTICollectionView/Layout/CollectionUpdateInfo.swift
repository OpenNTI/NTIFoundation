//
//  CollectionUpdateInfo.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/25/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

/// A container for keeping track of collection view updates.
public struct CollectionUpdateInfo {
	
	public var insertedIndexPaths: Set<NSIndexPath> = []
	public var removedIndexPaths: Set<NSIndexPath> = []
	public var reloadedIndexPaths: Set<NSIndexPath> = []
	
	public var insertedSections: Set<Int> = []
	public var removedSections: Set<Int> = []
	public var reloadedSections: Set<Int> = []
	
	/// Additional index paths to delete for given kinds of elements during updates.
	public var additionalDeletedIndexPathsByKind: [String: [NSIndexPath]] = [:]
	/// Additional index paths to insert for given kinds of elements during updates.
	public var additionalInsertedIndexPathsByKind: [String: [NSIndexPath]] = [:]
	
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
