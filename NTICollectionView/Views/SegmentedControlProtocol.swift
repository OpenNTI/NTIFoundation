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
	
	func setSegments(with titles: [String], animated: Bool)
	
}

extension SegmentedControlProtocol {
	
	public func setSegments(with titles: [String], animated: Bool) {
		removeAllSegments()
		for (index, title) in titles.enumerate() {
			insertSegmentWithTitle(title, atIndex: index, animated: animated)
		}
	}
	
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

public struct GridSegmentedControlHeader: GridSupplementaryItemWrapper, SegmentedControlSupplementaryItem {
	
	public init() {
		gridSupplementaryItem = BasicGridSupplementaryItem(elementKind: UICollectionElementKindSectionHeader)
	}
	
	public init(segmentedControl: SegmentedControlProtocol) {
		self.init()
		self.segmentedControl = segmentedControl
	}
	
	public var gridSupplementaryItem: BasicGridSupplementaryItem
	
	public var segmentedControl: SegmentedControlProtocol!
	
	public var section: LayoutSection? {
		get {
			return gridSupplementaryItem.section
		}
		set {
			gridSupplementaryItem.section = newValue
		}
	}
	
	public var frame: CGRect {
		get {
			return gridSupplementaryItem.frame
		}
		set {
			gridSupplementaryItem.frame = newValue
		}
	}
	
	public var itemIndex: Int {
		get {
			return gridSupplementaryItem.itemIndex
		}
		set {
			gridSupplementaryItem.itemIndex = newValue
		}
	}
	
	public var indexPath: NSIndexPath {
		return gridSupplementaryItem.indexPath
	}
	
	public var layoutAttributes: UICollectionViewLayoutAttributes {
		return gridSupplementaryItem.layoutAttributes
	}
	
	public func isEqual(to other: SupplementaryItem) -> Bool {
		guard other.isEqual(to: gridSupplementaryItem) else {
			return false
		}
		
		guard let other = other as? GridSegmentedControlHeader else {
			return false
		}
		
		return segmentedControl === other.segmentedControl
	}
	
	
	
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
