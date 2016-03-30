//
//  PagingPlaceholderDataSourceController.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 3/24/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import Foundation

private let nextPagePlaceholderKey = "nextPagePlaceholder"
private let prevPagePlaceholderKey = "prevPagePlaceholder"

public final class PagingPlaceholderDataSourceController: CollectionDataSourceController {
	
	public init(dataSource: CollectionDataSource) {
		self.dataSource = dataSource
		configureDataSource()
	}
	
	public let dataSource: CollectionDataSource
	
	public var hasNextPage = false {
		didSet {
			guard hasNextPage != oldValue else {
				return
			}
			if hasNextPage {
				dataSource.add(nextPagePlaceholder, forKey: nextPagePlaceholderKey)
			} else {
				dataSource.removeSupplementaryItemForKey(nextPagePlaceholderKey)
			}
		}
	}
	
	public var hasPrevPage = false {
		didSet {
			guard hasPrevPage != oldValue else {
				return
			}
			if hasPrevPage {
				dataSource.add(prevPagePlaceholder, forKey: prevPagePlaceholderKey)
			} else {
				dataSource.removeSupplementaryItemForKey(prevPagePlaceholderKey)
			}
		}
	}
	
	public let nextPagePlaceholder = BasicGridSupplementaryItem(elementKind: UICollectionElementKindSectionFooter)
	
	public let prevPagePlaceholder = BasicGridSupplementaryItem(elementKind: UICollectionElementKindSectionHeader)
	
	public var pageLoadDelay: NSTimeInterval = 0.5
	
	public var supplementaryViewRegistrations: [SupplementaryViewRegistration] {
		return [
			nextPagePlaceholder.registration,
			prevPagePlaceholder.registration
		]
	}
	
	private func configureDataSource() {
		configureNextPagePlaceholder()
		configurePrevPagePlaceholder()
	}
	
	private func configureNextPagePlaceholder() {
		configurePagingPlaceholder(nextPagePlaceholder)
		nextPagePlaceholder.reuseIdentifier = nextPagePlaceholderKey
		nextPagePlaceholder.configure { (view, dataSource, indexPath) in
			guard let placeholderView = view as? CollectionPlaceholderView else {
				return
			}
			placeholderView.onWillDisplay = { [unowned placeholderView, unowned self] in
				placeholderView.showActivityIndicator(true)
				self.dataSource.setNeedsLoadNextContent(self.pageLoadDelay)
			}
			placeholderView.onWillEndDisplaying = { [unowned placeholderView, unowned self] in
				self.dataSource.cancelNeedsLoadNextContent()
				placeholderView.showActivityIndicator(false)
			}
		}
	}
	
	private func configurePrevPagePlaceholder() {
		configurePagingPlaceholder(prevPagePlaceholder)
		prevPagePlaceholder.reuseIdentifier = prevPagePlaceholderKey
		prevPagePlaceholder.configure { (view, dataSource, indexPath) in
			guard let placeholderView = view as? CollectionPlaceholderView else {
				return
			}
			placeholderView.onWillDisplay = { [unowned placeholderView, unowned self] in
				placeholderView.showActivityIndicator(true)
				self.dataSource.setNeedsLoadPreviousContent(self.pageLoadDelay)
			}
			placeholderView.onWillEndDisplaying = { [unowned placeholderView, unowned self] in
				self.dataSource.cancelNeedsLoadPreviousContent()
				placeholderView.showActivityIndicator(false)
			}
		}
	}
	
	private func configurePagingPlaceholder(pagingPlaceholder: GridSupplementaryItem) {
		pagingPlaceholder.backgroundColor = nil
		pagingPlaceholder.height = 100
		pagingPlaceholder.supplementaryViewClass = CollectionPlaceholderView.self
	}
	
}
