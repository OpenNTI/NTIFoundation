//
//  GridSupplementaryAttributes.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 4/18/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

// MARK: - GridSupplementaryAttributeProvider

public protocol GridSupplementaryAttributeProvider: LayoutMetricsApplicable {
	
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

// MARK: - GridSupplementaryAttributes

public struct GridSupplementaryAttributes: GridSupplementaryAttributeProvider {
	
	public var layoutMargins = UIEdgeInsetsZero
	
	public var backgroundColor: UIColor?
	
	public var selectedBackgroundColor: UIColor?
	
	public var pinnedBackgroundColor: UIColor?
	
	public var showsSeparator = false
	
	public var separatorColor: UIColor?
	
	public var pinnedSeparatorColor: UIColor?
	
	public var simulatesSelection = false
	
	public mutating func applyValues(from metrics: LayoutMetrics) {
		guard let gridMetrics = metrics as? GridSectionMetrics else {
			return
		}
		
		if backgroundColor == nil && gridMetrics.definesMetric("backgroundColor") {
			backgroundColor = gridMetrics.backgroundColor
		}
		
		if separatorColor == nil && gridMetrics.definesMetric("separatorColor") {
			separatorColor = gridMetrics.separatorColor
		}
		
		if pinnedBackgroundColor == nil && gridMetrics.definesMetric("backgroundColor") {
			pinnedBackgroundColor = gridMetrics.backgroundColor
		}
		
		if pinnedSeparatorColor == nil && gridMetrics.definesMetric("separatorColor") {
			pinnedSeparatorColor = gridMetrics.separatorColor
		}
	}
	
}

// MARK: - GridSupplementaryAttributesWrapper

public protocol GridSupplementaryAttributesWrapper: GridSupplementaryAttributeProvider {
	
	var gridSupplementaryAttributes: GridSupplementaryAttributeProvider { get set }
	
}

extension GridSupplementaryAttributesWrapper {
	
	public var layoutMargins: UIEdgeInsets {
		get {
			return gridSupplementaryAttributes.layoutMargins
		}
		set {
			gridSupplementaryAttributes.layoutMargins = newValue
		}
	}
	
	public var backgroundColor: UIColor? {
		get {
			return gridSupplementaryAttributes.backgroundColor
		}
		set {
			gridSupplementaryAttributes.backgroundColor = newValue
		}
	}
	
	public var selectedBackgroundColor: UIColor? {
		get {
			return gridSupplementaryAttributes.selectedBackgroundColor
		}
		set {
			gridSupplementaryAttributes.selectedBackgroundColor = newValue
		}
	}
	
	public var pinnedBackgroundColor: UIColor? {
		get {
			return gridSupplementaryAttributes.pinnedBackgroundColor
		}
		set {
			gridSupplementaryAttributes.pinnedBackgroundColor = newValue
		}
	}
	
	public var showsSeparator: Bool {
		get {
			return gridSupplementaryAttributes.showsSeparator
		}
		set {
			gridSupplementaryAttributes.showsSeparator = newValue
		}
	}
	
	public var separatorColor: UIColor? {
		get {
			return gridSupplementaryAttributes.separatorColor
		}
		set {
			gridSupplementaryAttributes.separatorColor = newValue
		}
	}
	
	public var pinnedSeparatorColor: UIColor? {
		get {
			return gridSupplementaryAttributes.pinnedSeparatorColor
		}
		set {
			gridSupplementaryAttributes.pinnedSeparatorColor = newValue
		}
	}
	
	public var simulatesSelection: Bool {
		get {
			return gridSupplementaryAttributes.simulatesSelection
		}
		set {
			gridSupplementaryAttributes.simulatesSelection = newValue
		}
	}
	
}
