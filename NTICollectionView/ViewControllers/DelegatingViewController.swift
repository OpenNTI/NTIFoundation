//
//  DelegatingViewController.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 3/18/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

/// A view controller which notifies a delegate of API calls before sending them down its own hierarchy.
public class DelegatingViewController: UIViewController {
	
	public weak var delegate: ViewControllerDelegate?

    public override func viewDidLoad() {
		delegate?.viewControllerViewDidLoad(self)
        super.viewDidLoad()
    }
	
	public override func viewWillAppear(animated: Bool) {
		delegate?.viewControllerViewWillAppear(self)
		super.viewWillAppear(animated)
	}
	
	public override func willTransitionToTraitCollection(newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
		delegate?.viewController(self, willTransitionTo: newCollection, with: coordinator)
		super.willTransitionToTraitCollection(newCollection, withTransitionCoordinator: coordinator)
	}
	
	public override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
		delegate?.viewController(self, viewWillTransitionTo: size, with: coordinator)
		super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
	}

}
