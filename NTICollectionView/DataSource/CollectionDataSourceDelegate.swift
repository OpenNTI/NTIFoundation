//
//  CollectionDataSourceDelegate.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/19/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public enum SectionOperationDirection: String {
	case Left, Right
}

public protocol CollectionDataSourceDelegate: NSObjectProtocol {
	
	func dataSource(dataSource: CollectionDataSource, didInsertItemsAt indexPaths: [NSIndexPath])
	func dataSource(dataSource: CollectionDataSource, didRemoveItemsAt indexPaths: [NSIndexPath])
	func dataSource(dataSource: CollectionDataSource, didRefreshItemsAt indexPaths: [NSIndexPath])
	func dataSource(dataSource: CollectionDataSource, didMoveItemAt oldIndexPath: NSIndexPath, to newIndexPath: NSIndexPath)
	
	func dataSource(dataSource: CollectionDataSource, didInsertSections sections: NSIndexSet, direction: SectionOperationDirection?)
	func dataSource(dataSource: CollectionDataSource, didRemoveSections sections: NSIndexSet, direction: SectionOperationDirection?)
	func dataSource(dataSource: CollectionDataSource, didMoveSectionFrom oldSection: Int, to newSection: Int, direction: SectionOperationDirection?)
	func dataSource(dataSource: CollectionDataSource, didRefreshSections sections: NSIndexSet)
	
	func dataSourceDidReloadData(dataSource: CollectionDataSource)
	func dataSource(dataSource: CollectionDataSource, performBatchUpdate update: () -> Void, complete: (() -> Void)?)
	
	/// If the content was loaded successfully, the error will be nil.
	func dataSourceDidLoadContent(dataSource: CollectionDataSource, error: NSError?)
	
	/// Called just before a datasource begins loading its content.
	func dataSourceWillLoadContent(dataSource: CollectionDataSource)
	
	/// Present an activity indicator. The sections must be contiguous.
	func dataSource(dataSource: CollectionDataSource, didPresentActivityIndicatorForSections sections: NSIndexSet)
	
	/// Present a placeholder for a set of sections. The sections must be contiguous.
	func dataSource(dataSource: CollectionDataSource, didPresentPlaceholderForSections sections: NSIndexSet)
	
	/// Remove a placeholder for a set of sections.
	func dataSource(dataSource: CollectionDataSource, didDismissPlaceholderForSections sections: NSIndexSet)
	
	/// Update the view or views associated with supplementary item at given index paths.
	func dataSource(dataSource: CollectionDataSource, didUpdate supplementaryItem: SupplementaryItem, at indexPaths: [NSIndexPath])
	
	func dataSource(dataSource: CollectionDataSource, didAddChild childDataSource: CollectionDataSource)
	
}

extension CollectionDataSourceDelegate {
	
	public func dataSource(dataSource: CollectionDataSource, didInsertItemsAt indexPaths: [NSIndexPath]) {}
	public func dataSource(dataSource: CollectionDataSource, didRemoveItemsAt indexPaths: [NSIndexPath]) {}
	public func dataSource(dataSource: CollectionDataSource, didRefreshItemsAt indexPaths: [NSIndexPath]) {}
	public func dataSource(dataSource: CollectionDataSource, didMoveItemAt oldIndexPath: NSIndexPath, to newIndexPath: NSIndexPath) {}
	
	public func dataSource(dataSource: CollectionDataSource, didInsertSections sections: NSIndexSet, direction: SectionOperationDirection? = nil) {}
	public func dataSource(dataSource: CollectionDataSource, didRemoveSections sections: NSIndexSet, direction: SectionOperationDirection? = nil) {}
	public func dataSource(dataSource: CollectionDataSource, didMoveSectionFrom oldSection: Int, to newSection: Int, direction: SectionOperationDirection? = nil) {}
	public func dataSource(dataSource: CollectionDataSource, didRefreshSections sections: NSIndexSet) {}
	
	public func dataSourceDidReloadData(dataSource: CollectionDataSource) {}
	public func dataSource(dataSource: CollectionDataSource, performBatchUpdate update: () -> Void, complete: (() -> Void)?) {}
	
	public func dataSourceDidLoadContent(dataSource: CollectionDataSource, error: NSError? = nil) {}
	
	public func dataSourceWillLoadContent(dataSource: CollectionDataSource) {}
	
	public func dataSource(dataSource: CollectionDataSource, didPresentActivityIndicatorForSections sections: NSIndexSet) {}
	
	public func dataSource(dataSource: CollectionDataSource, didPresentPlaceholderForSections sections: NSIndexSet) {}
	
	public func dataSource(dataSource: CollectionDataSource, didDismissPlaceholderForSections sections: NSIndexSet) {}
	
	public func dataSource(dataSource: CollectionDataSource, didUpdate supplementaryItem: SupplementaryItem, at indexPaths: [NSIndexPath]) {}
	
	public func dataSource(dataSource: CollectionDataSource, didAddChild childDataSource: CollectionDataSource) { }
	
}
