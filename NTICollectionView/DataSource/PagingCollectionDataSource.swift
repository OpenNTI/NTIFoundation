//
//  PagingCollectionDataSource.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 3/3/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public protocol PagingCollectionDataSourceProtocol: CollectionDataSourceType, PageableContentLoading {
	
	var loadingDelegate: PageableContentLoading? { get set }
	
	func loadNextContent()
	
	func loadPreviousContent()
	
}

open class PagingCollectionDataSource<Item : AnyObject> : BasicCollectionDataSource<Item> {

	/// Optional delegate to provide custom loading logic without the need to override the `PageableContentLoading` methods in a subclass.
	open weak var loadingDelegate: PageableContentLoading?
	
	open override func beginLoadingContent(with progress: LoadingProgress) {
		if let loadingDelegate = self.loadingDelegate {
			return loadingDelegate.loadContent(with: progress)
		}
		super.beginLoadingContent(with: progress)
	}
	
	// MARK: - PagingCollectionDataSourceProtocol
	
	open override func loadNextContent() {
		guard canEnter(.LoadingNextContent) else {
			return
		}
		
		loadingState = .LoadingNextContent
		
		let loadingProgress = startNewLoadingProgress()
		
		beginLoadingNextContent(with: loadingProgress)
	}
	
	open override func beginLoadingNextContent(with progress: LoadingProgress) {
		if let loadingDelegate = self.loadingDelegate {
			return loadingDelegate.loadNextContent(with: progress)
		}
		loadNextContent(with: progress)
	}
	
	open override func loadPreviousContent() {
		guard canEnter(.LoadingPreviousContent) else {
			return
		}
		
		loadingState = .LoadingPreviousContent
		
		let loadingProgress = startNewLoadingProgress()
		
		beginLoadingPreviousContent(with: loadingProgress)
	}
	
	open override func beginLoadingPreviousContent(with progress: LoadingProgress) {
		if let loadingDelegate = self.loadingDelegate {
			return loadingDelegate.loadPreviousContent(with: progress)
		}
		loadPreviousContent(with: progress)
	}
	
	// MARK: - PageableContentLoading
	
	open override func loadNextContent(with progress: LoadingProgress) {
		// This is never called if a `loadingDelegate` is set
	}
	
	open override func loadPreviousContent(with progress: LoadingProgress) {
		// This is never called if a `loadingDelegate` is set
	}
	
}
