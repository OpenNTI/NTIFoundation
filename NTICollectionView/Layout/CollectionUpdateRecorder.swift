//
//  CollectionUpdateRecorder.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 4/12/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

/// Records index path and section information from `UICollectionViewUpdateItem` updates in a form that is more convenient for clients.
public struct CollectionUpdateRecorder: CollectionUpdateInfoWrapper {
	
	public var updateInfo = CollectionUpdateInfo()
	
	fileprivate weak var sectionProvider: LayoutSectionProvider?
	fileprivate weak var oldSectionProvider: LayoutSectionProvider?
	
	public mutating func record(_ updates: [UICollectionViewUpdateItem], sectionProvider: LayoutSectionProvider?, oldSectionProvider: LayoutSectionProvider?) {
		self.sectionProvider = sectionProvider
		self.oldSectionProvider = oldSectionProvider
		
		for update in updates {
			record(update)
		}
		
		self.sectionProvider = nil
		self.oldSectionProvider = nil
	}
	
	fileprivate mutating func record(_ update: UICollectionViewUpdateItem) {
		switch update.updateAction {
		case .insert:
			recordInsert(update)
		case .delete:
			recordDelete(update)
		case .reload:
			recordReload(update)
		case .move:
			recordMove(update)
		case .none:
			break
		}
	}
	
	fileprivate mutating func recordInsert(_ update: UICollectionViewUpdateItem) {
		guard let indexPath = update.indexPathAfterUpdate else {
			return
		}
		
		if indexPath.isSection {
			insertedSections.insert(indexPath.section)
		} else {
			insertedIndexPaths.insert(indexPath)
			recordAdditionalInsertedAttributesForItemInsertion(at: indexPath)
		}
	}
	
	fileprivate mutating func recordDelete(_ update: UICollectionViewUpdateItem) {
		guard let indexPath = update.indexPathBeforeUpdate else {
			return
		}
		
		if indexPath.isSection {
			removedSections.insert(indexPath.section)
		} else {
			removedIndexPaths.insert(indexPath)
			recordAdditionalDeletedAttributesForItemDeletion(at: indexPath)
		}
	}
	
	fileprivate mutating func recordReload(_ update: UICollectionViewUpdateItem) {
		guard let indexPath = update.indexPathAfterUpdate else {
			return
		}
		
		if indexPath.isSection {
			reloadedSections.insert(indexPath.section)
		} else {
			reloadedIndexPaths.insert(indexPath)
		}
	}
	
	fileprivate mutating func recordMove(_ update: UICollectionViewUpdateItem) {
		guard let oldIndexPath = update.indexPathBeforeUpdate,
			let newIndexPath = update.indexPathAfterUpdate else {
				return
		}
		
		if oldIndexPath.isSection {
			removedSections.insert(oldIndexPath.section)
			insertedSections.insert(newIndexPath.section)
		} else {
			recordAdditionalDeletedAttributesForItemDeletion(at: oldIndexPath)
			recordAdditionalInsertedAttributesForItemInsertion(at: newIndexPath)
		}
	}
	
	public mutating func recordAdditionalInsertedAttributesForItemInsertion(at indexPath: IndexPath) {
		guard let sectionInfo = sectionProvider?.sectionAtIndex(indexPath.section) else {
			return
		}
		
		let additionalInsertions = sectionInfo.additionalLayoutAttributesToInsertForInsertionOfItem(at: indexPath)
		for attributes in additionalInsertions {
			guard let kind = attributes.representedElementKind else {
				continue
			}
			recordAdditionalInsertedIndexPath(attributes.indexPath, forElementOf: kind)
		}
	}
	
	public mutating func recordAdditionalInsertedIndexPath(_ indexPath: IndexPath, forElementOf kind: String) {
		additionalInsertedIndexPathsByKind.append(indexPath, to: kind)
	}
	
	public mutating func recordAdditionalInsertedIndexPaths(_ indexPaths: [IndexPath], forElementOf kind: String) {
		for indexPath in indexPaths {
			recordAdditionalInsertedIndexPath(indexPath, forElementOf: kind)
		}
	}
	
	public mutating func recordAdditionalDeletedAttributesForItemDeletion(at indexPath: IndexPath) {
		guard let sectionInfo = oldSectionProvider?.sectionAtIndex(indexPath.section) else {
			return
		}
		
		let additionalDeletions = sectionInfo.additionalLayoutAttributesToDeleteForDeletionOfItem(at: indexPath)
		for attributes in additionalDeletions {
			guard let kind = attributes.representedElementKind else {
				continue
			}
			recordAdditionalDeletedIndexPath(attributes.indexPath, forElementOf: kind)
		}
	}
	
	public mutating func recordAdditionalDeletedIndexPaths(_ indexPaths: [IndexPath], forElementOf kind: String) {
		for indexPath in indexPaths {
			recordAdditionalDeletedIndexPath(indexPath, forElementOf: kind)
		}
	}
	
	public mutating func recordAdditionalDeletedIndexPath(_ indexPath: IndexPath, forElementOf kind: String) {
		additionalDeletedIndexPathsByKind.append(indexPath, to: kind)
	}
	
}
