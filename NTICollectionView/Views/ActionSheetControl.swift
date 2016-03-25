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
	
	/// The view controller which will present the action sheet.
	public var viewController: UIViewController?
	
	public var segments: [String] = []
	
	public var animatesPresentation = true
	
	@objc public func controlPressed(control: UIControl) {
		isActionSheetPresenting ? presentActionSheet() : dismissActionSheet()
	}
	
	private weak var actionSheetController: UIAlertController?
	
	private var isActionSheetPresenting: Bool {
		guard let actionSheet = actionSheetController else {
			return false
		}
		return actionSheet.presentingViewController != nil
	}
	
	private func presentActionSheet() {
		presentActionSheet()
	}
	
	private func dismissActionSheet() {
		viewController?.dismissViewControllerAnimated(animatesPresentation, completion: nil)
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
		let width: CGFloat = 2
		let height = controlView.bounds.height
		let center = controlView.center
		let x = center.x - width / 2
		let y = center.y - height / 2
		return CGRect(x: x, y: y, width: width, height: height)
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
