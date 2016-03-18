//
//  ViewControllerDelegate.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 3/18/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public protocol ViewControllerDelegate: class {
	
	func viewControllerViewDidLoad(viewController: UIViewController)
	
	func viewControllerViewWillAppear(viewController: UIViewController)
	
	func viewController(viewController: UIViewController, willTransitionTo newCollection: UITraitCollection, with transitionCoordinator: UIViewControllerTransitionCoordinator)
	
	func viewController(viewController: UIViewController, viewWillTransitionTo size: CGSize, with transitionCoordinator: UIViewControllerTransitionCoordinator)
	
}

extension ViewControllerDelegate {
	
	public func viewControllerViewDidLoad(viewController: UIViewController) { }
	
	public func viewControllerViewWillAppear(viewController: UIViewController) { }
	
	public func viewController(viewController: UIViewController, willTransitionTo newCollection: UITraitCollection, with transitionCoordinator: UIViewControllerTransitionCoordinator) { }
	
	public func viewController(viewController: UIViewController, viewWillTransitionTo size: CGSize, with transitionCoordinator: UIViewControllerTransitionCoordinator) { }
	
}