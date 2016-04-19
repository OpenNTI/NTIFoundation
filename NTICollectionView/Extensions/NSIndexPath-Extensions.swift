//
//  NSIndexPath-Extensions.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/18/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import Foundation

extension NSIndexPath {
	
	var itemIndex: Int {
		return length > 1 ? item : indexAtPosition(0)
	}
	
	var layoutSection: Int {
		return length > 1 ? section : globalSectionIndex
	}
	
	var isSection: Bool {
		return length > 1 && item == NSNotFound
	}
	
}
