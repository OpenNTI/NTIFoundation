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
		super.init(frame: frame, style: .plain)
		dataSource = self
		delegate = self
		register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
	}
	
	public convenience init() {
		self.init(frame: CGRect.zero)
	}
	
	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	fileprivate var segments: [String] = []
	
	public var font: UIFont?
	
	public var textColor: UIColor?
	
	public var cellBackgroundColor: UIColor?
	
	public var cellSelectedBackgroundColor: UIColor?
	
	public override var intrinsicContentSize : CGSize {
		let superSize = super.intrinsicContentSize
		guard !segments.isEmpty else {
			return superSize
		}
		let h = rowHeight * CGFloat(segments.count)
		return CGSize(width: superSize.width, height: h)
	}
	
	// MARK: - SegmentedControlProtocol
	
	public var numberOfSegments: Int {
		return segments.count
	}
	
	public var selectedSegmentIndex: Int {
		get {
			return indexPathForSelectedRow?.row ?? UISegmentedControlNoSegment
		}
		set {
			guard newValue != selectedSegmentIndex else {
				return
			}
			let indexPath: IndexPath?
			if newValue == UISegmentedControlNoSegment {
				indexPath = nil
			} else {
				indexPath = IndexPath(row: newValue, section: 0)
			}
			selectRow(at: indexPath, animated: false, scrollPosition: .none)
		}
	}

	public weak var segmentedControlDelegate: SegmentedControlDelegate?
	
	public func removeAllSegments() {
		segments.removeAll(keepingCapacity: true)
		invalidateIntrinsicContentSize()
		reloadData()
	}
	
	public func insertSegmentWithTitle(_ title: String?, atIndex segment: Int, animated: Bool) {
		beginUpdates()
		segments.insert(title ?? "", at: segment)
		let indexPath = IndexPath(row: segment, section: 0)
		insertRows(at: [indexPath], with: .automatic)
		invalidateIntrinsicContentSize()
		endUpdates()
	}
	
	public func setSegments(with titles: [String], animated: Bool) {
		segments = titles
		invalidateIntrinsicContentSize()
		reloadData()
	}
	
	// MARK: - UITableViewDataSource
	
	public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return segments.count
	}
	
	public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = dequeueReusableCell(withIdentifier: cellIdentifier) else {
			preconditionFailure("We should have a cell.")
		}
		cell.textLabel?.text = segments[indexPath.row]
		return cell
	}
	
	// MARK: - UITableViewDelegate
	
	public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		segmentedControlDelegate?.segmentedControlDidChangeValue(self)
	}
	
	public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
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
