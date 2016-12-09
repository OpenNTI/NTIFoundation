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
	
	func insertSegmentWithTitle(_ title: String?, atIndex segment: Int, animated: Bool)
	
	func setSegments(with titles: [String], animated: Bool)
	
}

extension SegmentedControlProtocol {
	
	public func setSegments(with titles: [String], animated: Bool) {
		removeAllSegments()
		for (index, title) in titles.enumerated() {
			insertSegmentWithTitle(title, atIndex: index, animated: animated)
		}
	}
	
}

public protocol SegmentedControlDelegate: class {
	
	func segmentedControlDidChangeValue(_ segmentedControl: SegmentedControlProtocol)
	
}

public protocol SegmentedControlView: SegmentedControlProtocol {
	
	var controlView: UIControl { get }
	
}

public protocol SegmentedControlSupplementaryItem: SupplementaryItem {
	
	var segmentedControl: SegmentedControlProtocol! { get }
	
}

open class SegmentedControl: UISegmentedControl, SegmentedControlView {
	
	deinit {
		removeTarget(self, action: #selector(SegmentedControl.segmentedControlDidChangeValue), for: .valueChanged)
	}
	
	public override init(frame: CGRect) {
		super.init(frame: frame)
		registerSelfAsTarget()
	}
	
	public override init(items: [Any]?) {
		super.init(items: items)
	}

	public required init?(coder aDecoder: NSCoder) {
	    super.init(coder: aDecoder)
		registerSelfAsTarget()
	}
	
	fileprivate func registerSelfAsTarget() {
		addTarget(self, action: #selector(SegmentedControl.segmentedControlDidChangeValue), for: .valueChanged)
	}
	
	open var resizesSegmentWidthsByContent = false {
		didSet {
			guard resizesSegmentWidthsByContent && !oldValue else { return }
			resizeSegmentWidthsByContent()
		}
	}
	
	/// The divider image used for the right edge of the rightmost segment.
	open var rightDividerImage: UIImage? {
		didSet {
			guard let rightDividerImage = rightDividerImage else {
				rightDividerLayer = nil
				return
			}
			
			guard rightDividerImage !== oldValue else { return }
			
			if rightDividerLayer == nil {
				rightDividerLayer = CALayer()
			}
			
			rightDividerLayer?.contents = rightDividerImage.cgImage
		}
	}
	
	/// The layer used to draw the right divider, if any.
	fileprivate var rightDividerLayer: CALayer? {
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
	
	open weak var segmentedControlDelegate: SegmentedControlDelegate?
	
	@objc open func segmentedControlDidChangeValue() {
		setNeedsLayout()
		segmentedControlDelegate?.segmentedControlDidChangeValue(self)
	}
	
	open var controlView: UIControl {
		return self
	}
	
	open func prepareForReuse() {
		segmentedControlDelegate = nil
	}
	
	open override func setTitle(_ title: String?, forSegmentAt segment: Int) {
		super.setTitle(title, forSegmentAt: segment)
		
		if resizesSegmentWidthsByContent {
			resizeWidthOfSegmentByContent(atIndex: segment)
		}
	}
	
	open override func insertSegment(withTitle title: String?, at segment: Int, animated: Bool) {
		super.insertSegment(withTitle: title, at: segment, animated: animated)
		
		if resizesSegmentWidthsByContent {
			resizeWidthOfSegmentByContent(atIndex: segment)
		}
	}
	
	open override func layoutSubviews() {
		super.layoutSubviews()
		
		layoutRightDivider()
	}
	
	fileprivate func layoutRightDivider() {
		guard let rightDividerLayer = rightDividerLayer else { return }
		
		// +3 makes the divider line up with the selected segment
		let dividerX: CGFloat = (0..<numberOfSegments).reduce(bounds.minX + 3) {
			$0 + self.widthForSegment(at: $1)
		}
		
		rightDividerLayer.frame = numberOfSegments > 0 ? CGRect(x: dividerX, y: bounds.minY, width: SegmentedControl.hairline, height: bounds.height) : .zero
	}
	
	fileprivate static let hairline: CGFloat = 1.0 / UIScreen.main.scale
}

extension UISegmentedControl {
	
	public func resizeSegmentWidthsByContent() {
		for idx in 0..<numberOfSegments {
			resizeWidthOfSegmentByContent(atIndex: idx)
		}
	}
	
	public func resizeWidthOfSegmentByContent(atIndex index: Int) {
		guard let title = titleForSegment(at: index) else { return }
		
		let horizontalPadding: CGFloat = 40
		
		let attributes: [String: AnyObject] = (titleTextAttributes(for: state) as? [String: AnyObject]) ?? [:]
		let attrTitle = NSAttributedString(string: title, attributes: attributes)
		let rect = attrTitle.boundingRect(with: bounds.size, options: [], context: nil)
		let width = ceil(rect.width) + horizontalPadding
		setWidth(width, forSegmentAt: index)
		
		setNeedsLayout()
	}
}
