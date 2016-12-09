//
//  Decoration.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 3/15/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public protocol DecorationProvider {
	
	associatedtype SectionType: LayoutSection
	
}

public protocol LayoutDecoration: DecorationAttributeProvider, DecorationLayoutInfoProvider {
	
	var layoutAttributes: CollectionViewLayoutAttributes { get }
	
	mutating func setContainerFrame(_ containerFrame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext?)
	
	func isEqual(to other: LayoutDecoration) -> Bool
	
}

public protocol DecorationLayoutInfoProvider {
	
	var elementKind: String { get }
	
	var itemIndex: Int { get set }
	
	var sectionIndex: Int { get set }
	
	var indexPath: IndexPath { get }
	
}

public struct DecorationLayoutInfo: DecorationLayoutInfoProvider, Equatable {
	
	public init(elementKind: String) {
		self.elementKind = elementKind
	}
	
	public var elementKind: String
	
	public var itemIndex: Int = NSNotFound
	
	public var sectionIndex: Int = NSNotFound
	
	public var indexPath: IndexPath {
		return sectionIndex == globalSectionIndex ?
		IndexPath(index: itemIndex)
		: IndexPath(item: itemIndex, section: sectionIndex)
	}
}

public func ==(lhs: DecorationLayoutInfo, rhs: DecorationLayoutInfo) -> Bool {
	return lhs.elementKind == rhs.elementKind
		&& lhs.itemIndex == rhs.itemIndex
		&& lhs.sectionIndex == rhs.sectionIndex
}

public protocol DecorationLayoutInfoWrapper: DecorationLayoutInfoProvider {
	
	var decorationLayoutInfo: DecorationLayoutInfo { get set }
	
}

extension DecorationLayoutInfoWrapper {
	
	public var elementKind: String {
		return decorationLayoutInfo.elementKind
	}
	
	public var itemIndex: Int {
		get {
			return decorationLayoutInfo.itemIndex
		}
		set {
			decorationLayoutInfo.itemIndex = newValue
		}
	}
	
	public var sectionIndex: Int {
		get {
			return decorationLayoutInfo.sectionIndex
		}
		set {
			decorationLayoutInfo.sectionIndex = newValue
		}
	}
	
	public var indexPath: IndexPath {
		return decorationLayoutInfo.indexPath
	}
	
}

private let hairline: CGFloat = 1.0 / UIScreen.main.scale

public let collectionElementKindHorizontalSeparator = "collectionElementKindHorizontalSeparator"

public enum HorizontalSeparatorPosition: Equatable {
	
	/// The separator appears at the top of its container.
	case top
	
	/// The separator appears at the bottom of its container.
	case bottom
	
	/// The separator appears at a fixed y-coordinate relative to its container's origin.
	case fixed(CGFloat)
	
	/// The separator appears at a y-coordinate proportional to a ratio of its container's height, relative to its container's origin.
	///
	/// The associated value should be between `0.0` and `1.0`; any other values will be clamped to this range.
	case ratio(CGFloat)
	
}

public func ==(lhs: HorizontalSeparatorPosition, rhs: HorizontalSeparatorPosition) -> Bool {
	switch (lhs, rhs) {
	case (.top, .top), (.bottom, .bottom):
		return true
	case let (.fixed(x), .fixed(y)):
		return x == y
	case let (.ratio(x), .ratio(y)):
		return x == y
	default:
		return false
	}
}

public struct HorizontalSeparatorDecoration: LayoutDecoration, DecorationAttributesWrapper, DecorationLayoutInfoWrapper {
	
	public init(elementKind: String, position: HorizontalSeparatorPosition) {
		decorationLayoutInfo = DecorationLayoutInfo(elementKind: elementKind)
		self.position = position
	}
	
	public var decorationLayoutInfo: DecorationLayoutInfo
	
	public var thickness: CGFloat = hairline
	
	public var leftMargin: CGFloat = 0
	
	public var rightMargin: CGFloat = 0
	
	public var position: HorizontalSeparatorPosition
	
	public var attributes = DecorationAttributes()
	
