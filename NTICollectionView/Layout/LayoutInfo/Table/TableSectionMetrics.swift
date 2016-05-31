//
//  TableSectionMetrics.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 4/12/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

// MARK: - TableSectionMetricsProviding

public protocol TableSectionMetricsProviding : TableRowMetricsProviding {
	
	/// Padding around the cells for this section.
	///
	/// The top/bottom padding will be applied between the headers/footers and the cells.
	/// The left/right padding will be applied between the view edges and the cells.
	var padding: UIEdgeInsets { get set }
	
	/// Layout margins for cells in this section.
	var layoutMargins: UIEdgeInsets { get set }
	
	/// Whether separators should be drawn between sections.
	var showsSectionSeparator: Bool { get set }
	
	/// Whether the section separator should be shown at the bottom of the last section.
	var showsSectionSeparatorWhenLastSection: Bool { get set }
	
	/// Insets for the section separator drawn below this section.
	var sectionSeparatorInsets: UIEdgeInsets { get set }
	
	/// The color to use when drawing the section separator below this section.
	var sectionSeparatorColor: UIColor? { get set }
	
}

// MARK: - TableRowMetrics

public protocol TableRowMetricsProviding : LayoutMetricsApplicable {
	
	/// The height of each row in the section.
	///
	/// Setting this property to a concrete value will prevent rows from being sized automatically using autolayout.
	var rowHeight: CGFloat? { get set }
	
	/// The estimated height of each row in the section.
	///
	/// The closer the estimatedRowHeight value matches the actual value of the row height, the less change will be noticed when rows are resized.
	var estimatedRowHeight: CGFloat { get set }
	
	/// Number of columns in this section.
	var numberOfColumns: Int { get set }
	
	/// Whether a column separator should be drawn.
	var showsColumnSeparator: Bool { get set }
	
	/// Whether a row separator should be drawn.
	var showsRowSeparator: Bool { get set }
	
	/// Insets for the separators drawn between rows (left & right) and columns (top & bottom).
	var separatorInsets: UIEdgeInsets { get set }
	
	/// The color to use when drawing the row and column separators.
	var separatorColor: UIColor? { get set }
	
	/// How the cells should be laid out when there are multiple columns.
	var cellLayoutOrder: ItemLayoutOrder { get set }
	
}

// MARK: - TableSectionMetrics

public struct TableSectionMetrics : TableSectionMetricsProviding, BasicSectionMetricsWrapper {
	
	public init() {}
	
	public var basicSectionMetrics = BasicSectionMetrics()
	
	/// The height of each row in the section.
	///
	/// The default value is `nil`. Setting this property to a concrete value will prevent rows from being sized automatically using autolayout.
	public var rowHeight: CGFloat? = nil {
		didSet {
			setFlag("rowHeight")
		}
	}
	
	/// The estimated height of each row in the section.
	///
	/// The closer the estimatedRowHeight value matches the actual value of the row height, the less change will be noticed when rows are resized.
	///
	/// The default value is `44`.
	public var estimatedRowHeight: CGFloat = 44 {
		didSet {
			setFlag("estimatedRowHeight")
		}
	}
	
	/// Number of columns in this section. 
	///
	/// The default value is `1`.
	public var numberOfColumns = 1 {
		didSet {
			setFlag("numberOfColumns")
		}
	}
	
	/// Padding around the cells for this section.
	///
	/// The top/bottom padding will be applied between the headers/footers and the cells.
	/// The left/right padding will be applied between the view edges and the cells.
	///
	/// The default value is `UIEdgeInsetsZero`.
	public var padding = UIEdgeInsetsZero {
		didSet {
			setFlag("padding")
		}
	}
	
	/// Layout margins for cells in this section.
	///
	/// The default value is `UIEdgeInsetsZero`.
	public var layoutMargins = UIEdgeInsetsZero
	
	/// Whether a column separator should be drawn.
	///
	/// The default value is `false`.
	public var showsColumnSeparator = true {
		didSet {
			setFlag("showsColumnSeparator")
		}
	}
	
	/// Whether a row separator should be drawn.
	///
	/// The default value is `false`.
	public var showsRowSeparator = false {
		didSet {
			setFlag("showsRowSeparator")
		}
	}
	
