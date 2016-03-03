//
//  CollectionUpdateInfo.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/25/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

/// The purpose of this class will be to encapsulate some of the behavior of `CollectionViewLayout`.
public struct CollectionUpdateInfo {
	
	public var insertedIndexPaths: Set<NSIndexPath> = []
	public var removedIndexPaths: Set<NSIndexPath> = []
	public var reloadedIndexPaths: Set<NSIndexPath> = []
	public var insertedSections: Set<Int> = []
	public var removedSections: Set<Int> = []
	public var reloadedSections: Set<Int> = []
	/// Additional index paths for element kinds to delete during updates.
	public var additionalDeletedIndexPaths: [String: [NSIndexPath]] = [:]
	/// Additional index paths for element kinds to insert during updates.
	public var additionalInsertedIndexPaths: [String: [NSIndexPath]] = [:]
	
	public mutating func processCollectionViewUpdates(updateItems: [UICollectionViewUpdateItem]) {
		for updateItem in updateItems {
			processCollectionViewUpdate(updateItem)
		}
	}
	private mutating func processCollectionViewUpdate(updateItem: UICollectionViewUpdateItem) {
		switch updateItem.updateAction {
		case .Insert:
			processCollectionViewInsert(updateItem)
		case .Delete:
			processCollectionViewDelete(updateItem)
		case .Reload:
			processCollectionViewReload(updateItem)
		case .Move:
			processCollectionViewMove(updateItem)
		case .None:
			break
		}
	}
	mutating func processCollectionViewInsert(updateItem: UICollectionViewUpdateItem) {
		guard let indexPath = updateItem.indexPathAfterUpdate else {
			return
		}
		if indexPath.isSection {
			insertedSections.insert(indexPath.section)
		} else {
			insertedIndexPaths.insert(indexPath)
		}
	}
	mutating func processCollectionViewDelete(updateItem: UICollectionViewUpdateItem) {
		guard let indexPath = updateItem.indexPathBeforeUpdate else {
			return
		}
		if indexPath.isSection {
			removedSections.insert(indexPath.section)
		} else {
			removedIndexPaths.insert(indexPath)
		}
	}
	mutating func processCollectionViewReload(updateItem: UICollectionViewUpdateItem) {
		guard let indexPath = updateItem.indexPathAfterUpdate else {
			return
		}
		if indexPath.isSection {
			reloadedSections.insert(indexPath.section)
		} else {
			reloadedIndexPaths.insert(indexPath)
		}
	}
	mutating func processCollectionViewMove(updateItem: UICollectionViewUpdateItem) {
		guard let oldIndexPath = updateItem.indexPathBeforeUpdate,
			newIndexPath = updateItem.indexPathAfterUpdate else {
				return
		}
		if oldIndexPath.isSection {
			removedSections.insert(oldIndexPath.section)
			insertedSections.insert(newIndexPath.section)
		}
	}
	
	public mutating func resetUpdates() {
		resetUpdatedIndexPaths()
		resetUpdatedSections()
		resetAdditionalUpdatedIndexPaths()
	}
	private mutating  func resetUpdatedIndexPaths() {
		insertedIndexPaths = []
		removedIndexPaths = []
		reloadedIndexPaths = []
	}
	private mutating func resetUpdatedSections() {
		insertedSections = []
		removedSections = []
		reloadedSections = []
	}
	private mutating func resetAdditionalUpdatedIndexPaths() {
		additionalDeletedIndexPaths = [:]
		additionalInsertedIndexPaths = [:]
	}
	
}
