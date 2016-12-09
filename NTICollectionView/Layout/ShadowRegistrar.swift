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

open class ShadowRegistrar: NSObject {

	fileprivate var cellRegistry: [ReuseIdentifier: ShadowRegistration] = [:]
	fileprivate var supplementaryViewRegistry: [ElementKind: [ReuseIdentifier: ShadowRegistration]] = [:]
	
	open func registerClass(_ cellClass: UICollectionReusableView.Type, forCellWith identifier: ReuseIdentifier) {
		let shadowRegistration = shadowRegistrationForCell(with: identifier)
		shadowRegistration.viewClass = cellClass
		shadowRegistration.nib = nil
		shadowRegistration.reusableView = nil
	}
	
	open func registerNib(_ nib: UINib, forCellWith identifier: ReuseIdentifier) {
		let shadowRegistration = shadowRegistrationForCell(with: identifier)
		shadowRegistration.viewClass = nil
		shadowRegistration.nib = nib
		shadowRegistration.reusableView = nil
	}
	
	open func registerClass(_ viewClass: UICollectionReusableView.Type, forSupplementaryViewOf elementKind: ElementKind, with identifier: ReuseIdentifier) {
		let shadowRegistration = shadowRegistrationForSupplementaryView(of: elementKind, with: identifier)
		shadowRegistration.viewClass = viewClass
		shadowRegistration.nib = nil
		shadowRegistration.reusableView = nil
	}
	
	fileprivate func shadowRegistrationForCell(with identifier: ReuseIdentifier) -> ShadowRegistration {
		var shadowRegistration = cellRegistry[identifier]
		if shadowRegistration == nil {
			shadowRegistration = ShadowRegistration()
			cellRegistry[identifier] = shadowRegistration
		}
		return shadowRegistration!
	}
	
	open func registerNib(_ nib: UINib, forSupplementaryViewOf elementKind: ElementKind, with identifier: ReuseIdentifier) {
		let shadowRegistration = shadowRegistrationForSupplementaryView(of: elementKind, with: identifier)
		shadowRegistration.viewClass = nil
		shadowRegistration.nib = nib
		shadowRegistration.reusableView = nil
	}
	
	fileprivate func shadowRegistrationForSupplementaryView(of elementKind: ElementKind, with identifier: ReuseIdentifier) -> ShadowRegistration {
		var elementKindRegistry = elementKindRegistryForSupplementaryViews(of: elementKind)
		var shadowRegistration = elementKindRegistry[identifier]
		if shadowRegistration == nil {
			shadowRegistration = ShadowRegistration()
			elementKindRegistry[identifier] = shadowRegistration
			supplementaryViewRegistry[elementKind] = elementKindRegistry
		}
		return shadowRegistration!
	}
	
	fileprivate func elementKindRegistryForSupplementaryViews(of elementKind: ElementKind) -> [ReuseIdentifier: ShadowRegistration] {
		var elementKindRegistry = supplementaryViewRegistry[elementKind]
		if elementKindRegistry == nil {
			elementKindRegistry = [:]
			supplementaryViewRegistry[elementKind] = elementKindRegistry
		}
		return elementKindRegistry!
	}
	
	open func dequeReusableCell(with identifier: ReuseIdentifier, for indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionReusableView {
		let layout = collectionView.collectionViewLayout
		let layoutAttributes = layout.layoutAttributesForItem(at: indexPath)!
		let shadowRegistration = shadowRegistrationForCell(with: identifier)
		return dequeReusableView(for: shadowRegistration, identifier: identifier, layoutAttributes: layoutAttributes, collectionView: collectionView)
	}
	
	open func dequeReusableSupplementaryView(of elementKind: ElementKind, with identifier: ReuseIdentifier, for indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionReusableView {
		let layout = collectionView.collectionViewLayout
		let layoutAttributes = layout.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath)!
		let shadowRegistration = shadowRegistrationForSupplementaryView(of: elementKind, with: identifier)
		return dequeReusableView(for: shadowRegistration, identifier: identifier, layoutAttributes: layoutAttributes, collectionView: collectionView)
	}
	
	fileprivate func dequeReusableView(for shadowRegistration: ShadowRegistration, identifier: ReuseIdentifier, layoutAttributes: UICollectionViewLayoutAttributes, collectionView: UICollectionView) -> UICollectionReusableView {
		var view = shadowRegistration.reusableView
		
		if view != nil {
			view?.prepareForReuse()
		} else if let viewClass = shadowRegistration.viewClass {
			var frame = layoutAttributes.frame
			frame.size = layoutAttributes.size
			view = viewClass.init(frame: frame)
		} else if let nib = shadowRegistration.nib {
			let topLevelObjects = nib.instantiate(withOwner: nil, options: nil)
			guard let nibView = topLevelObjects.first as? UICollectionReusableView else {
				preconditionFailure("Invalid nib registered for identifier (\(identifier)) - nib must contain exactly one top level object which must be a UICollectionReusableView instance")
			}
			view = nibView
			let viewReuseIdentifier = view?.reuseIdentifier
			guard (viewReuseIdentifier?.characters.count ?? 0) == 0 || viewReuseIdentifier == identifier else {
				preconditionFailure("View reuse identifier in nib (\(viewReuseIdentifier)) does not match the identifier used to register the ")
			}
		}
		
		guard let reusableView = view else {
			preconditionFailure("We must have a view by this point; identifier = \(identifier)")
		}
		
		shadowRegistration.reusableView = reusableView
		reusableView.autoresizingMask = UIViewAutoresizing()
		reusableView.translatesAutoresizingMaskIntoConstraints = true
		
		UIView.performWithoutAnimation {
			collectionView.addSubview(reusableView)
			self.apply(layoutAttributes, to: reusableView)
		}
		
		return reusableView
	}
	
	fileprivate func apply(_ layoutAttributes: UICollectionViewLayoutAttributes, to view: UICollectionReusableView) {
		view.center = layoutAttributes.center
		view.bounds.size = layoutAttributes.size
		view.alpha = layoutAttributes.alpha
		view.layer.transform = layoutAttributes.transform3D
		view.apply(layoutAttributes)
	}
	
}

// TODO: Convert to struct when there are tests
class ShadowRegistration: NSObject {
	
	var reusableView: UICollectionReusableView?
	
	var nib: UINib?
	
	var viewClass: UICollectionReusableView.Type?
	
}
