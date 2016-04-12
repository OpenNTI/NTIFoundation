//
//  TableSectionMetrics.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 4/12/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public protocol TableSectionMetricsProtocol: SectionMetrics {
	
	/// The height of each row in the section.
	/// 
	/// Setting this property to a concrete value will prevent rows from being sized automatically using autolayout.
	var rowHeight: CGFloat? { get set }
	
	/// The estimated height of each row in the section.
	///
	/// The closer the estimatedRowHeight value matches the actual value of the row height, the less change will be noticed when rows are resized.
	var estimatedRowHeight: CGFloat { get set }
	
	/// Number of columns in this section. Sections will inherit a default of 1 from the data source.
	var numberOfColumns: Int { get set }
	
	/// Padding around the cells for this section.
	///
	/// The top/bottom padding will be applied between the headers/footers and the cells. 
	/// The left/right padding will be applied between the view edges and the cells.
	var padding: UIEdgeInsets { get set }
	
	/// Layout margins for cells in this section.
	var layoutMargins: UIEdgeInsets { get set }
	
	/// Whether a column separator should be drawn.
	var showsColumnSeparator: Bool { get set }
	
	/// Whether a row separator should be drawn.
	var showsRowSeparator: Bool { get set }
	
	/// Whether separators should be drawn between sections.
	var showsSectionSeparator: Bool { get set }
	
	/// Whether the section separator should be shown at the bottom of the last section.
	var showsSectionSeparatorWhenLastSection: Bool { get set }
	
	/// Insets for the separators drawn between rows (left & right) and columns (top & bottom).
	var separatorInsets: UIEdgeInsets { get set }
	
	/// Insets for the section separator drawn below this section.
	var sectionSeparatorInsets: UIEdgeInsets { get set }
	
	/// The color to use when drawing the row separators (and column separators when `numberOfColumns > 1 && showsColumnSeparator == true`).
	var separatorColor: UIColor? { get set }
	
	/// The color to use when drawing the section separator below this section.
	var sectionSeparatorColor: UIColor? { get set }
	
	/// How the cells should be laid out when there are multiple columns.
	var cellLayoutOrder: ItemLayoutOrder { get set }
	
}


