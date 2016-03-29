//
//  GridDataSourceMetrics.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/12/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public class GridDataSourceSectionMetrics: NSObject, DataSourceSectionMetrics {
	
	public var metrics: SectionMetrics = BasicGridSectionMetrics()
	
	public var placeholder: AnyObject?
	
	public var supplementaryItemsByKind: [String: [SupplementaryItem]] = [:]
	
	public override func copy() -> AnyObject {
		let copy = GridDataSourceSectionMetrics()
		copy.metrics = (metrics as! BasicGridSectionMetrics).copy() as! BasicGridSectionMetrics
		copy.placeholder = placeholder?.copy()
		copy.supplementaryItemsByKind = supplementaryItemsByKind
		return copy
	}
	
	public func definesMetric(metric: String) -> Bool {
		return false
	}
	
	public func resolveMissingValuesFromTheme() {
		metrics.resolveMissingValuesFromTheme()
	}
	
}
