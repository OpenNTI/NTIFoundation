//
//  CollectionDataSourceController.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 3/7/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import Foundation

/// A type which manages a `CollectionDataSource` instance.
public protocol CollectionDataSourceController: class {
	
	/// The `CollectionDataSource` instance managed by `self`.
	var dataSource: CollectionDataSource { get }
	
	func loadContent(with progress: LoadingProgress)
	
}

extension CollectionDataSourceController {
	
	public func loadContent(with progress: LoadingProgress) {
		progress.done()
	}
	
}
