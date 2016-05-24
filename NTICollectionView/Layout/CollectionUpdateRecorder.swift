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
	
	private weak var sectionProvider: LayoutSectionProvider?
	private weak var oldSectionProvider: LayoutSectionProvider?
	
	public mutating func record(updates: [UICollectionViewUpdateItem], sectionProvider: LayoutSectionProvider?, oldSectionProvider: LayoutSectionProvider?) {
		self.sectionProvider = sectionProvider
		self.oldSectionProvider = oldSectionProvider
		
		for update in updates {
			record(update)
		}
		
		self.sectionProvider = nil
		self.oldSectionProvider = nil
	}
	
	private mutating func record(update: UICollectionViewUpdateItem) {
		switch update.updateAction {
		case .Insert:
			recordInsert(update)
		case .Delete:
			recordDelete(update)
		case .Reload:
			recordReload(update)
		case .Move:
			recordMove(update)
		case .None:
			break
		}
	}
	
	private mutating func recordInsert(update: UICollectionViewUpdateItem) {
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
	
	private mutating func recordDelete(update: UICollectionViewUpdateItem) {
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
	
	private mutating func recordReload(update: UICollectionViewUpdateItem) {
		guard let indexPath = update.indexPathAfterUpdate else {
			return
		}
		
		if indexPath.isSection {
			reloadedSections.insert(indexPath.section)
		} else {
			reloadedIndexPaths.insert(indexPath)
		}
	}
	
	private mutating func recordMove(update: UICollectionViewUpdateItem) {
		guard let oldIndexPath = update.indexPathBeforeUpdate,
			newIndexPath = update.indexPathAfterUpdate else {
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
	
	public mutating func recordAdditionalInsertedAttributesForItemInsertion(at indexPath: NSIndexPath) {
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
	
	public mutating func recordAdditionalInsertedIndexPath(indexPath: NSIndexPath, forElementOf kind: String) {
		additionalInsertedIndexPathsByKind.append(indexPath, to: kind)
	}
	
	public mutating func recordAdditionalInsertedIndexPaths(indexPaths: [NSIndexPath], forElementOf kind: String) {
		for indexPath in indexPaths {
			recordAdditionalInsertedIndexPath(indexPath, forElementOf: kind)
		}
	}
	
	public mutating func recordAdditionalDeletedAttributesForItemDeletion(at indexPath: NSIndexPath) {
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
	
	public mutating func recordAdditionalDeletedIndexPaths(indexPaths: [NSIndexPath], forElementOf kind: String) {
		for indexPath in indexPaths {
			recordAdditionalDeletedIndexPath(indexPath, forElementOf: kind)
		}
	}
	
	public mutating func recordAdditionalDeletedIndexPath(indexPath: NSIndexPath, forElementOf kind: String) {
		additionalDeletedIndexPathsByKind.append(indexPath, to: kind)
	}
	
}
