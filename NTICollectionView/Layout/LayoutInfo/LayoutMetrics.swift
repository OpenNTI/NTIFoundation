//
//  LayoutMetrics.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/11/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

let defaultZIndex = 1
let headerZIndex = 1000
let pinnedHeaderZIndex = 10000

public let collectionElementKindRowSeparator = "collectionElementKindRowSeparator"
public let collectionElementKindColumnSeparator = "collectionElementKindColumnSeparator"
public let collectionElementKindSectionSeparator = "collectionElementKindSectionSeparator"
public let collectionElementKindGlobalHeaderBackground = "collectionElementKindGlobalHeaderBackground"
public let collectionElementKindContentBackground = "collectionElementKindContentBackground"

public enum ItemLayoutOrder: String {
	
	case LeadingToTrailing, TrailingToLeading
	
}

public protocol LayoutMetrics: class {
	
	func applyValues(from metrics: LayoutMetrics)
	
	func definesMetric(metric: String) -> Bool
	
	func resolveMissingValuesFromTheme()
	
	func copy() -> LayoutMetrics
	
}

public protocol SectionMetrics: LayoutMetrics {
	
	/// The distance that the section content is inset from the enclosing content.
	var contentInset: UIEdgeInsets { get set }
	
	/// The color to use for the background of a cell in this section.
	var backgroundColor: UIColor? { get set }
	
	/// The color to use when a cell becomes highlighted or selected.
	var selectedBackgroundColor: UIColor? { get set }
	
	/// The corner radius to apply to items in this section.
	var cornerRadius: CGFloat { get set }
	
	/// The decorations to add to the section represented by `self`.
	var decorationsByKind: [String: [LayoutDecoration]] { get set }
	
}

public protocol SectionMetricsOwning: SectionMetrics {
	
	var metrics: SectionMetrics { get }
	
	func applyValues(from metrics: SectionMetrics)
	
	func definesMetric(metric: String) -> Bool
	
	func resolveMissingValuesFromTheme()
	
}

extension SectionMetricsOwning {
	
	public var contentInset: UIEdgeInsets {
		get {
			return metrics.contentInset
		}
		set {
			metrics.contentInset = newValue
		}
	}
	
	public func applyValues(from metrics: LayoutMetrics) {
		self.metrics.applyValues(from: metrics)
	}
	
	public func definesMetric(metric: String) -> Bool {
		return metrics.definesMetric(metric)
	}
	
	public func resolveMissingValuesFromTheme() {
		metrics.resolveMissingValuesFromTheme()
	}
	
}
