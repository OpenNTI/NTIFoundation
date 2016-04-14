//
//  TextValueCell.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 4/14/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

/// A simple `CollectionViewCell` that displays a large block of text.
public class TextValueCell: CollectionViewCell {
	
	public override init(frame: CGRect) {
		super.init(frame: frame)
		
		
	}
	
	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	public var numberOfLines: Int = 0
	
	public var allowsTruncation = false
	
	private let titleLabel = UILabel()
	
}
