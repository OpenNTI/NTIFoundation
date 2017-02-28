//
//  CollectionViewLayoutAttributes.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/12/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

open class CollectionViewLayoutAttributes: UICollectionViewLayoutAttributes {
	
	open override var hash: Int {
		let prime = 31
		var result = 1
		result = prime * result + super.hash
		result = prime * result + (isPinned ? 1 : 0)
		result = prime * result + columnIndex
		result = prime * result + (backgroundColor?.hashValue ?? 0)
		result = prime * result + (selectedBackgroundColor?.hashValue ?? 0)
		result = prime * result + layoutMargins.top.hashValue
		result = prime * result + layoutMargins.left.hashValue
		result = prime * result + layoutMargins.bottom.hashValue
		result = prime * result + layoutMargins.right.hashValue
		result = prime * result + (isEditing ? 1 : 0)
		result = prime * result + (isMovable ? 1 : 0)
		result = prime * result + (shouldCalculateFittingSize ? 1 : 0)
		result = prime * result + cornerRadius.hashValue
		return result
	}
	
	// If this is a supplementary view, is it pinned in place?
	open var isPinned = false
	/// The background color of the view.
	open var backgroundColor: UIColor?
	/// The background color when selected.
	open var selectedBackgroundColor: UIColor?
	/// Layout margins passed to cells and supplementary views.
	open var layoutMargins = UIEdgeInsets.zero
	
	/// The column index of the item in a grid layout.
	open var columnIndex: Int = NSNotFound
	open var isEditing = false
	open var isMovable = false
	open var pinnedBackgroundColor: UIColor?
	open var separatorColor: UIColor?
	open var pinnedSeparatorColor: UIColor?
	open var showsSeparator = false
	open var simulatesSelection = false
	/// Origin when not pinned.
	open var unpinnedOrigin = CGPoint.zero
	/// Whether the correct fitting size should be calculated in `-preferredLayoutAttributesFittingAttributes:` or if the value is already correct.
	open var shouldCalculateFittingSize = true
	
	/// The corner radius of the view's layer.
	open var cornerRadius: CGFloat = 0
	
	open override func copy(with zone: NSZone?) -> Any {
		let copy = super.copy(with: zone) as! CollectionViewLayoutAttributes
		copy.isPinned = isPinned
		copy.columnIndex = columnIndex
		copy.backgroundColor = backgroundColor
		copy.selectedBackgroundColor = selectedBackgroundColor
		copy.layoutMargins = layoutMargins
		copy.isEditing = isEditing
		copy.isMovable = isMovable
		copy.unpinnedOrigin = unpinnedOrigin
		copy.shouldCalculateFittingSize = shouldCalculateFittingSize
		copy.simulatesSelection = simulatesSelection
		copy.separatorColor = separatorColor
		copy.pinnedSeparatorColor = pinnedSeparatorColor
		copy.pinnedBackgroundColor = pinnedBackgroundColor
		copy.showsSeparator = showsSeparator
		copy.cornerRadius = cornerRadius
		return copy
	}
	
	open override func isEqual(_ object: Any?) -> Bool {
		guard let object = object as? CollectionViewLayoutAttributes, super.isEqual(object) else {
				return false
		}
		return isEditing == object.isEditing
			&& isMovable == object.isMovable
			&& isPinned == object.isPinned
			&& columnIndex == object.columnIndex
			&& backgroundColor == object.backgroundColor
			&& selectedBackgroundColor == object.selectedBackgroundColor
			&& layoutMargins == object.layoutMargins
			&& shouldCalculateFittingSize == object.shouldCalculateFittingSize
			&& cornerRadius == object.cornerRadius
	}
	
}
