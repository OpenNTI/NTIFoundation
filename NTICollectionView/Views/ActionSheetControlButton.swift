//
//  ActionSheetControlButton.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 3/25/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public final class ActionSheetControlButton: UIButton, SegmentedControlView, SegmentedControlDelegate {

	public override init(frame: CGRect) {
		super.init(frame: frame)
		actionSheetControl = ActionSheetControl(controlView: self)
		actionSheetControl.segmentedControlDelegate = self
	}
	
	public convenience init() {
		self.init(frame: CGRectZero)
	}
	
	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	public private(set) var actionSheetControl: ActionSheetControl!
	
	private func updateTitleText() {
		setTitle(makeTitleText(), forState: .Normal)
	}
	
	private func makeTitleText() -> String? {
		let title = selectedSegmentIndex != UISegmentedControlNoSegment
			? actionSheetControl.segments[selectedSegmentIndex]
			: ""
		return "\(title) ▼"
	}
	
	public var presentationDelegate: ActionSheetPresentationDelegate? {
		get {
			return actionSheetControl.presentationDelegate
		}
		set {
			actionSheetControl.presentationDelegate = newValue
		}
	}
	
	// MARK: - SegmentedControlView
	
	public var segmentedControlDelegate: SegmentedControlDelegate?
	
	public var selectedSegmentIndex: Int {
		get {
			return actionSheetControl.selectedSegmentIndex
		}
		set {
			actionSheetControl.selectedSegmentIndex = newValue
			updateTitleText()
		}
	}
	
	public func insertSegmentWithTitle(title: String?, atIndex segment: Int, animated: Bool) {
		actionSheetControl.insertSegmentWithTitle(title, atIndex: segment, animated: animated)
	}
	
	public func removeAllSegments() {
		actionSheetControl.removeAllSegments()
	}
	
	public var controlView: UIControl {
		return self
	}
	
	// MARK: - SegmentedControlDelegate
	
	public func segmentedControlDidChangeValue(segmentedControl: SegmentedControlProtocol) {
		updateTitleText()
		segmentedControlDelegate?.segmentedControlDidChangeValue(self)
	}

}
