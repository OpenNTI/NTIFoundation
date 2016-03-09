//
//  GridSectionMetrics.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/16/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public protocol GridSectionMetrics: SectionMetrics {
	
	/// The height of each row in the section. The default value is `nil`. Setting this property to a concrete value will prevent rows from being sized automatically using autolayout.
	var rowHeight: CGFloat? { get set }
	
	/// The estimated height of each row in the section. The default value is 44pts. The closer the estimatedRowHeight value matches the actual value of the row height, the less change will be noticed when rows are resized.
	var estimatedRowHeight: CGFloat { get set }
	
	/// An optional fixed width that can be used to size each column.
	var fixedColumnWidth: CGFloat? { get set }
	
	/// Number of columns in this section. Sections will inherit a default of 1 from the data source.
	var numberOfColumns: Int { get set }
	
	/// Padding around the cells for this section. The top & bottom padding will be applied between the headers & footers and the cells. The left & right padding will be applied between the view edges and the cells.
	var padding: UIEdgeInsets { get set }
	
	/// Layout margins for cells in this section. When not set (e.g. UIEdgeInsetsZero), the default value of the theme will be used, listLayoutMargins.
	var layoutMargins: UIEdgeInsets { get set }
	
	/// Whether a column separator should be drawn. Default is `true`.
	var showsColumnSeparator: Bool { get set }
	
	/// Whether a row separator should be drawn. Default is `false`.
	var showsRowSeparator: Bool { get set }
	
	/// Whether separators should be drawn between sections. Default is `false`.
	var showsSectionSeparator: Bool { get set }
	
	/// Whether the section separator should be shown at the bottom of the last section. Default is `false`.
	var showsSectionSeparatorWhenLastSection: Bool { get set }
	
	/// Insets for the separators drawn between rows (left & right) and columns (top & bottom).
	var separatorInsets: UIEdgeInsets { get set }
	
	/// Insets for the section separator drawn below this section.
	var sectionSeparatorInsets: UIEdgeInsets { get set }
	
	/// The color to use for the background of a cell in this section.
	var backgroundColor: UIColor? { get set }
	
	/// The color to use when a cell becomes highlighted or selected.
	var selectedBackgroundColor: UIColor? { get set }
	
	/// The color to use when drawing the row separators (and column separators when `numberOfColumns > 1 && showsColumnSeparator == true`).
	var separatorColor: UIColor? { get set }
	
	/// The color to use when drawing the section separator below this section.
	var sectionSeparatorColor: UIColor? { get set }
	
	/// How the cells should be laid out when there are multiple columns.
	var cellLayoutOrder: ItemLayoutOrder { get set }
	
}

public class BasicGridSectionMetrics: NSObject, GridSectionMetrics, NSCopying {

	/// The height of each row in the section. The default value is `nil`. Setting this property to a concrete value will prevent rows from being sized automatically using autolayout.
	public var rowHeight: CGFloat? = nil {
		didSet {
			setFlag("rowHeight")
		}
	}
	
	/// The estimated height of each row in the section. The default value is 44pts. The closer the estimatedRowHeight value matches the actual value of the row height, the less change will be noticed when rows are resized.
	public var estimatedRowHeight: CGFloat = 44 {
		didSet {
			setFlag("estimatedRowHeight")
		}
	}
	
	/// An optional fixed width that can be used to size each column.
	public var fixedColumnWidth: CGFloat? {
		didSet {
			setFlag("fixedColumnWidth")
		}
	}
	
	/// Number of columns in this section. Sections will inherit a default of 1 from the data source.
	public var numberOfColumns = 1 {
		didSet {
			setFlag("numberOfColumns")
		}
	}
	
	/// Padding around the cells for this section. The top & bottom padding will be applied between the headers & footers and the cells. The left & right padding will be applied between the view edges and the cells.
	public var padding = UIEdgeInsetsZero {
		didSet {
			setFlag("padding")
		}
	}
	
	/// Layout margins for cells in this section. When not set (e.g. UIEdgeInsetsZero), the default value of the theme will be used, listLayoutMargins.
	public var layoutMargins = UIEdgeInsetsZero
	
	/// Whether a column separator should be drawn. Default is `true`.
	public var showsColumnSeparator = true {
		didSet {
			setFlag("showsColumnSeparator")
		}
	}
	
	/// Whether a row separator should be drawn. Default is `false`.
	public var showsRowSeparator = false {
		didSet {
			setFlag("showsRowSeparator")
		}
	}
	
