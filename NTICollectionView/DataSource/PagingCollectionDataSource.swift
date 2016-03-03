//
//  PagingCollectionDataSource.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 3/3/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public protocol PagingCollectionDataSourceProtocol: CollectionDataSource, PageableContentLoading {
	
	func loadNextContent()
	
	func loadPreviousContent()
	
}

public class PagingCollectionDataSource: BasicCollectionDataSource, PagingCollectionDataSourceProtocol {

	
	// MARK: - PagingCollectionDataSourceProtocol
	
	public func loadNextContent() {
		
	}
	
	public func loadPreviousContent() {
		
	}
	
	// MARK: - PageableContentLoading
	
	public func loadNextContent(with progress: LoadingProgress) {
		
	}
	
	public func loadPreviousContent(with progress: LoadingProgress) {
		
	}
	
}
