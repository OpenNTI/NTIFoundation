//
//  BasicSectionMetrics.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 4/20/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public struct BasicSectionMetrics: SectionMetrics {
	
	public var contentInset: UIEdgeInsets = .zero {
		didSet {setFlag("contentInset")}
	}
	
	public var backgroundColor: UIColor? {
		didSet {setFlag("backgroundColor")}
	}
	
	public var selectedBackgroundColor: UIColor? {
		didSet {setFlag("selectedBackgroundColor")}
	}
	
	public var cornerRadius: CGFloat = 0 {
		didSet {setFlag("cornerRadius")}
	}
	
	public var decorationsByKind: [String : [LayoutDecoration]] = [:]
	
	public mutating func setFlag(flag: String) {
		flags.insert(flag)
	}
	
	private var flags: Set<String> = []
	
}

// MARK: - LayoutMetrics

extension BasicSectionMetrics {
	
	public func definesMetric(metric: String) -> Bool {
		return flags.contains(metric)
	}
	
	public mutating func resolveMissingValuesFromTheme() {
		
	}
	
	public func isEqual(to other: LayoutMetrics) -> Bool {
		guard let other = other as? BasicSectionMetrics else {
			return false
		}
		
		return contentInset == other.contentInset
			&& backgroundColor == other.backgroundColor
			&& selectedBackgroundColor == other.selectedBackgroundColor
			&& cornerRadius == other.cornerRadius
			&& decorationsByKind.elementsEqual(other.decorationsByKind) {
				(lhs: (kind: String, decorations: [LayoutDecoration]), rhs: (kind: String, decorations: [LayoutDecoration])) -> Bool in
				lhs.kind == rhs.kind
					&& lhs.decorations.elementsEqual(rhs.decorations) {$0.isEqual(to: $1)}
		}
	}
	
}

// MARK: - LayoutMetricsApplicable

extension BasicSectionMetrics {
	
	public mutating func applyValues(from metrics: LayoutMetrics) {
		guard let metrics = metrics as? SectionMetrics else {
			return
		}
		
		decorationsByKind.appendContents(of: metrics.decorationsByKind)
		
		if metrics.definesMetric("contentInset") {
			contentInset = metrics.contentInset
		}
		
		if metrics.definesMetric("backgroundColor") {
			backgroundColor = metrics.backgroundColor
		}
		
		if metrics.definesMetric("selectedBackgroundColor") {
			selectedBackgroundColor = metrics.selectedBackgroundColor
		}
		
		if metrics.definesMetric("cornerRadius") {
			cornerRadius = metrics.cornerRadius
		}
	}
	
}