	/// Whether separators should be drawn between sections.
	///
	/// The default value is `false`.
	public var showsSectionSeparator = false {
		didSet {
			setFlag("showsSectionSeparator")
		}
	}
	
	/// Whether the section separator should be shown at the bottom of the last section.
	///
	/// The default value is `false`.
	public var showsSectionSeparatorWhenLastSection = false {
		didSet {
			setFlag("showsSectionSeparatorWhenLastSection")
		}
	}
	
	/// Insets for the separators drawn between rows (left & right) and columns (top & bottom).
	///
	/// The default value is `UIEdgeInsetsZero`.
	public var separatorInsets = UIEdgeInsetsZero
	
	/// Insets for the section separator drawn below this section.
	///
	/// The default value is `UIEdgeInsetsZero`.
	public var sectionSeparatorInsets = UIEdgeInsetsZero
	
	/// The color to use when drawing the row and column separators.
	///
	/// The default value is `nil`.
	public var separatorColor: UIColor? {
		didSet {
			setFlag("separatorColor")
		}
	}
	
	/// The color to use when drawing the section separator below this section.
	///
	/// The default value is `nil`.
	public var sectionSeparatorColor: UIColor? {
		didSet {
			setFlag("sectionSeparatorColor")
		}
	}
	
	/// How the cells should be laid out when there are multiple columns.
	///
	/// The default value is `.leadingToTrailing`.
	public var cellLayoutOrder: ItemLayoutOrder = .LeadingToTrailing
	
	public func isEqual(to other: LayoutMetrics) -> Bool {
		guard let other = other as? TableSectionMetrics else {
			return false
		}
		
		return other.basicSectionMetrics.isEqual(to: basicSectionMetrics)
			&& other.rowHeight == rowHeight
			&& other.estimatedRowHeight == estimatedRowHeight
			&& other.numberOfColumns == numberOfColumns
			&& other.padding == padding
			&& other.showsColumnSeparator == showsColumnSeparator
			&& other.separatorInsets == separatorInsets
			&& other.backgroundColor == backgroundColor
			&& other.selectedBackgroundColor == selectedBackgroundColor
			&& other.separatorColor == separatorColor
			&& other.sectionSeparatorColor == sectionSeparatorColor
			&& other.sectionSeparatorInsets == sectionSeparatorInsets
			&& other.showsSectionSeparator == showsSectionSeparator
			&& other.showsSectionSeparatorWhenLastSection == showsSectionSeparatorWhenLastSection
			&& other.cellLayoutOrder == cellLayoutOrder
			&& other.showsRowSeparator == showsRowSeparator
	}
	
	public mutating func applyValues(from metrics: LayoutMetrics) {
		basicSectionMetrics.applyValues(from: metrics)
		
		guard let tableMetrics = metrics as? TableSectionMetricsProviding else {
			return
		}
		
		if metrics.definesMetric("rowHeight") {
			rowHeight = tableMetrics.rowHeight
		}
		
		if metrics.definesMetric("estimatedRowHeight") {
			estimatedRowHeight = tableMetrics.estimatedRowHeight
		}
		
		if metrics.definesMetric("numberOfColumns") {
			numberOfColumns = tableMetrics.numberOfColumns
		}
		
		if metrics.definesMetric("sectionSeparatorColor") {
			sectionSeparatorColor = tableMetrics.sectionSeparatorColor
		}
		
		if metrics.definesMetric("separatorColor") {
			separatorColor = tableMetrics.separatorColor
		}
		
		if metrics.definesMetric("showsSectionSeparatorWhenLastSection") {
			showsSectionSeparatorWhenLastSection = tableMetrics.showsSectionSeparatorWhenLastSection
		}
		
		if metrics.definesMetric("padding") {
			padding = tableMetrics.padding
		}
		
		if metrics.definesMetric("showsColumnSeparator") {
			showsColumnSeparator = tableMetrics.showsColumnSeparator
		}
		
		if metrics.definesMetric("showsRowSeparator") {
			showsRowSeparator = tableMetrics.showsRowSeparator
		}
		
		if metrics.definesMetric("showsSectionSeparator") {
			showsSectionSeparator = tableMetrics.showsSectionSeparator
		}
	}
	
	public mutating func resolveMissingValuesFromTheme() {
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
	
}


