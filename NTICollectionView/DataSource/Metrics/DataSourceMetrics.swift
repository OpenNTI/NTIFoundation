//
//  DataSourceMetrics.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/12/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public protocol DataSourceSectionMetrics: DataSourceSectionInfo, SectionMetrics {
	
	var metrics: SectionMetrics { get set }
	
	func copy() -> AnyObject
	
}

extension DataSourceSectionMetrics {
	
	public func applyValues(from metrics: SectionMetrics) {
		guard let dataSourceMetrics = metrics as? DataSourceSectionMetrics else {
			return self.metrics.applyValues(from: metrics)
		}
		
		self.metrics.applyValues(from: dataSourceMetrics.metrics)
		
		for (kind, items) in dataSourceMetrics.supplementaryItemsByKind {
			var myItems = supplementaryItemsOfKind(kind)
			myItems.appendContentsOf(items)
			supplementaryItemsByKind[kind] = myItems
		}
		
		if placeholder == nil {
			placeholder = dataSourceMetrics.placeholder
		}
	}
	
}