	public var layoutAttributes: CollectionViewLayoutAttributes {
		let layoutAttributes = CollectionViewLayoutAttributes(forDecorationViewOfKind: elementKind, with: indexPath)
		layoutAttributes.frame = frame
		layoutAttributes.backgroundColor = color
		layoutAttributes.zIndex = zIndex
		layoutAttributes.isHidden = isHidden
		return layoutAttributes
	}
	
	public mutating func setContainerFrame(_ containerFrame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		frame.origin.x = containerFrame.minX + leftMargin
		frame.origin.y = computeYCoordinate(for: containerFrame)
		frame.size.width = containerFrame.width - leftMargin - rightMargin
		frame.size.height = thickness
		
		invalidationContext?.invalidateDecorationElement(with: layoutAttributes)
	}
	
	fileprivate func computeYCoordinate(for containerFrame: CGRect) -> CGFloat {
		switch position {
		case .top:
			return containerFrame.minY
		case .bottom:
			return containerFrame.maxY
		case let .fixed(y):
			return containerFrame.minY + y
		case let .ratio(r):
			let r = min(max(r, 0), 1)
			return containerFrame.minY + r * containerFrame.height
		}
	}
	
	public func isEqual(to other: LayoutDecoration) -> Bool {
		guard let other = other as? HorizontalSeparatorDecoration else {
			return false
		}
		
		return attributes == other.attributes
			&& decorationLayoutInfo == other.decorationLayoutInfo
			&& thickness == other.thickness
			&& leftMargin == other.leftMargin
			&& position == other.position
	}
	
}

public let collectionElementKindVerticalSeparator = "collectionElementKindVerticalSeparator"

public enum VerticalSeparatorPosition: Equatable {
	
	/// The separator appears at the left of its container.
	case left
	
	/// The separator appears at the right of its container.
	case right
	
	/// The separator appears at a fixed x-coordinate relative to its container's origin.
	case fixed(CGFloat)
	
	/// The separator appears at a x-coordinate proportional to a ratio of its container's width, relative to its container's origin.
	///
	/// The associated value should be between `0.0` and `1.0`; any other values will be clamped to this range.
	case ratio(CGFloat)
	
}

public func ==(lhs: VerticalSeparatorPosition, rhs: VerticalSeparatorPosition) -> Bool {
	switch (lhs, rhs) {
	case (.left, .left), (.right, .right):
		return true
	case let (.fixed(x), .fixed(y)):
		return x == y
	case let (.ratio(x), .ratio(y)):
		return x == y
	default:
		return false
	}
}

public struct VerticalSeparatorDecoration: LayoutDecoration, DecorationAttributesWrapper, DecorationLayoutInfoWrapper {
	
	public init(elementKind: String, position: VerticalSeparatorPosition) {
		decorationLayoutInfo = DecorationLayoutInfo(elementKind: elementKind)
		self.position = position
	}
	
	public var decorationLayoutInfo: DecorationLayoutInfo
	
	public var thickness: CGFloat = hairline
	
	public var topMargin: CGFloat = 0
	
	public var bottomMargin: CGFloat = 0
	
	public var position: VerticalSeparatorPosition
	
	public var attributes = DecorationAttributes()
	
	public var layoutAttributes: CollectionViewLayoutAttributes {
		let layoutAttributes = CollectionViewLayoutAttributes(forDecorationViewOfKind: elementKind, with: indexPath)
		layoutAttributes.frame = frame
		layoutAttributes.backgroundColor = color
		layoutAttributes.zIndex = zIndex
		layoutAttributes.isHidden = isHidden
		return layoutAttributes
	}
	
	public mutating func setContainerFrame(_ containerFrame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		
		frame.origin.x = computeXCoordinate(for: containerFrame)
		frame.origin.y = containerFrame.minY + topMargin
		frame.size.width = thickness
		frame.size.height = containerFrame.height - topMargin - bottomMargin
		
		invalidationContext?.invalidateDecorationElement(with: layoutAttributes)
	}
	
