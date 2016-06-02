//
//  PinnableHeaderView.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 6/2/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

/// A base class for headers that respond to being pinned to the top of the collection view.
public class PinnableHeaderView: CollectionSupplementaryView {

	/// Default	`layoutMargins` values preferred by `self`.
	public var defaultLayoutMargins = UIEdgeInsets(top: 8, left: 15, bottom: 8, right: 15)
	
	/// Property updated by the collection view layout when the header is pinned to the top of the collection view.
	public var isPinned: Bool {
		get { return _isPinned }
		set {
			let duration = (newValue == _isPinned ? 0 : 0.25)
			
			UIView.animateWithDuration(duration) { 
				if newValue {
					self.backgroundColor = self.pinnedBackgroundColor
				}
				else {
					self.backgroundColor = self.normalBackgroundColor
				}
				
				self._isPinned = newValue
				
				let separatorColor = self.pinnedSeparatorColor ?? self.separatorColor
				self.separatorView.backgroundColor = separatorColor
			}
		}
	}
	
	private var _isPinned = false
	
	/// Whether `self` displays a separator beneath its text.
	public var showsSeparator = false {
		didSet { separatorView.hidden = !showsSeparator }
	}
	
	/// The color of the separator.
	public var separatorColor: UIColor? {
		didSet {
			if isPinned {
				separatorView.backgroundColor = pinnedSeparatorColor
			}
		}
	}
	
	/// The color of the separator when	`self` is pinned.
	///
	/// If `nil`, the separator will not change color when pinned.
	public var pinnedSeparatorColor: UIColor? {
		didSet {
			if isPinned {
				separatorView.backgroundColor = pinnedSeparatorColor
			}
		}
	}
	
	/// The background color to display when `self` is been pinned. 
	///
	/// A `nil` value indicates the header should blend with navigation bars.
	public var pinnedBackgroundColor: UIColor?
	
	let separatorView = UIView()
	
	public override init(frame: CGRect) {
		super.init(frame: frame)
		
		separatorView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(separatorView)
		
		let views = ["separator": separatorView]
		var constraints = [NSLayoutConstraint]()
		
		constraints += NSLayoutConstraint.constraintsWithVisualFormat("H:|[separator]|", options: [], metrics: nil, views: views)
		constraints.append(NSLayoutConstraint(item: separatorView, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1, constant: 0))
		
		NSLayoutConstraint.activateConstraints(constraints)
	}
	
	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	public override func updateBackgroundColor() {
		super.updateBackgroundColor()
		if isPinned {
			backgroundColor = pinnedBackgroundColor
		}
	}
	
	public override func applyLayoutAttributes(layoutAttributes: UICollectionViewLayoutAttributes) {
		super.applyLayoutAttributes(layoutAttributes)
		
		guard let attributes = layoutAttributes as? CollectionViewLayoutAttributes else {
			return
		}
		
		if attributes.layoutMargins == UIEdgeInsetsZero {
			layoutMargins = defaultLayoutMargins
		}
		else {
			layoutMargins = attributes.layoutMargins
		}
		
		separatorColor = attributes.separatorColor
		pinnedSeparatorColor = attributes.pinnedSeparatorColor
		showsSeparator = attributes.showsSeparator
		pinnedBackgroundColor = attributes.pinnedBackgroundColor
		
		isPinned = attributes.isPinned
	}
	
	public override func prepareForReuse() {
		super.prepareForReuse()
		layoutMargins = defaultLayoutMargins
		isPinned = false
		pinnedBackgroundColor = nil
	}
	
	public override func layoutMarginsDidChange() {
		super.layoutMarginsDidChange()
		setNeedsUpdateConstraints()
	}

}
