//
//  LayoutDescription.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 4/19/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

/// Data used for creating layout info.
public struct LayoutDescription {
	
	public var size = CGSizeZero
	
	public var contentOffset = CGPointZero
	
	public var contentInset = UIEdgeInsetsZero
	
	public var bounds = CGRectZero
	
	public var sections: [SectionDescription] = []
	
	public var globalSection: SectionDescription?
	
}

/// Data used for creating a layout section.
public struct SectionDescription {
	
	public init(metrics: SectionMetrics) {
		self.metrics = metrics
	}
	
	public var sectionIndex = NSNotFound
	
	public var numberOfItems = 0
	
	public var metrics: SectionMetrics
	
	public var sizingInfo: CollectionViewLayoutMeasuring?
	
	public var supplementaryItemsByKind: [String: [SupplementaryItem]] = [:]
	
}
