//
//  GridDataSourceMetrics.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/12/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public struct GridDataSourceSectionMetrics: DataSourceSectionMetrics {
	
	public init() { }
	
	public var metrics: SectionMetrics = BasicGridSectionMetrics()
	
	public var placeholder: AnyObject?
	
	public var supplementaryItemsByKind: [String: [SupplementaryItem]] = [:]
	
	public func isEqual(to other: LayoutMetrics) -> Bool {
		guard let other = other as? GridDataSourceSectionMetrics else {
			return false
		}
		
		return metrics.isEqual(to: other.metrics)
	}
	
	public func definesMetric(metric: String) -> Bool {
		return false
	}
	
	public mutating func resolveMissingValuesFromTheme() {
		metrics.resolveMissingValuesFromTheme()
	}
	
}
