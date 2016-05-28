//
//  DataSourceMetrics.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/12/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public protocol DataSourceSectionMetricsProviding: DataSourceSectionInfo, LayoutMetrics {
	
	var metrics: SectionMetrics { get set }
	
	/// The type of `LayoutSectionBuilder` that should be used to create the section described by `self`.
//	var sectionBuilderType: LayoutSectionBuilder.Type { get set }
	
	/// Optional information used for sizing the elements in the section described by `self`.
	var sizingInfo: CollectionViewLayoutMeasuring? { get set }
	
}

extension DataSourceSectionMetricsProviding {
	
	public mutating func applyValues(from metrics: LayoutMetrics) {
		guard let dataSourceMetrics = metrics as? DataSourceSectionMetricsProviding else {
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

public struct DataSourceSectionMetrics<LayoutClassType: LayoutClass> : DataSourceSectionMetricsProviding {
	
	public let template = LayoutClassType.SectionMetricsType.init()
	
	public var metrics: SectionMetrics = LayoutClassType.SectionMetricsType.init()
	
	public var placeholder: AnyObject?
	
	public var supplementaryItemsByKind: [String: [SupplementaryItem]] = [:]
	
	public var sizingInfo: CollectionViewLayoutMeasuring?
	
	public func makeSupplementaryItem(elementKind kind: String) -> LayoutClassType.SupplementaryItemType {
		return LayoutClassType.SupplementaryItemType.init(elementKind: kind)
	}
	
	public func isEqual(to other: LayoutMetrics) -> Bool {
		guard let other = other as? DataSourceSectionMetrics<LayoutClassType> else {
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
