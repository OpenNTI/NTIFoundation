//
//  DelegatingViewController.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 3/18/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

/// A view controller which notifies a delegate of API calls before sending them down its own hierarchy.
open class DelegatingViewController: UIViewController {
	
	open weak var delegate: ViewControllerDelegate?

    open override func viewDidLoad() {
		delegate?.viewControllerViewDidLoad(self)
        super.viewDidLoad()
    }
	
	open override func viewWillAppear(_ animated: Bool) {
		delegate?.viewControllerViewWillAppear(self)
		super.viewWillAppear(animated)
	}
	
	open override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
		delegate?.viewController(self, willTransitionTo: newCollection, with: coordinator)
		super.willTransition(to: newCollection, with: coordinator)
	}
	
	open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		delegate?.viewController(self, viewWillTransitionTo: size, with: coordinator)
		super.viewWillTransition(to: size, with: coordinator)
	}

}