	fileprivate func computeXCoordinate(for containerFrame: CGRect) -> CGFloat {
		switch position {
		case .left:
			return containerFrame.minX
		case .right:
			return containerFrame.maxX
		case let .fixed(x):
			return containerFrame.minX + x
		case let .ratio(r):
			let r = min(max(r, 0), 1)
			return containerFrame.minX + r * containerFrame.width
		}
	}
	
	public func isEqual(to other: LayoutDecoration) -> Bool {
		guard let other = other as? VerticalSeparatorDecoration else {
			return false
		}
		
		return attributes == other.attributes
			&& decorationLayoutInfo == other.decorationLayoutInfo
		&& thickness == other.thickness
		&& topMargin == other.topMargin
		&& bottomMargin == other.bottomMargin
		&& position == other.position
	}
	
}

public struct BackgroundDecoration: LayoutDecoration, DecorationAttributesWrapper, DecorationLayoutInfoWrapper {
	
	public init(elementKind: String) {
		decorationLayoutInfo = DecorationLayoutInfo(elementKind: elementKind)
	}
	
	public var decorationLayoutInfo: DecorationLayoutInfo
	
	public var margins = UIEdgeInsets.zero
	
	public var cornerRadius: CGFloat = 0
	
	public var attributes = DecorationAttributes()
	
	public var layoutAttributes: CollectionViewLayoutAttributes {
		let layoutAttributes = CollectionViewLayoutAttributes(forDecorationViewOfKind: elementKind, with: indexPath)
		layoutAttributes.frame = frame
		layoutAttributes.backgroundColor = color
		layoutAttributes.zIndex = zIndex
		layoutAttributes.isHidden = isHidden
		layoutAttributes.cornerRadius = cornerRadius
		return layoutAttributes
	}
	
	public mutating func setContainerFrame(_ containerFrame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		frame = UIEdgeInsetsInsetRect(containerFrame, margins)
		
		invalidationContext?.invalidateDecorationElement(with: layoutAttributes)
	}
	
	public func isEqual(to other: LayoutDecoration) -> Bool {
		guard let other = other as? BackgroundDecoration else {
			return false
		}
		
		return attributes == other.attributes
			&& decorationLayoutInfo == other.decorationLayoutInfo
			&& margins == other.margins
			&& cornerRadius == other.cornerRadius
	}
	
}

public protocol DecorationAttributeProvider {
	
	var frame: CGRect { get set }
	
	var zIndex: Int { get set }
	
	var isHidden: Bool { get set }
	
	var color: UIColor? { get set }
	
}

public struct DecorationAttributes: DecorationAttributeProvider, Equatable {
	
	public var frame: CGRect = CGRect.zero
	
	public var zIndex: Int = 0
	
	public var isHidden: Bool = false
	
	public var color: UIColor?
	
}

public func ==(lhs: DecorationAttributes, rhs: DecorationAttributes) -> Bool {
	return lhs.frame == rhs.frame
		&& lhs.zIndex == rhs.zIndex
		&& lhs.isHidden == rhs.isHidden
		&& lhs.color == rhs.color
}

public protocol DecorationAttributesWrapper: DecorationAttributeProvider {
	
	var attributes: DecorationAttributes { get set }
	
}

extension DecorationAttributesWrapper {
	
	public var frame: CGRect {
		get {
			return attributes.frame
		}
		set {
			attributes.frame = newValue
		}
	}
	
	public var zIndex: Int {
		get {
			return attributes.zIndex
		}
		set {
			attributes.zIndex = newValue
		}
	}
	
	public var isHidden: Bool {
		get {
			return attributes.isHidden
		}
		set {
			attributes.isHidden = newValue
		}
	}
	
	public var color: UIColor? {
		get {
			return attributes.color
		}
		set {
			attributes.color = newValue
		}
	}
	
}

public struct BackgroundDecorationAttributes: Equatable {
	
	public var color: UIColor?
	
	public var cornerRadius: CGFloat = 0
	
}

public func ==(lhs: BackgroundDecorationAttributes, rhs: BackgroundDecorationAttributes) -> Bool {
	return lhs.color == rhs.color
	&& lhs.cornerRadius == rhs.cornerRadius
}
