//
//  Debug.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/29/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

let LayoutDebugging = true

func layoutLog(str: String) {
	if LayoutDebugging {
		debugPrint(str)
	}
}

let UpdateDebugging = true
func updateLog(str: String) {
	if UpdateDebugging {
		debugPrint(str)
	}
}

protocol DebugLoggable {
	
	var debugLogDescription: String { get }
	
}

extension Bool: DebugLoggable {
	
	var debugLogDescription: String {
		return self ? "true" : "false"
	}
	
}

extension NSIndexPath: DebugLoggable {
	
	var debugLogDescription: String {
		var indexes: [String] = []
		let numberOfIndexes = length
		for index in 0..<numberOfIndexes {
			indexes.append("\(indexAtPosition(index))")
		}
		return "(" + indexes.joinWithSeparator(", ") + ")"
	}
	
}

extension NSIndexSet: DebugLoggable {
	
	var debugLogDescription: String {
		var result: [String] = []
		enumerateRangesUsingBlock { (range, stop) in
			switch range.length {
			case 0:
				result.append("empty")
			case 1:
				result.append("\(range.location)")
			default:
				result.append(range.debugLogDescription)
			}
		}
		return "(" + result.joinWithSeparator(", ") + ")"
	}
	
}

extension NSRange: DebugLoggable {
	
	var debugLogDescription: String {
		let start = location
		let end = location + length - 1
		return "\(start)...\(end)"
	}
	
}

extension UICollectionViewLayoutAttributes: DebugLoggable {
	
	var debugLogDescription: String {
		let type: String
		switch representedElementCategory {
		case .Cell:
			type = "CELL"
		case .DecorationView:
			type = "DECORATION"
		case .SupplementaryView:
			type = "SUPPLEMENTARY"
		}
		let kind = representedElementKind ?? ""
		return "\(type) \(kind) indexPath=\(indexPath.debugLogDescription) frame=\(frame) hidden=\(hidden.debugLogDescription)"
	}
	
}
