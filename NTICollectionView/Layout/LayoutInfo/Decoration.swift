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

public protocol LayoutDecoration: DecorationAttributeProvider {
	
	var elementKind: String { get }
	
	var indexPath: NSIndexPath { get }
	
	var itemIndex: Int { get set }
	
	var sectionIndex: Int { get set }
	
	var layoutAttributes: UICollectionViewLayoutAttributes { get }
	
	mutating func setContainerFrame(containerFrame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext?)
	
}

private let hairline: CGFloat = 1.0 / UIScreen.mainScreen().scale

public let collectionElementKindHorizontalSeparator = "collectionElementKindHorizontalSeparator"

public enum HorizontalSeparatorPosition {
	
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

public struct HorizontalSeparatorDecoration: LayoutDecoration, DecorationAttributesWrapper {
	
	public init(elementKind: String, position: HorizontalSeparatorPosition) {
		self.elementKind = elementKind
		self.position = position
	}
	
	public var thickness: CGFloat = hairline
	
	public var leftMargin: CGFloat = 0
	
	public var rightMargin: CGFloat = 0
	
	public var position: HorizontalSeparatorPosition
	
	public let elementKind: String
	
	public var indexPath: NSIndexPath {
		return NSIndexPath(forItem: itemIndex, inSection: sectionIndex)
	}
	
	public var itemIndex: Int = 0
	
	public var sectionIndex: Int = 0
	
	public var attributes = DecorationAttributes()
	
	public var layoutAttributes: UICollectionViewLayoutAttributes {
		let layoutAttributes = CollectionViewLayoutAttributes(forDecorationViewOfKind: elementKind, withIndexPath: indexPath)
		layoutAttributes.frame = frame
		layoutAttributes.backgroundColor = color
		layoutAttributes.zIndex = zIndex
		layoutAttributes.hidden = isHidden
		return layoutAttributes
	}
	
	public mutating func setContainerFrame(containerFrame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		frame.origin.x = containerFrame.minX + leftMargin
		frame.origin.y = computeYCoordinate(for: containerFrame)
		frame.size.width = containerFrame.width - leftMargin - rightMargin
		frame.size.height = thickness
		
		invalidationContext?.invalidateDecorationElement(with: layoutAttributes)
	}
	
	private func computeYCoordinate(for containerFrame: CGRect) -> CGFloat {
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
	
}

public let collectionElementKindVerticalSeparator = "collectionElementKindVerticalSeparator"

public enum VerticalSeparatorPosition {
	
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

public struct VerticalSeparatorDecoration: LayoutDecoration, DecorationAttributesWrapper {
	
	public init(elementKind: String, position: VerticalSeparatorPosition) {
		self.elementKind = elementKind
		self.position = position
	}
	
	public var thickness: CGFloat = hairline
	
	public var topMargin: CGFloat = 0
	
	public var bottomMargin: CGFloat = 0
	
	public var position: VerticalSeparatorPosition
	
	public let elementKind: String
	
	public var indexPath: NSIndexPath {
		return NSIndexPath(forItem: itemIndex, inSection: sectionIndex)
	}
	
	public var itemIndex: Int = 0
	
	public var sectionIndex: Int = 0
	
	public var attributes = DecorationAttributes()
	
	public var layoutAttributes: UICollectionViewLayoutAttributes {
		let layoutAttributes = CollectionViewLayoutAttributes(forDecorationViewOfKind: elementKind, withIndexPath: indexPath)
		layoutAttributes.frame = frame
		layoutAttributes.backgroundColor = color
		layoutAttributes.zIndex = zIndex
		layoutAttributes.hidden = isHidden
		return layoutAttributes
	}
	
	public mutating func setContainerFrame(containerFrame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		
		frame.origin.x = computeXCoordinate(for: containerFrame)
		frame.origin.y = containerFrame.minY + topMargin
		frame.size.width = thickness
		frame.size.height = containerFrame.height - topMargin - bottomMargin
		
		invalidationContext?.invalidateDecorationElement(with: layoutAttributes)
	}
	
	private func computeXCoordinate(for containerFrame: CGRect) -> CGFloat {
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
	
}

public struct BackgroundDecoration: LayoutDecoration, DecorationAttributesWrapper {
	
	public init(elementKind: String) {
		self.elementKind = elementKind
	}
	
	public var margins = UIEdgeInsetsZero
	
	public var cornerRadius: CGFloat = 0
	
	public let elementKind: String
	
	public var indexPath: NSIndexPath {
		return NSIndexPath(forItem: itemIndex, inSection: sectionIndex)
	}
	
	public var itemIndex: Int = 0
	
	public var sectionIndex: Int = 0
	
	public var attributes = DecorationAttributes()
	
	public var layoutAttributes: UICollectionViewLayoutAttributes {
		let layoutAttributes = CollectionViewLayoutAttributes(forDecorationViewOfKind: elementKind, withIndexPath: indexPath)
		layoutAttributes.frame = frame
		layoutAttributes.backgroundColor = color
		layoutAttributes.zIndex = zIndex
		layoutAttributes.hidden = isHidden
		layoutAttributes.cornerRadius = cornerRadius
		return layoutAttributes
	}
	
	public mutating func setContainerFrame(containerFrame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		frame = UIEdgeInsetsInsetRect(containerFrame, margins)
		
		invalidationContext?.invalidateDecorationElement(with: layoutAttributes)
	}
	
}

public protocol DecorationAttributeProvider {
	
	var frame: CGRect { get set }
	
	var zIndex: Int { get set }
	
	var isHidden: Bool { get set }
	
	var color: UIColor? { get set }
	
}

public struct DecorationAttributes: DecorationAttributeProvider {
	
	public var frame: CGRect = CGRectZero
	
	public var zIndex: Int = 0
	
	public var isHidden: Bool = false
	
	public var color: UIColor?
	
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
