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

public enum ItemLayoutOrder: String {
	
	case LeadingToTrailing, TrailingToLeading
	
}

public protocol SectionMetrics: NSObjectProtocol {
	
	func applyValues(from metrics: SectionMetrics)
	
	func definesMetric(metric: String) -> Bool
	
	func resolveMissingValuesFromTheme()
	
	func copy() -> AnyObject
	
}

public protocol SectionMetricsOwning: NSObjectProtocol, SectionMetrics {
	
	var metrics: SectionMetrics { get }
	
	func applyValues(from metrics: SectionMetrics)
	
	func definesMetric(metric: String) -> Bool
	
	func resolveMissingValuesFromTheme()
	
}

extension SectionMetricsOwning {
	
	public func applyValues(from metrics: SectionMetrics) {
		self.metrics.applyValues(from: metrics)
	}
	
	public func definesMetric(metric: String) -> Bool {
		return metrics.definesMetric(metric)
	}
	
	public func resolveMissingValuesFromTheme() {
		metrics.resolveMissingValuesFromTheme()
	}
	
}
