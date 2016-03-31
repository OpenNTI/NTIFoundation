//
//  GridSupplementaryItem.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/19/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public protocol GridSupplementaryItem: LayoutSupplementaryItem {
	
	/// Use top & bottom layoutMargin to adjust spacing of header & footer elements. Not all headers & footers adhere to layoutMargins. Default is UIEdgeInsetsZero which is interpreted by supplementary items to be their default values.
	var layoutMargins: UIEdgeInsets { get set }
	
	/// The background color that should be used for this supplementary view. If not set, this will be inherited from the section.
	var backgroundColor: UIColor? { get set }
	
	/// The background color shown when this header is selected. If not set, this will be inherited from the section. This will only be used when simulatesSelection is YES.
	var selectedBackgroundColor: UIColor? { get set }
	
	/// The color to use for the background when the supplementary view has been pinned. If not set, this will be inherited from the section's backgroundColor value.
	var pinnedBackgroundColor: UIColor? { get set }
	
	/// Should the header/footer show a separator line? When shown, the separator will be shown using the separator color.
	var showsSeparator: Bool { get set }
	
	/// The color to use when showing the bottom separator line (if shown). If not set, this will be inherited from the section.
	var separatorColor: UIColor? { get set }
	
	/// The color to use when showing the bottom separator line if the supplementary view has been pinned. If not set, this will be inherited from the section's separatorColor value.
	var pinnedSeparatorColor: UIColor? { get set }
	
	/// Should this supplementary view simulate selection highlighting like cells?
	var simulatesSelection: Bool { get set }
	
}

private let DefaultEstimatedHeight: CGFloat = 44

public class BasicGridSupplementaryItem: NSObject, NSCopying, GridSupplementaryItem {
	
	public init(elementKind: String) {
		self.elementKind = elementKind
		super.init()
	}
	
	public var layoutMargins: UIEdgeInsets = UIEdgeInsetsZero {
		didSet {
			setFlag("layoutMargins")
		}
	}
	public var backgroundColor: UIColor? {
		didSet {
			setFlag("backgroundColor")
		}
	}
	public var selectedBackgroundColor: UIColor? {
		didSet {
			setFlag("selectedBackgroundColor")
		}
	}
	public var pinnedBackgroundColor: UIColor? {
		didSet {
			setFlag("pinnedBackgroundColor")
		}
	}
	public var separatorColor: UIColor? {
		didSet {
			setFlag("separatorColor")
		}
	}
	public var showsSeparator = false {
		didSet {
			setFlag("showsSeparator")
		}
	}
	public var pinnedSeparatorColor: UIColor? {
		didSet {
			setFlag("pinnedSeparatorColor")
		}
	}
	public var simulatesSelection: Bool = false {
		didSet {
			setFlag("simulatesSelection")
		}
	}
	
	public var section: LayoutSection?
	
	public var isVisibleWhileShowingPlaceholder: Bool = false {
		didSet {
			setFlag("isVisibleWhileShowingPlaceholder")
		}
	}
	public var shouldPin: Bool = false {
		didSet {
			setFlag("shouldPin")
		}
	}
	public var width: CGFloat?
	public var height: CGFloat? {
		didSet {
			setFlag("height")
		}
	}
	public var estimatedWidth: CGFloat = DefaultEstimatedHeight
	public var estimatedHeight: CGFloat = DefaultEstimatedHeight {
		didSet {
			setFlag("estimatedHeight")
		}
	}
	public var isHidden: Bool = false {
		didSet {
			setFlag("isHidden")
		}
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
		if let layoutAttributes = _layoutAttributes where layoutAttributes.indexPath == indexPath {
			return layoutAttributes
		}
		
		let attributes = CollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind, withIndexPath: indexPath)
		let section = self.section as? GridLayoutSection
		let metrics = section?.metrics
		let layoutInfo = section?.layoutInfo
		
