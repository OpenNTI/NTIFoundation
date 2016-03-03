//
//  GridSectionColumnLayoutEngine.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/26/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public class GridSectionColumnLayoutEngine: NSObject {

	public init(layoutSection: GridLayoutSection) {
		self.layoutSection = layoutSection
		super.init()
	}
	
	public weak var layoutSection: GridLayoutSection!
	
	var origin: CGPoint!
	
}
