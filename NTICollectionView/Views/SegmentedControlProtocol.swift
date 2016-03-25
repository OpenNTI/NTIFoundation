//
//  SegmentedControlProtocol.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/26/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public protocol SegmentedControlProtocol: class {
	
	var selectedSegmentIndex: Int { get set }
	
	var userInteractionEnabled: Bool { get set }
	
	weak var segmentedControlDelegate: SegmentedControlDelegate? { get set }
	
	func removeAllSegments()
	
	func insertSegmentWithTitle(title: String?, atIndex segment: Int, animated: Bool)
	
}

public protocol SegmentedControlDelegate: class {
	
	func segmentedControlDidChangeValue(segmentedControl: SegmentedControlProtocol)
	
}

public protocol SegmentedControlView: SegmentedControlProtocol {
	
	var controlView: UIControl { get }
	
}

public protocol SegmentedControlSupplementaryItem: SupplementaryItem {
	
	var segmentedControl: SegmentedControlProtocol! { get }
	
}

public class GridSegmentedControlHeader: BasicGridSupplementaryItem, SegmentedControlSupplementaryItem {
	
	public init() {
		super.init(elementKind: UICollectionElementKindSectionHeader)
	}
	
	public convenience init(segmentedControl: SegmentedControlProtocol) {
		self.init()
		self.segmentedControl = segmentedControl
	}
	
	public var segmentedControl: SegmentedControlProtocol!
	
}

public class SegmentedControl: UISegmentedControl, SegmentedControlView {
	
	deinit {
		removeTarget(self, action: #selector(SegmentedControl.segmentedControlDidChangeValue), forControlEvents: .ValueChanged)
	}
	
	public override init(frame: CGRect) {
		super.init(frame: frame)
		registerSelfAsTarget()
	}
	
	public override init(items: [AnyObject]?) {
		super.init(items: items)
	}

	public required init?(coder aDecoder: NSCoder) {
	    super.init(coder: aDecoder)
		registerSelfAsTarget()
	}
	
	private func registerSelfAsTarget() {
		addTarget(self, action: #selector(SegmentedControl.segmentedControlDidChangeValue), forControlEvents: .ValueChanged)
	}
	
	public weak var segmentedControlDelegate: SegmentedControlDelegate?
	
	@objc public func segmentedControlDidChangeValue() {
		segmentedControlDelegate?.segmentedControlDidChangeValue(self)
	}
	
	public var controlView: UIControl {
		return self
	}
	
	public func prepareForReuse() {
		segmentedControlDelegate = nil
	}
	
}
