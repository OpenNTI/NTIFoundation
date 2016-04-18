//
//  GridSupplementaryItem.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/19/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

// MARK: - GridSupplementaryItem

public protocol GridSupplementaryItem: LayoutSupplementaryItem, GridSupplementaryAttributeProvider {
	
	/// Y-origin when not pinned.
	var unpinnedY: CGFloat { get set }
	
	// Whether `self` is pinned in place.
	var isPinned: Bool { get set }
	
}

// MARK: - GridSupplementaryItemWrapper

public protocol GridSupplementaryItemWrapper: GridSupplementaryItem, SupplementaryItemWrapper {
	
	var gridSupplementaryItem: BasicGridSupplementaryItem { get set }
	
}

extension GridSupplementaryItemWrapper {
	
	public var supplementaryItem: SupplementaryItem {
		get {
			return gridSupplementaryItem.supplementaryItem
		}
		set {
			gridSupplementaryItem.supplementaryItem = newValue
		}
	}
	
	public var layoutMargins: UIEdgeInsets {
		get {
			return gridSupplementaryItem.layoutMargins
		}
		set {
			gridSupplementaryItem.layoutMargins = newValue
		}
	}
	
	public var backgroundColor: UIColor? {
		get {
			return gridSupplementaryItem.backgroundColor
		}
		set {
			gridSupplementaryItem.backgroundColor = newValue
		}
	}
	
	public var selectedBackgroundColor: UIColor? {
		get {
			return gridSupplementaryItem.selectedBackgroundColor
		}
		set {
			gridSupplementaryItem.selectedBackgroundColor = newValue
		}
	}
	
	public var pinnedBackgroundColor: UIColor? {
		get {
			return gridSupplementaryItem.pinnedBackgroundColor
		}
		set {
			gridSupplementaryItem.pinnedBackgroundColor = newValue
		}
	}
	
	public var showsSeparator: Bool {
		get {
			return gridSupplementaryItem.showsSeparator
		}
		set {
			gridSupplementaryItem.showsSeparator = newValue
		}
	}
	
	public var separatorColor: UIColor? {
		get {
			return gridSupplementaryItem.separatorColor
		}
		set {
			gridSupplementaryItem.separatorColor = newValue
		}
	}
	
	public var pinnedSeparatorColor: UIColor? {
		get {
			return gridSupplementaryItem.pinnedSeparatorColor
		}
		set {
			gridSupplementaryItem.pinnedSeparatorColor = newValue
		}
	}
	
	public var simulatesSelection: Bool {
		get {
			return gridSupplementaryItem.simulatesSelection
		}
		set {
			gridSupplementaryItem.simulatesSelection = newValue
		}
	}
	
	public var section: LayoutSection? {
		get {
			return gridSupplementaryItem.section
		}
		set {
			gridSupplementaryItem.section = newValue
		}
	}
	
	public var frame: CGRect {
		get {
			return gridSupplementaryItem.frame
		}
		set {
			gridSupplementaryItem.frame = newValue
		}
	}
	
	public var unpinnedY: CGFloat {
		get {
			return gridSupplementaryItem.unpinnedY
		}
		set {
			gridSupplementaryItem.unpinnedY = newValue
		}
	}
	
	public var isPinned: Bool {
		get {
			return gridSupplementaryItem.isPinned
		}
		set {
			gridSupplementaryItem.isPinned = newValue
		}
	}
	
	public var itemIndex: Int {
		get {
			return gridSupplementaryItem.itemIndex
		}
		set {
			gridSupplementaryItem.itemIndex = newValue
		}
	}
	
	public var indexPath: NSIndexPath {
		return gridSupplementaryItem.indexPath
	}
	
	public var layoutAttributes: UICollectionViewLayoutAttributes {
		return gridSupplementaryItem.layoutAttributes
	}
	
	public mutating func resetLayoutAttributes() {
		gridSupplementaryItem.resetLayoutAttributes()
	}
	
	public mutating func setFrame(frame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		gridSupplementaryItem.setFrame(frame, invalidationContext: invalidationContext)
	}
	
	public mutating func applyValues(from metrics: SupplementaryItem) {
		gridSupplementaryItem.applyValues(from: metrics)
	}
	
	public func definesMetric(metric: String) -> Bool {
		return gridSupplementaryItem.definesMetric(metric)
	}
	
}

