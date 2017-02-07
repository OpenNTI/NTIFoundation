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
	
	func dataSource(_ dataSource: CollectionDataSource, didInsertItemsAt indexPaths: [IndexPath])
	func dataSource(_ dataSource: CollectionDataSource, didRemoveItemsAt indexPaths: [IndexPath])
	func dataSource(_ dataSource: CollectionDataSource, didRefreshItemsAt indexPaths: [IndexPath])
	func dataSource(_ dataSource: CollectionDataSource, didMoveItemAt oldIndexPath: IndexPath, to newIndexPath: IndexPath)
	
	func dataSource(_ dataSource: CollectionDataSource, didInsertSections sections: IndexSet, direction: SectionOperationDirection?)
	func dataSource(_ dataSource: CollectionDataSource, didRemoveSections sections: IndexSet, direction: SectionOperationDirection?)
	func dataSource(_ dataSource: CollectionDataSource, didMoveSectionFrom oldSection: Int, to newSection: Int, direction: SectionOperationDirection?)
	func dataSource(_ dataSource: CollectionDataSource, didRefreshSections sections: IndexSet)
	
	func dataSourceDidReloadData(_ dataSource: CollectionDataSource)
	func dataSource(_ dataSource: CollectionDataSource, performBatchUpdate update: () -> Void, complete: (() -> Void)?)
	
	/// If the content was loaded successfully, the error will be nil.
	func dataSourceDidLoadContent(_ dataSource: CollectionDataSource, error: Error?)
	
	/// Called just before a datasource begins loading its content.
	func dataSourceWillLoadContent(_ dataSource: CollectionDataSource)
	
	/// Present an activity indicator. The sections must be contiguous.
	func dataSource(_ dataSource: CollectionDataSource, didPresentActivityIndicatorForSections sections: IndexSet)
	
	/// Present a placeholder for a set of sections. The sections must be contiguous.
	func dataSource(_ dataSource: CollectionDataSource, didPresentPlaceholderForSections sections: IndexSet)
	
	/// Remove a placeholder for a set of sections.
	func dataSource(_ dataSource: CollectionDataSource, didDismissPlaceholderForSections sections: IndexSet)
	
	/// Update the view or views associated with supplementary item at given index paths.
	func dataSource(_ dataSource: CollectionDataSource, didUpdate supplementaryItem: SupplementaryItem, at indexPaths: [IndexPath])
	
	func dataSource(_ dataSource: CollectionDataSource, didAddChild childDataSource: CollectionDataSource)
	
	func dataSource(_ dataSource: CollectionDataSource, perform update: (UICollectionView) -> Void)
	
}

extension CollectionDataSourceDelegate {
	
	public func dataSource(_ dataSource: CollectionDataSource, didInsertItemsAt indexPaths: [IndexPath]) {}
	public func dataSource(_ dataSource: CollectionDataSource, didRemoveItemsAt indexPaths: [IndexPath]) {}
	public func dataSource(_ dataSource: CollectionDataSource, didRefreshItemsAt indexPaths: [IndexPath]) {}
	public func dataSource(_ dataSource: CollectionDataSource, didMoveItemAt oldIndexPath: IndexPath, to newIndexPath: IndexPath) {}
	
	public func dataSource(_ dataSource: CollectionDataSource, didInsertSections sections: IndexSet, direction: SectionOperationDirection? = nil) {}
	public func dataSource(_ dataSource: CollectionDataSource, didRemoveSections sections: IndexSet, direction: SectionOperationDirection? = nil) {}
	public func dataSource(_ dataSource: CollectionDataSource, didMoveSectionFrom oldSection: Int, to newSection: Int, direction: SectionOperationDirection? = nil) {}
	public func dataSource(_ dataSource: CollectionDataSource, didRefreshSections sections: IndexSet) {}
	
	public func dataSourceDidReloadData(_ dataSource: CollectionDataSource) {}
	public func dataSource(_ dataSource: CollectionDataSource, performBatchUpdate update: () -> Void, complete: (() -> Void)?) {}
	
	public func dataSourceDidLoadContent(_ dataSource: CollectionDataSource, error: Error? = nil) {}
	
	public func dataSourceWillLoadContent(_ dataSource: CollectionDataSource) {}
	
	public func dataSource(_ dataSource: CollectionDataSource, didPresentActivityIndicatorForSections sections: IndexSet) {}
	
	public func dataSource(_ dataSource: CollectionDataSource, didPresentPlaceholderForSections sections: IndexSet) {}
	
	public func dataSource(_ dataSource: CollectionDataSource, didDismissPlaceholderForSections sections: IndexSet) {}
	
	public func dataSource(_ dataSource: CollectionDataSource, didUpdate supplementaryItem: SupplementaryItem, at indexPaths: [IndexPath]) {}
	
	public func dataSource(_ dataSource: CollectionDataSource, didAddChild childDataSource: CollectionDataSource) { }
	
	public func dataSource(_ dataSource: CollectionDataSource, perform update: (UICollectionView) -> Void) { }
	
}
