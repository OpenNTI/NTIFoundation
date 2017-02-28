//
//  BasicSupplementaryItem.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 4/13/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

private let defaultEstimatedHeight: CGFloat = 44

public struct BasicSupplementaryItem: SupplementaryItem {
	
	public init(elementKind: String) {
		self.elementKind = elementKind
	}
	
	public var isVisibleWhileShowingPlaceholder: Bool = false
	
	public var shouldPin: Bool = false
	
	public var width: CGFloat?
	
	public var height: CGFloat?
	
	public var estimatedWidth: CGFloat = defaultEstimatedHeight
	
	public var estimatedHeight: CGFloat = defaultEstimatedHeight
	
	public var zIndex: Int = headerZIndex
	
	public var cornerRadius: CGFloat = 0
	
	public var isHidden: Bool = false
	
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
	fileprivate var _reuseIdentifier: String?
	
	public var configureView: SupplementaryItemConfiguration?
	
	public var fixedHeight: CGFloat {
		return height ?? estimatedHeight
	}
	
	public var hasEstimatedHeight: Bool {
		return height == nil
	}
	
	public func applyValues(from metrics: LayoutMetrics) {
		
	}
	
	public func configureValues(of attributes: CollectionViewLayoutAttributes) {
		attributes.zIndex = zIndex
		attributes.cornerRadius = cornerRadius
		attributes.isHidden = false
		attributes.shouldCalculateFittingSize = hasEstimatedHeight
	}
	
	public mutating func configure(with configuration: @escaping SupplementaryItemConfiguration) {
		guard let configureView = self.configureView else {
			self.configureView = configuration
			return
		}
		
		self.configureView = { (view: UICollectionReusableView, dataSource: CollectionDataSource, indexPath: IndexPath) in
			configureView(view, dataSource, indexPath)
			configuration(view, dataSource, indexPath)
		}
	}
	
	public mutating func setFrame(_ frame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		
	}
	
	public mutating func resetLayoutAttributes() {
		
	}
	
	public func isEqual(to other: SupplementaryItem) -> Bool {
		guard let other = other as? BasicSupplementaryItem else {
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
	
}
