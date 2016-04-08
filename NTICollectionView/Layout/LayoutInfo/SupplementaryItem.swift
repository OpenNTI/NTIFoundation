//
//  SupplementaryItem.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/11/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

/// The element kind for placeholders.
public let CollectionElementKindPlaceholder = "CollectionElementKindPlaceholder"

public let GlobalSectionIndex = Int.max

public let AutomaticLength: CGFloat = -1

public typealias SupplementaryItemConfiguration = (view: UICollectionReusableView, dataSource: CollectionDataSource, indexPath: NSIndexPath) -> Void

/// Definition of how supplementary views should be created and presented in a collection view.
public protocol SupplementaryItem: class {
	
	/// Should this supplementary view be displayed while the placeholder is visible?
	var isVisibleWhileShowingPlaceholder: Bool { get set }
	
	/// Should this supplementary view be pinned to the top of the view when scrolling?
	var shouldPin: Bool { get set }
	
	/// The width of the supplementary view. Setting this property to `nil` will cause the supplementary view to be automatically sized.
	var width: CGFloat? { get set }
	
	/// The height of the supplementary view. Setting this property to `nil` will cause the supplementary view to be automatically sized.
	var height: CGFloat? { get set }
	
	/// The estimated width of the supplementary view. To prevent layout glitches, this value should be set to the best estimation of the width of the supplementary view.
	var estimatedWidth: CGFloat { get set }
	
	/// The estimated height of the supplementary view. To prevent layout glitches, this value should be set to the best estimation of the height of the supplementary view.
	var estimatedHeight: CGFloat { get set }
	
	/// Should the supplementary view be hidden?
	var isHidden: Bool { get set }
	
	/// The class to use when dequeuing an instance of this supplementary view.
	var supplementaryViewClass: UICollectionReusableView.Type! { get set }
	
	/// The represented element kind of this supplementary view.
	var elementKind: String { get }
	
	/// Optional reuse identifier. If not specified, this will be inferred from the class of the supplementary view.
	var reuseIdentifier: String { get set }
	
	/// A block that can be used to configure the supplementary view after it is created.
	var configureView: SupplementaryItemConfiguration? { get }
	
	var fixedHeight: CGFloat { get }
	
	var hasEstimatedHeight: Bool { get }
	
	/// Adds a configuration block to the supplementary view. This does not clear existing configuration blocks.
	func configure(with configuration: SupplementaryItemConfiguration)
	
	/// Update these metrics with the values from another metrics.
	func applyValues(from metrics: SupplementaryItem)
	
	func definesMetric(metric: String) -> Bool
	
}

extension SupplementaryItem {
	
	public var isHeader: Bool {
		return elementKind == UICollectionElementKindSectionHeader
	}
	
	public var registration: SupplementaryViewRegistration {
		return (viewClass: supplementaryViewClass, elementKind: elementKind, identifier: reuseIdentifier)
	}
	
}
