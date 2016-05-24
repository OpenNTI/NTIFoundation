//
//  ActionSheetControl.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 3/25/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public final class ActionSheetControl: SegmentedControlView {

	public init(controlView: UIControl) {
		self.controlView = controlView
		controlView.addTarget(self, action: #selector(ActionSheetControl.controlPressed(_:)), forControlEvents: .TouchUpInside)
	}
	
	deinit {
		controlView.removeTarget(self, action: #selector(ActionSheetControl.controlPressed(_:)), forControlEvents: .TouchUpInside)
	}
	
	public let controlView: UIControl
	
	public weak var presentationDelegate: ActionSheetPresentationDelegate?
	
	public var segments: [String] = []
	
	public var animatesPresentation = true
	
	@objc public func controlPressed(control: UIControl) {
		isActionSheetPresenting ? dismissActionSheet() : presentActionSheet()
	}
	
	private weak var actionSheetController: UIAlertController?
	
	private var isActionSheetPresenting: Bool {
		guard let actionSheet = actionSheetController else {
			return false
		}
		return actionSheet.presentingViewController != nil
	}
	
	private func presentActionSheet() {
		guard let presenter = presentationDelegate else {
			return
		}
		let actionSheet = makeActionSheetController()
		actionSheetController = actionSheet
		presenter.presentActionSheet(actionSheet)
	}
	
	private func dismissActionSheet() {
		presentationDelegate?.dismissActionSheet()
	}
	
	private func makeActionSheetController() -> UIAlertController {
		let sheetController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
		
		configurePresentationController(of: sheetController)
		configureActions(of: sheetController)
		
		return sheetController
	}
	
	private func configurePresentationController(of sheetController: UIAlertController) {
		guard let presentationController = sheetController.popoverPresentationController else {
			return
		}
		presentationController.sourceView = controlView
		presentationController.sourceRect = makeActionSheetSourceRect()
	}
	
	private func makeActionSheetSourceRect() -> CGRect {
		let x = controlView.bounds.midX
		let y = controlView.bounds.midY
		return CGRect(x: x, y: y, width: 1, height: 1)
	}
	
	private func configureActions(of sheetController: UIAlertController) {
		for index in segments.indices {
			let action = makeAlertAction(for: index)
			sheetController.addAction(action)
		}
	}
	
	private func makeAlertAction(for index: Int) -> UIAlertAction {
		let title = segments[index]
		return UIAlertAction(title: title, style: .Default) { [unowned self] alertAction in
			self.selectedSegmentIndex = index
			self.segmentedControlDelegate?.segmentedControlDidChangeValue(self)
		}
	}
	
	// MARK: - SegmentedControl
	
	public var selectedSegmentIndex: Int = UISegmentedControlNoSegment
	
	public var userInteractionEnabled: Bool {
		get {
			return controlView.userInteractionEnabled
		}
		set {
			controlView.userInteractionEnabled = newValue
		}
	}
	
	public weak var segmentedControlDelegate: SegmentedControlDelegate?
	
	public func insertSegmentWithTitle(title: String?, atIndex segment: Int, animated: Bool) {
		segments.insert(title ?? "", atIndex: segment)
	}
	
	public func removeAllSegments() {
		segments.removeAll(keepCapacity: true)
	}
	
}

public protocol ActionSheetPresentationDelegate: class {
	
	func presentActionSheet(actionSheet: UIAlertController)
	
	func dismissActionSheet()
	
}
