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
		controlView.addTarget(self, action: #selector(ActionSheetControl.controlPressed(_:)), for: .touchUpInside)
	}
	
	deinit {
		controlView.removeTarget(self, action: #selector(ActionSheetControl.controlPressed(_:)), for: .touchUpInside)
	}
	
	public let controlView: UIControl
	
	public weak var presentationDelegate: ActionSheetPresentationDelegate?
	
	public var segments: [String] = []
	
	public var animatesPresentation = true
	
	@objc public func controlPressed(_ control: UIControl) {
		isActionSheetPresenting ? dismissActionSheet() : presentActionSheet()
	}
	
	fileprivate weak var actionSheetController: UIAlertController?
	
	fileprivate var isActionSheetPresenting: Bool {
		guard let actionSheet = actionSheetController else {
			return false
		}
		return actionSheet.presentingViewController != nil
	}
	
	fileprivate func presentActionSheet() {
		guard let presenter = presentationDelegate else {
			return
		}
		let actionSheet = makeActionSheetController()
		actionSheetController = actionSheet
		presenter.presentActionSheet(actionSheet)
	}
	
	fileprivate func dismissActionSheet() {
		presentationDelegate?.dismissActionSheet()
	}
	
	fileprivate func makeActionSheetController() -> UIAlertController {
		let sheetController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		
		configurePresentationController(of: sheetController)
		configureActions(of: sheetController)
		
		return sheetController
	}
	
	fileprivate func configurePresentationController(of sheetController: UIAlertController) {
		guard let presentationController = sheetController.popoverPresentationController else {
			return
		}
		presentationController.sourceView = controlView
		presentationController.sourceRect = makeActionSheetSourceRect()
	}
	
	fileprivate func makeActionSheetSourceRect() -> CGRect {
		let x = controlView.bounds.midX
		let y = controlView.bounds.midY
		return CGRect(x: x, y: y, width: 1, height: 1)
	}
	
	fileprivate func configureActions(of sheetController: UIAlertController) {
		for index in segments.indices {
			let action = makeAlertAction(for: index)
			sheetController.addAction(action)
		}
	}
	
	fileprivate func makeAlertAction(for index: Int) -> UIAlertAction {
		let title = segments[index]
		return UIAlertAction(title: title, style: .default) { [unowned self] alertAction in
			self.selectedSegmentIndex = index
			self.segmentedControlDelegate?.segmentedControlDidChangeValue(self)
		}
	}
	
	// MARK: - SegmentedControl
	
	public var numberOfSegments: Int {
		return segments.count
	}
	
	public var selectedSegmentIndex: Int = UISegmentedControlNoSegment
	
	public var userInteractionEnabled: Bool {
		get {
			return controlView.isUserInteractionEnabled
		}
		set {
			controlView.isUserInteractionEnabled = newValue
		}
	}
	
	public weak var segmentedControlDelegate: SegmentedControlDelegate?
	
	public func insertSegmentWithTitle(_ title: String?, atIndex segment: Int, animated: Bool) {
		segments.insert(title ?? "", at: segment)
	}
	
	public func removeAllSegments() {
		segments.removeAll(keepingCapacity: true)
	}
	
}

public protocol ActionSheetPresentationDelegate: class {
	
	func presentActionSheet(_ actionSheet: UIAlertController)
	
	func dismissActionSheet()
	
}
