//
//  ViewControllerDelegate.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 3/18/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public protocol ViewControllerDelegate {
	
	func viewController(viewController: UIViewController, willTransitionTo newCollection: UITraitCollection, with transitionCoordinator: UIViewControllerTransitionCoordinator)
	
	func viewController(viewController: UIViewController, willTransitionTo size: CGSize, with transitionCoordinator: UIViewControllerTransitionCoordinator)
	
}