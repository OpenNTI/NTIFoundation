//
//  BasicSupplementaryItem.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 4/13/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

private let DefaultEstimatedHeight: CGFloat = 44

public struct BasicSupplementaryItem: SupplementaryItem {
	
	public init(elementKind: String) {
		self.elementKind = elementKind
	}
	
	public var isVisibleWhileShowingPlaceholder: Bool = false {
		didSet { setFlag("isVisibleWhileShowingPlaceholder") }
	}
	
	public var shouldPin: Bool = false {
		didSet { setFlag("shouldPin") }
	}
	
	public var width: CGFloat?
	
	public var height: CGFloat? {
		didSet { setFlag("height") }
	}
	
	public var estimatedWidth: CGFloat = DefaultEstimatedHeight
	
	public var estimatedHeight: CGFloat = DefaultEstimatedHeight {
		didSet { setFlag("estimatedHeight") }
	}
	
	public var zIndex: Int = headerZIndex {
		didSet { setFlag("zIndex") }
	}
	
	public var isHidden: Bool = false {
		didSet { setFlag("isHidden") }
	}
	
	public var supplementaryViewClass: UICollectionReusableView.Type!
	
	public var elementKind: String
	
	public var reuseIdentifier: String {
		get {
			return _reuseIdentifier ?? NSStringFromClass(supplementaryViewClass)
		}
		set {
			_reuseIdentifier = newValue
		}
	}
	private var _reuseIdentifier: String?
	
	public var configureView: SupplementaryItemConfiguration?
	
	public var fixedHeight: CGFloat {
		return height ?? estimatedHeight
	}
	
	public var hasEstimatedHeight: Bool {
		return height == nil
	}
	
	public var frame = CGRectZero
	
	public var section: LayoutSection?
	
	public var itemIndex = NSNotFound
	
	public var indexPath: NSIndexPath {
		guard let sectionInfo = section else {
			return NSIndexPath()
		}
		if sectionInfo.isGlobalSection {
			return NSIndexPath(index: itemIndex)
		} else {
			return NSIndexPath(forItem: itemIndex, inSection: sectionInfo.sectionIndex)
		}
	}
	
	public var layoutAttributes: UICollectionViewLayoutAttributes {
		let attributes = CollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind, withIndexPath: indexPath)
		let section = self.section as? GridLayoutSection
		let metrics = section?.metrics
		let layoutInfo = section?.layoutInfo
		
		attributes.frame = frame
		attributes.unpinnedOrigin = frame.origin
		attributes.zIndex = zIndex
		attributes.isPinned = false
		attributes.isEditing = layoutInfo?.isEditing ?? false
		attributes.hidden = false
		attributes.shouldCalculateFittingSize = hasEstimatedHeight
		attributes.cornerRadius = metrics?.cornerRadius ?? 0
		
		return attributes
	}
	
	public mutating func configure(with configuration: SupplementaryItemConfiguration) {
		guard let configureView = self.configureView else {
			self.configureView = configuration
			return
		}
		
		self.configureView = { (view: UICollectionReusableView, dataSource: CollectionDataSource, indexPath: NSIndexPath) in
			configureView(view: view, dataSource: dataSource, indexPath: indexPath)
			configuration(view: view, dataSource: dataSource, indexPath: indexPath)
		}
	}
	
	public mutating func applyValues(from metrics: SupplementaryItem) {
		guard let metrics = metrics as? GridSupplementaryItem else {
			return
		}
		
		if metrics.definesMetric("height") {
			height = metrics.height
		}
		if metrics.definesMetric("estimatedHeight") {
			estimatedHeight = metrics.estimatedHeight
		}
		if metrics.definesMetric("zIndex") {
			zIndex = metrics.zIndex
		}
		if metrics.definesMetric("isHidden") {
			isHidden = metrics.isHidden
		}
		if metrics.definesMetric("shouldPin") {
			shouldPin = metrics.shouldPin
		}
		if metrics.definesMetric("isVisibleWhileShowingPlaceholder") {
			isVisibleWhileShowingPlaceholder = metrics.isVisibleWhileShowingPlaceholder
		}
		
		supplementaryViewClass = metrics.supplementaryViewClass
		configureView = metrics.configureView
		reuseIdentifier = metrics.reuseIdentifier
	}
	
	public func definesMetric(metric: String) -> Bool {
		return flags.contains(metric)
	}
	
	public mutating func setFrame(frame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		
	}
	
	public mutating func resetLayoutAttributes() {
		
	}
	
	public func isEqual(to other: SupplementaryItem) -> Bool {
		guard let other = other as? BasicGridSupplementaryItem else {
			return false
		}
		
		return elementKind == other.elementKind
			&& reuseIdentifier == other.reuseIdentifier
			&& supplementaryViewClass == other.supplementaryViewClass
			
			&& isVisibleWhileShowingPlaceholder == other.isVisibleWhileShowingPlaceholder
			&& shouldPin == other.shouldPin
			&& width == other.width
			&& height == other.height
			&& estimatedWidth == other.estimatedWidth
			&& estimatedHeight == other.estimatedHeight
			&& isHidden == other.isHidden
	}
	
	private var flags: Set<String> = []
	
	private mutating func setFlag(flag: String) {
		flags.insert(flag)
	}
	
}
