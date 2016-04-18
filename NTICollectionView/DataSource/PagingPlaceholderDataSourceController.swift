//
//  PagingPlaceholderDataSourceController.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 3/24/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

private let nextPagePlaceholderKey = "nextPagePlaceholder"
private let prevPagePlaceholderKey = "prevPagePlaceholder"

private let placeholderHeight: CGFloat = 100

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
			hasNextPage ? showNextPagePlaceholder() : hideNextPagePlaceholder()
		}
	}
	
	private func showNextPagePlaceholder() {
		nextPagePlaceholder.height = placeholderHeight
		nextPagePlaceholder.isHidden = false
		replaceNextPagePlaceholder()
	}
	
	private func hideNextPagePlaceholder() {
		nextPagePlaceholder.height = 0
		nextPagePlaceholder.isHidden = true
		replaceNextPagePlaceholder()
	}
	
	private func replaceNextPagePlaceholder() {
		dataSource.replaceSupplementaryItemForKey(nextPagePlaceholderKey, with: nextPagePlaceholder)
	}
	
	public var hasPrevPage = false {
		didSet {
			guard hasPrevPage != oldValue else {
				return
			}
			hasPrevPage ? showPrevPagePlaceholder() : hidePrevPagePlaceholder()
		}
	}
	
	private func showPrevPagePlaceholder() {
		prevPagePlaceholder.height = placeholderHeight
		prevPagePlaceholder.isHidden = false
		replacePrevPagePlaceholder()
	}
	
	private func hidePrevPagePlaceholder() {
		prevPagePlaceholder.height = 0
		prevPagePlaceholder.isHidden = true
		replacePrevPagePlaceholder()
	}
	
	private func replacePrevPagePlaceholder() {
		dataSource.replaceSupplementaryItemForKey(prevPagePlaceholderKey, with: prevPagePlaceholder)
	}
	
	public private(set) var nextPagePlaceholder = GridSupplementaryItem(elementKind: UICollectionElementKindSectionFooter)
	
	public private(set) var prevPagePlaceholder = GridSupplementaryItem(elementKind: UICollectionElementKindSectionHeader)
	
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
		configurePagingPlaceholder(&nextPagePlaceholder)
		nextPagePlaceholder.reuseIdentifier = nextPagePlaceholderKey
		nextPagePlaceholder.configure { [weak self] (view, dataSource, indexPath) in
			guard let `self` = self else {
				return
			}
			guard let placeholderView = view as? CollectionPlaceholderView else {
				return
			}
			placeholderView.isSectionPlaceholder = false
			placeholderView.onWillDisplay = { [unowned placeholderView, unowned self] in
				placeholderView.showActivityIndicator(true)
				self.dataSource.setNeedsLoadNextContent(self.pageLoadDelay)
			}
			placeholderView.onWillEndDisplaying = { [unowned placeholderView, unowned self] in
				self.dataSource.cancelNeedsLoadNextContent()
				placeholderView.showActivityIndicator(false)
			}
		}
		dataSource.add(nextPagePlaceholder, forKey: nextPagePlaceholderKey)
	}
	
	private func configurePrevPagePlaceholder() {
		configurePagingPlaceholder(&prevPagePlaceholder)
		prevPagePlaceholder.reuseIdentifier = prevPagePlaceholderKey
		prevPagePlaceholder.configure { [weak self] (view, dataSource, indexPath) in
			guard let `self` = self else {
				return
			}
			guard let placeholderView = view as? CollectionPlaceholderView else {
				return
			}
			placeholderView.isSectionPlaceholder = false
			placeholderView.onWillDisplay = { [unowned placeholderView, unowned self] in
				placeholderView.showActivityIndicator(true)
				self.dataSource.setNeedsLoadPreviousContent(self.pageLoadDelay)
			}
			placeholderView.onWillEndDisplaying = { [unowned placeholderView, unowned self] in
				self.dataSource.cancelNeedsLoadPreviousContent()
				placeholderView.showActivityIndicator(false)
			}
		}
		dataSource.add(prevPagePlaceholder, forKey: prevPagePlaceholderKey)
	}
	
	private func configurePagingPlaceholder(inout pagingPlaceholder: GridSupplementaryItem) {
		pagingPlaceholder.backgroundColor = nil
		pagingPlaceholder.height = 0
		pagingPlaceholder.isHidden = true
		pagingPlaceholder.supplementaryViewClass = CollectionPlaceholderView.self
	}
	
}
