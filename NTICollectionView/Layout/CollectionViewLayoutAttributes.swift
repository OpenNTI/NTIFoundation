//
//  CollectionViewLayoutAttributes.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/12/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public class CollectionViewLayoutAttributes: UICollectionViewLayoutAttributes {
	
	public override var hash: Int {
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
	public var isPinned = false
	/// The background color of the view.
	public var backgroundColor: UIColor?
	/// The background color when selected.
	public var selectedBackgroundColor: UIColor?
	/// Layout margins passed to cells and supplementary views.
	public var layoutMargins = UIEdgeInsetsZero
	
	/// The column index of the item in a grid layout.
	public var columnIndex: Int = NSNotFound
	public var isEditing = false
	public var isMovable = false
	public var pinnedBackgroundColor: UIColor?
	public var separatorColor: UIColor?
	public var pinnedSeparatorColor: UIColor?
	public var showsSeparator = false
	public var simulatesSelection = false
	/// Origin when not pinned.
	public var unpinnedOrigin = CGPointZero
	/// Whether the correct fitting size should be calculated in `-preferredLayoutAttributesFittingAttributes:` or if the value is already correct.
	public var shouldCalculateFittingSize = true
	
	/// The corner radius of the view's layer.
	public var cornerRadius: CGFloat = 0
	
	public override func copyWithZone(zone: NSZone) -> AnyObject {
		let copy = super.copyWithZone(zone) as! CollectionViewLayoutAttributes
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
	
	public override func isEqual(object: AnyObject?) -> Bool {
		guard let object = object as? CollectionViewLayoutAttributes
			where super.isEqual(object) else {
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