	/// Whether separators should be drawn between sections. Default is `false`.
	public var showsSectionSeparator = false {
		didSet {
			setFlag("showsSectionSeparator")
		}
	}
	
	/// Whether the section separator should be shown at the bottom of the last section. Default is `false`.
	public var showsSectionSeparatorWhenLastSection = false {
		didSet {
			setFlag("showsSectionSeparatorWhenLastSection")
		}
	}
	
	/// Insets for the separators drawn between rows (left & right) and columns (top & bottom).
	public var separatorInsets = UIEdgeInsetsZero
	
	/// Insets for the section separator drawn below this section.
	public var sectionSeparatorInsets = UIEdgeInsetsZero
	
	/// The color to use for the background of a cell in this section.
	public var backgroundColor: UIColor? {
		didSet {
			setFlag("backgroundColor")
		}
	}
	
	/// The color to use when a cell becomes highlighted or selected.
	public var selectedBackgroundColor: UIColor? {
		didSet {
			setFlag("selectedBackgroundColor")
		}
	}
	
	/// The color to use when drawing the row separators (and column separators when `numberOfColumns > 1 && showsColumnSeparator == true`).
	public var separatorColor: UIColor? {
		didSet {
			setFlag("separatorColor")
		}
	}
	
	/// The color to use when drawing the section separator below this section.
	public var sectionSeparatorColor: UIColor? {
		didSet {
			setFlag("sectionSeparatorColor")
		}
	}
	
	/// How the cells should be laid out when there are multiple columns. The current default is `.LeadingToTrailing`.
	public var cellLayoutOrder: ItemLayoutOrder = .LeadingToTrailing
	
	public func copyWithZone(zone: NSZone) -> AnyObject {
		let copy = BasicGridSectionMetrics()
		
		copy.rowHeight = rowHeight
		copy.estimatedRowHeight = estimatedRowHeight
		copy.fixedColumnWidth = fixedColumnWidth
		copy.numberOfColumns = numberOfColumns
		copy.padding = padding
		copy.showsColumnSeparator = showsColumnSeparator
		copy.separatorInsets = separatorInsets
		copy.backgroundColor = backgroundColor
		copy.selectedBackgroundColor = selectedBackgroundColor
		copy.separatorColor = separatorColor
		copy.sectionSeparatorColor = sectionSeparatorColor
		copy.sectionSeparatorInsets = sectionSeparatorInsets
		copy.showsSectionSeparator = showsSectionSeparator
		copy.showsSectionSeparatorWhenLastSection = showsSectionSeparatorWhenLastSection
		copy.cellLayoutOrder = cellLayoutOrder
		copy.showsRowSeparator = showsRowSeparator
		copy.flags = flags
		
		return copy
	}
	
	public func applyValues(from metrics: SectionMetrics) {
		guard let gridMetrics = metrics as? GridSectionMetrics else {
			return
		}
		separatorInsets = gridMetrics.separatorInsets
		sectionSeparatorInsets = gridMetrics.sectionSeparatorInsets
		
		if metrics.definesMetric("rowHeight") {
			rowHeight = gridMetrics.rowHeight
		}
		if metrics.definesMetric("estimatedRowHeight") {
			estimatedRowHeight = gridMetrics.estimatedRowHeight
		}
		if metrics.definesMetric("fixedColumnWidth") {
			fixedColumnWidth = gridMetrics.fixedColumnWidth
		}
		if metrics.definesMetric("numberOfColumns") {
			numberOfColumns = gridMetrics.numberOfColumns
		}
		if metrics.definesMetric("backgroundColor") {
			backgroundColor = gridMetrics.backgroundColor
		}
		if metrics.definesMetric("selectedBackgroundColor") {
			selectedBackgroundColor = gridMetrics.selectedBackgroundColor
		}
		if metrics.definesMetric("sectionSeparatorColor") {
			sectionSeparatorColor = gridMetrics.sectionSeparatorColor
		}
		if metrics.definesMetric("separatorColor") {
			separatorColor = gridMetrics.separatorColor
		}
		if metrics.definesMetric("showsSectionSeparatorWhenLastSection") {
			showsSectionSeparatorWhenLastSection = gridMetrics.showsSectionSeparatorWhenLastSection
		}
		if metrics.definesMetric("padding") {
			padding = gridMetrics.padding
		}
		if metrics.definesMetric("showsColumnSeparator") {
			showsColumnSeparator = gridMetrics.showsColumnSeparator
		}
		if metrics.definesMetric("showsRowSeparator") {
			showsRowSeparator = gridMetrics.showsRowSeparator
		}
		if metrics.definesMetric("showsSectionSeparator") {
			showsSectionSeparator = gridMetrics.showsSectionSeparator
		}
	}
	
