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
	
	var numberOfSegments: Int { get }
	
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
	
	public var resizesSegmentWidthsByContent = false {
		didSet {
			guard resizesSegmentWidthsByContent && !oldValue else { return }
			resizeSegmentWidthsByContent()
		}
	}
	
	/// The divider image used for the right edge of the rightmost segment.
	public var rightDividerImage: UIImage? {
		didSet {
			guard let rightDividerImage = rightDividerImage else {
				rightDividerLayer = nil
				return
			}
			
			guard rightDividerImage !== oldValue else { return }
			
			if rightDividerLayer == nil {
				rightDividerLayer = CALayer()
			}
			
			rightDividerLayer?.contents = rightDividerImage.CGImage
		}
	}
	
	/// The layer used to draw the right divider, if any.
	private var rightDividerLayer: CALayer? {
		didSet {
			guard rightDividerLayer !== oldValue else { return }
			
			if let oldLayer = oldValue {
				oldLayer.removeFromSuperlayer()
			}
			
			if let newLayer = rightDividerLayer {
				layer.addSublayer(newLayer)
			}
			
			setNeedsLayout()
		}
	}
	
	public weak var segmentedControlDelegate: SegmentedControlDelegate?
	
	@objc public func segmentedControlDidChangeValue() {
		setNeedsLayout()
		segmentedControlDelegate?.segmentedControlDidChangeValue(self)
	}
	
	public var controlView: UIControl {
		return self
	}
	
	public func prepareForReuse() {
		segmentedControlDelegate = nil
	}
	
	public override func setTitle(title: String?, forSegmentAtIndex segment: Int) {
		super.setTitle(title, forSegmentAtIndex: segment)
		
		if resizesSegmentWidthsByContent {
			resizeWidthOfSegmentByContent(atIndex: segment)
		}
	}
	
	public override func insertSegmentWithTitle(title: String?, atIndex segment: Int, animated: Bool) {
		super.insertSegmentWithTitle(title, atIndex: segment, animated: animated)
		
		if resizesSegmentWidthsByContent {
			resizeWidthOfSegmentByContent(atIndex: segment)
		}
	}
	
	public override func layoutSubviews() {
		super.layoutSubviews()
		
		layoutRightDivider()
	}
	
	private func layoutRightDivider() {
		guard let rightDividerLayer = rightDividerLayer else { return }
		
		// +3 makes the divider line up with the selected segment
		let dividerX: CGFloat = (0..<numberOfSegments).reduce(bounds.minX + 3) {
			$0 + self.widthForSegmentAtIndex($1)
		}
		
		rightDividerLayer.frame = numberOfSegments > 0 ? CGRect(x: dividerX, y: bounds.minY, width: SegmentedControl.hairline, height: bounds.height) : .zero
	}
	
	private static let hairline: CGFloat = 1.0 / UIScreen.mainScreen().scale
}

extension UISegmentedControl {
	
	public func resizeSegmentWidthsByContent() {
		for idx in 0..<numberOfSegments {
			resizeWidthOfSegmentByContent(atIndex: idx)
		}
	}
	
	public func resizeWidthOfSegmentByContent(atIndex index: Int) {
		guard let title = titleForSegmentAtIndex(index) else { return }
		
		let horizontalPadding: CGFloat = 40
		
		let attributes: [String: AnyObject] = (titleTextAttributesForState(state) as? [String: AnyObject]) ?? [:]
		let attrTitle = NSAttributedString(string: title, attributes: attributes)
		let rect = attrTitle.boundingRectWithSize(bounds.size, options: [], context: nil)
		let width = ceil(rect.width) + horizontalPadding
		setWidth(width, forSegmentAtIndex: index)
		
		setNeedsLayout()
	}
}
