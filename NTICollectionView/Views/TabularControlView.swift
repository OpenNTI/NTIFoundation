//
//  TabularControlView.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 3/24/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

private let cellIdentifier = "cell"

public final class TabularControlView: UITableView, UITableViewDataSource, UITableViewDelegate, SegmentedControlProtocol {
	
	public init(frame: CGRect) {
		super.init(frame: frame, style: .Plain)
		dataSource = self
		delegate = self
		registerClass(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
	}
	
	public convenience init() {
		self.init(frame: CGRectZero)
	}
	
	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	private var segments: [String] = []
	
	public var font: UIFont?
	
	public var textColor: UIColor?
	
	public var cellBackgroundColor: UIColor?
	
	public var cellSelectedBackgroundColor: UIColor?
	
	public override func intrinsicContentSize() -> CGSize {
		let superSize = super.intrinsicContentSize()
		guard !segments.isEmpty else {
			return superSize
		}
		let h = rowHeight * CGFloat(segments.count)
		return CGSize(width: superSize.width, height: h)
	}
	
	// MARK: - SegmentedControlProtocol
	
	public var selectedSegmentIndex: Int {
		get {
			return indexPathForSelectedRow?.row ?? UISegmentedControlNoSegment
		}
		set {
			guard newValue != selectedSegmentIndex else {
				return
			}
			let indexPath: NSIndexPath?
			if newValue == UISegmentedControlNoSegment {
				indexPath = nil
			} else {
				indexPath = NSIndexPath(forRow: newValue, inSection: 0)
			}
			selectRowAtIndexPath(indexPath, animated: false, scrollPosition: .None)
		}
	}

	public weak var segmentedControlDelegate: SegmentedControlDelegate?
	
	public func removeAllSegments() {
		segments.removeAll(keepCapacity: true)
		invalidateIntrinsicContentSize()
		reloadData()
	}
	
	public func insertSegmentWithTitle(title: String?, atIndex segment: Int, animated: Bool) {
		beginUpdates()
		segments.insert(title ?? "", atIndex: segment)
		let indexPath = NSIndexPath(forRow: segment, inSection: 0)
		insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
		invalidateIntrinsicContentSize()
		endUpdates()
	}
	
	public func setSegments(with titles: [String], animated: Bool) {
		segments = titles
		invalidateIntrinsicContentSize()
		reloadData()
	}
	
	// MARK: - UITableViewDataSource
	
	public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return segments.count
	}
	
	public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		guard let cell = dequeueReusableCellWithIdentifier(cellIdentifier) else {
			preconditionFailure("We should have a cell.")
		}
		cell.textLabel?.text = segments[indexPath.row]
		return cell
	}
	
	// MARK: - UITableViewDelegate
	
	public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		segmentedControlDelegate?.segmentedControlDidChangeValue(self)
	}
	
	public func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
		if let font = self.font {
			cell.textLabel?.font = font
		}
		
		if let textColor = self.textColor {
			cell.textLabel?.textColor = textColor
		}
		
		cell.backgroundColor = cellBackgroundColor
		
		if let selectedBackgroundColor = cellSelectedBackgroundColor {
			let selectedBackgroundView = UIView()
			selectedBackgroundView.backgroundColor = selectedBackgroundColor
			cell.selectedBackgroundView = selectedBackgroundView
		}
	}

}
