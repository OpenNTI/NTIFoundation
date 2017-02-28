//
//  PinnableHeaderView.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 6/2/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

/// A base class for headers that respond to being pinned to the top of the collection view.
open class PinnableHeaderView: CollectionSupplementaryView {

	/// Default	`layoutMargins` values preferred by `self`.
	open var defaultLayoutMargins = UIEdgeInsets(top: 8, left: 15, bottom: 8, right: 15)
	
	/// Property updated by the collection view layout when the header is pinned to the top of the collection view.
	open var isPinned: Bool {
		get { return _isPinned }
		set {
			let duration = (newValue == _isPinned ? 0 : 0.25)
			
			UIView.animate(withDuration: duration, animations: { 
				if newValue {
					self.backgroundColor = self.pinnedBackgroundColor
				}
				else {
					self.backgroundColor = self.normalBackgroundColor
				}
				
				self._isPinned = newValue
				
				let separatorColor = self.pinnedSeparatorColor ?? self.separatorColor
				self.separatorView.backgroundColor = separatorColor
			}) 
		}
	}
	
	fileprivate var _isPinned = false
	
	/// Whether `self` displays a separator beneath its text.
	open var showsSeparator = false {
		didSet { separatorView.isHidden = !showsSeparator }
	}
	
	/// The color of the separator.
	open var separatorColor: UIColor? {
		didSet {
			if isPinned {
				separatorView.backgroundColor = pinnedSeparatorColor
			}
		}
	}
	
	/// The color of the separator when	`self` is pinned.
	///
	/// If `nil`, the separator will not change color when pinned.
	open var pinnedSeparatorColor: UIColor? {
		didSet {
			if isPinned {
				separatorView.backgroundColor = pinnedSeparatorColor
			}
		}
	}
	
	/// The background color to display when `self` is been pinned. 
	///
	/// A `nil` value indicates the header should blend with navigation bars.
	open var pinnedBackgroundColor: UIColor?
	
	let separatorView = UIView()
	
	public override init(frame: CGRect) {
		super.init(frame: frame)
		
		separatorView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(separatorView)
		
		let views = ["separator": separatorView]
		var constraints = [NSLayoutConstraint]()
		
		constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|[separator]|", options: [], metrics: nil, views: views)
		constraints.append(NSLayoutConstraint(item: separatorView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0))
		
		NSLayoutConstraint.activate(constraints)
	}
	
	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	open override func updateBackgroundColor() {
		super.updateBackgroundColor()
		if isPinned {
			backgroundColor = pinnedBackgroundColor
		}
	}
	
	open override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
		super.apply(layoutAttributes)
		
		guard let attributes = layoutAttributes as? CollectionViewLayoutAttributes else {
			return
		}
		
		if attributes.layoutMargins == UIEdgeInsets.zero {
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
	
	open override func prepareForReuse() {
		super.prepareForReuse()
		layoutMargins = defaultLayoutMargins
		isPinned = false
		pinnedBackgroundColor = nil
	}
	
	open override func layoutMarginsDidChange() {
		super.layoutMarginsDidChange()
		setNeedsUpdateConstraints()
	}

}
