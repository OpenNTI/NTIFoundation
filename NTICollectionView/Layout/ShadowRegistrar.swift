//
//  ShadowRegistrar.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/24/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public typealias ElementKind = String
public typealias ReuseIdentifier = String

public protocol ShadowRegistrarVending: NSObjectProtocol {
	
	var shadowRegistrar: ShadowRegistrar { get }
	
}

public class ShadowRegistrar: NSObject {

	private var cellRegistry: [ReuseIdentifier: ShadowRegistration] = [:]
	private var supplementaryViewRegistry: [ElementKind: [ReuseIdentifier: ShadowRegistration]] = [:]
	
	public func registerClass(cellClass: UICollectionReusableView.Type, forCellWith identifier: ReuseIdentifier) {
		let shadowRegistration = shadowRegistrationForCell(with: identifier)
		shadowRegistration.viewClass = cellClass
		shadowRegistration.nib = nil
		shadowRegistration.reusableView = nil
	}
	
	public func registerNib(nib: UINib, forCellWith identifier: ReuseIdentifier) {
		let shadowRegistration = shadowRegistrationForCell(with: identifier)
		shadowRegistration.viewClass = nil
		shadowRegistration.nib = nib
		shadowRegistration.reusableView = nil
	}
	
	public func registerClass(viewClass: UICollectionReusableView.Type, forSupplementaryViewOf elementKind: ElementKind, with identifier: ReuseIdentifier) {
		let shadowRegistration = shadowRegistrationForSupplementaryView(of: elementKind, with: identifier)
		shadowRegistration.viewClass = viewClass
		shadowRegistration.nib = nil
		shadowRegistration.reusableView = nil
	}
	
	private func shadowRegistrationForCell(with identifier: ReuseIdentifier) -> ShadowRegistration {
		var shadowRegistration = cellRegistry[identifier]
		if shadowRegistration == nil {
			shadowRegistration = ShadowRegistration()
			cellRegistry[identifier] = shadowRegistration
		}
		return shadowRegistration!
	}
	
	public func registerNib(nib: UINib, forSupplementaryViewOf elementKind: ElementKind, with identifier: ReuseIdentifier) {
		let shadowRegistration = shadowRegistrationForSupplementaryView(of: elementKind, with: identifier)
		shadowRegistration.viewClass = nil
		shadowRegistration.nib = nib
		shadowRegistration.reusableView = nil
	}
	
	private func shadowRegistrationForSupplementaryView(of elementKind: ElementKind, with identifier: ReuseIdentifier) -> ShadowRegistration {
		var elementKindRegistry = elementKindRegistryForSupplementaryViews(of: elementKind)
		var shadowRegistration = elementKindRegistry[identifier]
		if shadowRegistration == nil {
			shadowRegistration = ShadowRegistration()
			elementKindRegistry[identifier] = shadowRegistration
			supplementaryViewRegistry[elementKind] = elementKindRegistry
		}
		return shadowRegistration!
	}
	
	private func elementKindRegistryForSupplementaryViews(of elementKind: ElementKind) -> [ReuseIdentifier: ShadowRegistration] {
		var elementKindRegistry = supplementaryViewRegistry[elementKind]
		if elementKindRegistry == nil {
			elementKindRegistry = [:]
			supplementaryViewRegistry[elementKind] = elementKindRegistry
		}
		return elementKindRegistry!
	}
	
	public func dequeReusableCell(with identifier: ReuseIdentifier, `for` indexPath: NSIndexPath, collectionView: UICollectionView) -> UICollectionReusableView {
		let layout = collectionView.collectionViewLayout
		let layoutAttributes = layout.layoutAttributesForItemAtIndexPath(indexPath)!
		let shadowRegistration = shadowRegistrationForCell(with: identifier)
		return dequeReusableView(`for`: shadowRegistration, identifier: identifier, layoutAttributes: layoutAttributes, collectionView: collectionView)
	}
	
	public func dequeReusableSupplementaryView(of elementKind: ElementKind, with identifier: ReuseIdentifier, `for` indexPath: NSIndexPath, collectionView: UICollectionView) -> UICollectionReusableView {
		let layout = collectionView.collectionViewLayout
		let layoutAttributes = layout.layoutAttributesForSupplementaryViewOfKind(elementKind, atIndexPath: indexPath)!
		let shadowRegistration = shadowRegistrationForSupplementaryView(of: elementKind, with: identifier)
		return dequeReusableView(`for`: shadowRegistration, identifier: identifier, layoutAttributes: layoutAttributes, collectionView: collectionView)
	}
	
	private func dequeReusableView(`for` shadowRegistration: ShadowRegistration, identifier: ReuseIdentifier, layoutAttributes: UICollectionViewLayoutAttributes, collectionView: UICollectionView) -> UICollectionReusableView {
		var view: UICollectionReusableView! = shadowRegistration.reusableView
		
		if view != nil {
			view.prepareForReuse()
		} else if let viewClass = shadowRegistration.viewClass {
			var frame = layoutAttributes.frame
			frame.size = layoutAttributes.size
			view = viewClass.init(frame: frame)
		} else if let nib = shadowRegistration.nib {
			let topLevelObjects = nib.instantiateWithOwner(nil, options: nil)
			guard let nibView = topLevelObjects.first as? UICollectionReusableView else {
				preconditionFailure("Invalid nib registered for identifier (\(identifier)) - nib must contain exactly one top level object which must be a UICollectionReusableView instance")
			}
			view = nibView
			let viewReuseIdentifier = view.reuseIdentifier
			guard (viewReuseIdentifier?.characters.count ?? 0) == 0 || viewReuseIdentifier == identifier else {
				preconditionFailure("View reuse identifier in nib (\(viewReuseIdentifier)) does not match the identifier used to register the ")
			}
		}
		
		shadowRegistration.reusableView = view
		view.autoresizingMask = .None
		view.translatesAutoresizingMaskIntoConstraints = true
		
		UIView.performWithoutAnimation {
			collectionView.addSubview(view)
			self.apply(layoutAttributes, to: view)
		}
		
		return view
	}
	
	private func apply(layoutAttributes: UICollectionViewLayoutAttributes, to view: UICollectionReusableView) {
		view.center = layoutAttributes.center
		view.bounds.size = layoutAttributes.size
		view.alpha = layoutAttributes.alpha
		view.layer.transform = layoutAttributes.transform3D
		view.applyLayoutAttributes(layoutAttributes)
	}
	
}

// TODO: Convert to struct when there are tests
class ShadowRegistration: NSObject {
	
	var reusableView: UICollectionReusableView?
	
	var nib: UINib?
	
	var viewClass: UICollectionReusableView.Type?
	
}