private let DefaultEstimatedHeight: CGFloat = 44

public struct BasicGridSupplementaryItem: GridSupplementaryItem, SupplementaryItemWrapper {
	
	public init(elementKind: String) {
		supplementaryItem = BasicSupplementaryItem(elementKind: elementKind)
	}
	
	public var supplementaryItem: SupplementaryItem
	
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
	
	public var frame = CGRectZero
	
	public var unpinnedY: CGFloat = 0
	
	public var isPinned = false
	
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
	
	public var layoutAttributes: CollectionViewLayoutAttributes {
//		if let layoutAttributes = _layoutAttributes where layoutAttributes.indexPath == indexPath {
//			return layoutAttributes
//		}
		
		let attributes = CollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind, withIndexPath: indexPath)
		let section = self.section as? GridLayoutSection
		let metrics = section?.metrics
		
		attributes.frame = frame
		attributes.unpinnedOrigin = CGPoint(x: frame.origin.x, y: unpinnedY)
		attributes.zIndex = zIndex
		attributes.isPinned = false
		attributes.backgroundColor = backgroundColor ?? metrics?.backgroundColor
		attributes.selectedBackgroundColor = selectedBackgroundColor
		attributes.layoutMargins = layoutMargins
		attributes.hidden = false
		attributes.shouldCalculateFittingSize = hasEstimatedHeight
		attributes.simulatesSelection = simulatesSelection
		attributes.pinnedSeparatorColor = pinnedSeparatorColor ?? metrics?.separatorColor
		attributes.pinnedBackgroundColor = pinnedBackgroundColor ?? metrics?.backgroundColor
		attributes.showsSeparator = showsSeparator
		attributes.cornerRadius = metrics?.cornerRadius ?? 0
		
//		_layoutAttributes = attributes
		return attributes
	}
	private var _layoutAttributes: CollectionViewLayoutAttributes?
	
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
		supplementaryItem.applyValues(from: metrics)
		
		guard let gridMetrics = metrics as? GridSupplementaryItem else {
			return
		}
		
		if gridMetrics.definesMetric("layoutMargins") {
			layoutMargins = gridMetrics.layoutMargins
		}
		if gridMetrics.definesMetric("separatorColor") {
			separatorColor = gridMetrics.separatorColor
		}
		if gridMetrics.definesMetric("pinnedSeparatorColor") {
			pinnedSeparatorColor = gridMetrics.pinnedSeparatorColor
		}
		if gridMetrics.definesMetric("backgroundColor") {
			backgroundColor = gridMetrics.backgroundColor
		}
		if gridMetrics.definesMetric("pinnedBackgroundColor") {
			pinnedBackgroundColor = gridMetrics.pinnedBackgroundColor
		}
		if gridMetrics.definesMetric("selectedBackgroundColor") {
			selectedBackgroundColor = gridMetrics.selectedBackgroundColor
		}
		if gridMetrics.definesMetric("simulatesSelection") {
			simulatesSelection = gridMetrics.simulatesSelection
		}
		if gridMetrics.definesMetric("showsSeparator") {
			showsSeparator = gridMetrics.showsSeparator
		}
	}
	
	public func definesMetric(metric: String) -> Bool {
		if supplementaryItem.definesMetric(metric) {
			return true
		}
		
		return flags.contains(metric)
	}
	
	public mutating func setFrame(frame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		
	}
	
	public mutating func resetLayoutAttributes() {
		_layoutAttributes = nil
	}
	
	private var flags: Set<String> = []
	
	private mutating func setFlag(flag: String) {
		flags.insert(flag)
	}
	
	public func isEqual(to other: SupplementaryItem) -> Bool {
		guard supplementaryItem.isEqual(to: other) else {
			return false
		}
		
		guard let other = other as? BasicGridSupplementaryItem else {
			return false
		}
		
		return layoutMargins == other.layoutMargins
			&& backgroundColor == other.backgroundColor
			&& selectedBackgroundColor == other.selectedBackgroundColor
			&& pinnedBackgroundColor == other.pinnedBackgroundColor
			&& showsSeparator == other.showsSeparator
			&& separatorColor == other.separatorColor
			&& pinnedSeparatorColor == other.pinnedSeparatorColor
			&& simulatesSelection == other.simulatesSelection
	}
	
}
