//
//  ViewControllerDelegate.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 3/18/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public protocol ViewControllerDelegate: class {
	
	func viewControllerViewDidLoad(_ viewController: UIViewController)
	
	func viewControllerViewWillAppear(_ viewController: UIViewController)
	
	func viewControllerViewDidDisappear(_ viewController: UIViewController)
	
	func viewController(_ viewController: UIViewController, willTransitionTo newCollection: UITraitCollection, with transitionCoordinator: UIViewControllerTransitionCoordinator)
	
	func viewController(_ viewController: UIViewController, viewWillTransitionTo size: CGSize, with transitionCoordinator: UIViewControllerTransitionCoordinator)
	
}

extension ViewControllerDelegate {
	
	public func viewControllerViewDidLoad(_ viewController: UIViewController) { }
	
	public func viewControllerViewWillAppear(_ viewController: UIViewController) { }
	
	public func viewControllerViewDidDisappear(_ viewController: UIViewController) { }
	
	public func viewController(_ viewController: UIViewController, willTransitionTo newCollection: UITraitCollection, with transitionCoordinator: UIViewControllerTransitionCoordinator) { }
	
	public func viewController(_ viewController: UIViewController, viewWillTransitionTo size: CGSize, with transitionCoordinator: UIViewControllerTransitionCoordinator) { }
	
}
