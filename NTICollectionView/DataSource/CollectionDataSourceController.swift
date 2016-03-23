//
//  CollectionDataSourceController.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 3/7/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public typealias SupplementaryViewRegistration = (viewClass: UICollectionReusableView.Type?, elementKind: String, identifier: String)

/// A type which manages a `CollectionDataSource` instance.
public protocol CollectionDataSourceController: class {
	
	/// The `CollectionDataSource` instance managed by `self`.
	var dataSource: CollectionDataSource { get }
	
	var supplementaryViewRegistrations: [SupplementaryViewRegistration] { get }
	
	/// `SupplementaryItem`s which may be contributed to the global section -- or, if `self` is the root controller, the supplementary items which have been contributed by child controllers.
	var contributionalGlobalSupplementaryItemsByKey: [String: SupplementaryItem] { get }
	
	func loadContent(with progress: LoadingProgress)
	
	func loadNextContent(with progress: LoadingProgress)
	
	func loadPreviousContent(with progress: LoadingProgress)
	
}

extension CollectionDataSourceController {
	
	public func loadContent(with progress: LoadingProgress) {
		progress.done()
	}
	
	public func loadNextContent(with progress: LoadingProgress) {
		progress.done()
	}
	
	public func loadPreviousContent(with progress: LoadingProgress) {
		progress.done()
	}
	
	public var contributionalGlobalSupplementaryItemsByKey: [String: SupplementaryItem] {
		return [:]
	}
	
}

public protocol ParentCollectionDataSourceController: CollectionDataSourceController {
	
	var childControllers: [CollectionDataSourceController] { get }
	
}

extension ParentCollectionDataSourceController {
	
	public var childControllers: [CollectionDataSourceController] {
		return []
	}
	
}
