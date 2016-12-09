//
//  NSIndexPath-Extensions.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/18/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import Foundation

extension IndexPath {
	
	var itemIndex: Int {
		return count > 1 ? item : index(atPosition: 0)
	}
	
	var layoutSection: Int {
		return count > 1 ? section : globalSectionIndex
	}
	
	var isSection: Bool {
		return count > 1 && item == NSNotFound
	}
	
}
