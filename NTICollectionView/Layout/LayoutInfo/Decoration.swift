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

public protocol LayoutDecoration {
	
	associatedtype SectionType: LayoutSection
	
	var elementKind: String { get }
	
	var layoutAttributes: CollectionViewLayoutAttributes { get }
	
	var indexPath: NSIndexPath { get }
	
	var configureDecoration: ((inout attributes: CollectionViewLayoutAttributes, section: SectionType, indexPath: NSIndexPath, invalidationContext: UICollectionViewLayoutInvalidationContext?) -> Void)? { get }
	
	mutating func update(with section: SectionType, indexPath: NSIndexPath, invalidationContext: UICollectionViewLayoutInvalidationContext?)
	
}

public struct GridLayoutDecoration<SectionType: GridLayoutSection>: LayoutDecoration {
	
	public init(elementKind: String, indexPath: NSIndexPath = NSIndexPath()) {
		self.elementKind = elementKind
		layoutAttributes = CollectionViewLayoutAttributes(forDecorationViewOfKind: elementKind, withIndexPath: indexPath)
	}
	
	public let elementKind: String
	
	public private(set) var layoutAttributes: CollectionViewLayoutAttributes
	
	public var indexPath: NSIndexPath {
		return layoutAttributes.indexPath
	}
	
	public var configureDecoration: ((inout attributes: CollectionViewLayoutAttributes, section: SectionType, indexPath: NSIndexPath, invalidationContext: UICollectionViewLayoutInvalidationContext?) -> Void)?
	
	public mutating func update(with section: SectionType, indexPath: NSIndexPath, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		if indexPath != layoutAttributes.indexPath {
			layoutAttributes = CollectionViewLayoutAttributes(forDecorationViewOfKind: elementKind, withIndexPath: indexPath)
		}
		guard let configure = configureDecoration else {
			return
		}
		configure(attributes: &layoutAttributes, section: section, indexPath: indexPath, invalidationContext: invalidationContext)
	}
	
}

public protocol DecorationAttributesProtocol {
	
	var frame: CGRect { get set }
	
	var zIndex: Int { get set }
	
	var isHidden: Bool { get set }
	
	var color: UIColor? { get set }
	
	var cornerRadius: CGFloat { get set }
	
	var borderColor: UIColor? { get set }
	
	var borderWidth: CGFloat { get set }
	
}

public struct BackgroundDecorationAttributes {
	
	public var color: UIColor?
	
	public var cornerRadius: CGFloat = 0
	
}
