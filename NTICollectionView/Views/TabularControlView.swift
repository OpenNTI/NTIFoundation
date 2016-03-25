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
		reloadData()
	}
	
	public func insertSegmentWithTitle(title: String?, atIndex segment: Int, animated: Bool) {
		beginUpdates()
		segments.insert(title ?? "", atIndex: segment)
		let indexPath = NSIndexPath(forRow: segment, inSection: 0)
		insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
		endUpdates()
	}
	
	public func setSegments(with titles: [String], animated: Bool) {
		segments = titles
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
	}

}