		attributes.frame = frame
		attributes.unpinnedOrigin = frame.origin
		attributes.zIndex = headerZIndex
		attributes.isPinned = false
		attributes.backgroundColor = backgroundColor ?? metrics?.backgroundColor
		attributes.selectedBackgroundColor = selectedBackgroundColor
		attributes.layoutMargins = layoutMargins
		attributes.isEditing = layoutInfo?.isEditing ?? false
		attributes.hidden = false
		attributes.shouldCalculateFittingSize = hasEstimatedHeight
		attributes.simulatesSelection = simulatesSelection
		attributes.pinnedSeparatorColor = pinnedSeparatorColor ?? metrics?.separatorColor
		attributes.pinnedBackgroundColor = pinnedBackgroundColor ?? metrics?.backgroundColor
		attributes.showsSeparator = showsSeparator
		attributes.cornerRadius = metrics?.cornerRadius ?? 0
		
		_layoutAttributes = attributes
		return attributes
	}
	private var _layoutAttributes: CollectionViewLayoutAttributes?
	
	public func configure(with configuration: SupplementaryItemConfiguration) {
		guard let configureView = self.configureView else {
			self.configureView = configuration
			return
		}
		
		self.configureView = { (view: UICollectionReusableView, dataSource: CollectionDataSource, indexPath: NSIndexPath) in
			configureView(view: view, dataSource: dataSource, indexPath: indexPath)
			configuration(view: view, dataSource: dataSource, indexPath: indexPath)
		}
	}
	
	public func applyValues(from metrics: SupplementaryItem) {
		guard let metrics = metrics as? GridSupplementaryItem else {
			return
		}
		if metrics.definesMetric("layoutMargins") {
			layoutMargins = metrics.layoutMargins
		}
		if metrics.definesMetric("separatorColor") {
			separatorColor = metrics.separatorColor
		}
		if metrics.definesMetric("pinnedSeparatorColor") {
			pinnedSeparatorColor = metrics.pinnedSeparatorColor
		}
		if metrics.definesMetric("backgroundColor") {
			backgroundColor = metrics.backgroundColor
		}
		if metrics.definesMetric("pinnedBackgroundColor") {
			pinnedBackgroundColor = metrics.pinnedBackgroundColor
		}
		if metrics.definesMetric("selectedBackgroundColor") {
			selectedBackgroundColor = metrics.selectedBackgroundColor
		}
		if metrics.definesMetric("simulatesSelection") {
			simulatesSelection = metrics.simulatesSelection
		}
		if metrics.definesMetric("height") {
			height = metrics.height
		}
		if metrics.definesMetric("estimatedHeight") {
			estimatedHeight = metrics.estimatedHeight
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
		if metrics.definesMetric("showsSeparator") {
			showsSeparator = metrics.showsSeparator
		}
		
		supplementaryViewClass = metrics.supplementaryViewClass
		configureView = metrics.configureView
		reuseIdentifier = metrics.reuseIdentifier
	}
	
	public func definesMetric(metric: String) -> Bool {
		return flags.contains(metric)
	}
	
	public func setFrame(frame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		
	}
	
	public func resetLayoutAttributes() {
		_layoutAttributes = nil
	}
	
	public func copyWithZone(zone: NSZone) -> AnyObject {
		let copy = BasicGridSupplementaryItem(elementKind: elementKind)
		
		copy.reuseIdentifier = reuseIdentifier
		copy.supplementaryViewClass = supplementaryViewClass
		copy.configureView = configureView
		
		copy.height = height
		copy.estimatedHeight = estimatedHeight
		copy.isHidden = isHidden
		copy.shouldPin = shouldPin
		copy.isVisibleWhileShowingPlaceholder = isVisibleWhileShowingPlaceholder
		copy.backgroundColor = backgroundColor
		copy.selectedBackgroundColor = selectedBackgroundColor
		copy.layoutMargins = layoutMargins
		copy.separatorColor = separatorColor
		copy.pinnedSeparatorColor = pinnedSeparatorColor
		copy.showsSeparator = showsSeparator
		
		return copy
	}
	
	private var flags: Set<String> = []
	
	private func setFlag(flag: String) {
		flags.insert(flag)
	}
	
}
