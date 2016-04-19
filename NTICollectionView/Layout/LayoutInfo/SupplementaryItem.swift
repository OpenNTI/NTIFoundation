//
//  SupplementaryItem.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/11/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

/// The element kind for placeholders.
public let collectionElementKindPlaceholder = "collectionElementKindPlaceholder"

public let globalSectionIndex = Int.max

public let automaticLength: CGFloat = -1

public typealias SupplementaryItemConfiguration = (view: UICollectionReusableView, dataSource: CollectionDataSource, indexPath: NSIndexPath) -> Void

/// Definition of how supplementary views should be created and presented in a collection view.
public protocol SupplementaryItem: LayoutMetricsApplicable {
	
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
	
	var zIndex: Int { get set }
	
	var cornerRadius: CGFloat { get set }
	
	/// Should the supplementary view be hidden?
	var isHidden: Bool { get set }
	
	/// The class to use when dequeuing an instance of this supplementary view.
	var supplementaryViewClass: UICollectionReusableView.Type! { get set }
	
	/// The represented element kind of this supplementary view.
	var elementKind: String { get }
	
	/// Optional reuse identifier. If not specified, this will be inferred from the class of the supplementary view.
	var reuseIdentifier: String { get set }
	
	/// A block that can be used to configure the supplementary view after it is created.
	var configureView: SupplementaryItemConfiguration? { get set }
	
	var fixedHeight: CGFloat { get }
	
	var hasEstimatedHeight: Bool { get }
	
	/// Adds a configuration block to the supplementary view. This does not clear existing configuration blocks.
	mutating func configure(with configuration: SupplementaryItemConfiguration)
	
	func configureValues(of attributes: CollectionViewLayoutAttributes)
	
	func isEqual(to other: SupplementaryItem) -> Bool
	
}

extension SupplementaryItem {
	
	public var isHeader: Bool {
		return elementKind == UICollectionElementKindSectionHeader
	}
	
	public var registration: SupplementaryViewRegistration {
		return (viewClass: supplementaryViewClass, elementKind: elementKind, identifier: reuseIdentifier)
	}
	
}

public protocol SupplementaryItemWrapper: SupplementaryItem {
	
	var supplementaryItem: SupplementaryItem { get set }
	
}

extension SupplementaryItemWrapper {
	
	public var isVisibleWhileShowingPlaceholder: Bool {
		get {
			return supplementaryItem.isVisibleWhileShowingPlaceholder
		}
		set {
			supplementaryItem.isVisibleWhileShowingPlaceholder = newValue
		}
	}
	
	public var shouldPin: Bool {
		get {
			return supplementaryItem.shouldPin
		}
		set {
			supplementaryItem.shouldPin = newValue
		}
	}
	
	public var width: CGFloat? {
		get {
			return supplementaryItem.width
		}
		set {
			supplementaryItem.width = newValue
		}
	}
	
	public var height: CGFloat? {
		get {
			return supplementaryItem.height
		}
		set {
			supplementaryItem.height = newValue
		}
	}
	
	public var estimatedWidth: CGFloat {
		get {
			return supplementaryItem.estimatedWidth
		}
		set {
			supplementaryItem.estimatedWidth = newValue
		}
	}
	
	public var estimatedHeight: CGFloat {
		get {
			return supplementaryItem.estimatedHeight
		}
		set {
			supplementaryItem.estimatedHeight = newValue
		}
	}
	
	public var zIndex: Int {
		get {
			return supplementaryItem.zIndex
		}
		set {
			supplementaryItem.zIndex = newValue
		}
	}
	
	public var cornerRadius: CGFloat {
		get {
			return supplementaryItem.cornerRadius
		}
		set {
			supplementaryItem.cornerRadius = newValue
		}
	}
	
	public var isHidden: Bool {
		get {
			return supplementaryItem.isHidden
		}
		set {
			supplementaryItem.isHidden = newValue
		}
	}
	
	public var supplementaryViewClass: UICollectionReusableView.Type! {
		get {
			return supplementaryItem.supplementaryViewClass
		}
		set {
			supplementaryItem.supplementaryViewClass = newValue
		}
	}
	
	public var elementKind: String {
		return supplementaryItem.elementKind
	}
	
	public var reuseIdentifier: String {
		get {
			return supplementaryItem.reuseIdentifier
		}
		set {
			supplementaryItem.reuseIdentifier = newValue
		}
	}
	
	public var configureView: SupplementaryItemConfiguration? {
		get {
			return supplementaryItem.configureView
		}
		set {
			supplementaryItem.configureView = newValue
		}
	}
	
	public var fixedHeight: CGFloat {
		return supplementaryItem.fixedHeight
	}
	
	public var hasEstimatedHeight: Bool {
		return supplementaryItem.hasEstimatedHeight
	}
	
	public mutating func configure(with configuration: SupplementaryItemConfiguration) {
		supplementaryItem.configure(with: configuration)
	}
	
}