	public func definesMetric(metric: String) -> Bool {
		return flags[metric] ?? false
	}
	
	public func resolveMissingValuesFromTheme() {
		if !definesMetric("backgroundColor") {
			backgroundColor = UIColor.whiteColor()
		}
		if !definesMetric("selectedBackgroundColor") {
			selectedBackgroundColor = UIColor(white: 235.0 / 0xFF, alpha: 1)
		}
		if !definesMetric("separatorColor") {
			separatorColor = UIColor(white: 204.0 / 0xFF, alpha: 1)
		}
		if !definesMetric("sectionSeparatorColor") {
			sectionSeparatorColor = UIColor(white: 204.0 / 0xFF, alpha: 1)
		}
	}
	
	private var flags = [
		"rowHeight": false,
		"estimatedRowHeight": false,
		"fixedColumnWidth": false,
		"showsSectionSeparator": false,
		"showsSectionSeparatorWhenLastSection": false,
		"backgroundColor": false,
		"selectedBackgroundColor": false,
		"separatorColor": false,
		"sectionSeparatorColor": false,
		"numberOfColumns": false,
		"theme": false,
		"padding": false,
		"showsColumnSeparator": false,
		"showsRowSeparator": false
	]
	
	private func setFlag(flag: String) {
		flags[flag] = true
	}
	
}

public protocol GridSectionMetricsOwning: SectionMetricsOwning, GridSectionMetrics {
	
	var metrics: GridSectionMetrics { get }
	
}

extension GridSectionMetricsOwning {
	
	public var rowHeight: CGFloat? {
		get {
			return metrics.rowHeight
		}
		set {
			metrics.rowHeight = newValue
		}
	}
	
	public var estimatedRowHeight: CGFloat {
		get {
			return metrics.estimatedRowHeight
		}
		set {
			metrics.estimatedRowHeight = newValue
		}
	}
	
	public var numberOfColumns: Int {
		get {
			return metrics.numberOfColumns
		}
		set {
			metrics.numberOfColumns = newValue
		}
	}
	
	public var padding: UIEdgeInsets {
		get {
			return metrics.padding
		}
		set {
			metrics.padding = newValue
		}
	}
	
	public var layoutMargins: UIEdgeInsets {
		get {
			return metrics.layoutMargins
		}
		set {
			metrics.layoutMargins = newValue
		}
	}
	
	public var showsColumnSeparator: Bool {
		get {
			return metrics.showsColumnSeparator
		}
		set {
			metrics.showsColumnSeparator = newValue
		}
	}
	
	public var showsRowSeparator: Bool {
		get {
			return metrics.showsRowSeparator
		}
		set {
			metrics.showsRowSeparator = newValue
		}
	}
	
	public var showsSectionSeparator: Bool {
		get {
			return metrics.showsSectionSeparator
		}
		set {
			metrics.showsSectionSeparator = newValue
		}
	}
	
	public var showsSectionSeparatorWhenLastSection: Bool {
		get {
			return metrics.showsSectionSeparatorWhenLastSection
		}
		set {
			metrics.showsSectionSeparatorWhenLastSection = newValue
		}
	}
	
	public var separatorInsets: UIEdgeInsets {
		get {
			return metrics.separatorInsets
		}
		set {
			metrics.separatorInsets = newValue
		}
	}
	
	public var sectionSeparatorInsets: UIEdgeInsets {
		get {
			return metrics.sectionSeparatorInsets
		}
		set {
			metrics.sectionSeparatorInsets = newValue
		}
	}
	
	public var backgroundColor: UIColor? {
		get {
			return metrics.backgroundColor
		}
		set {
			metrics.backgroundColor = newValue
		}
	}
	
	public var selectedBackgroundColor: UIColor? {
		get {
			return metrics.selectedBackgroundColor
		}
		set {
			metrics.selectedBackgroundColor = newValue
		}
	}
	
	public var separatorColor: UIColor? {
		get {
			return metrics.separatorColor
		}
		set {
			metrics.separatorColor = newValue
		}
	}
	
	public var sectionSeparatorColor: UIColor? {
		get {
			return metrics.sectionSeparatorColor
		}
		set {
			metrics.sectionSeparatorColor = newValue
		}
	}
	
	public var cellLayoutOrder: ItemLayoutOrder {
		get {
			return metrics.cellLayoutOrder
		}
		set {
			metrics.cellLayoutOrder = newValue
		}
	}
	
}
