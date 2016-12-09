//
//  Debug.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/29/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

let layoutDebugging = true

func layoutLog(_ str: String) {
	if layoutDebugging {
		debugPrint(str)
	}
}

let dragLogging = true

func dragLog(_ funcName: String, message: String) {
	if dragLogging {
		debugPrint("\(funcName): \(message)")
	}
}

let updateDebugging = true

func updateLog(_ str: String) {
	if updateDebugging {
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

extension IndexPath: DebugLoggable {
	
	var debugLogDescription: String {
		var indexes: [String] = []
		let numberOfIndexes = count
		for index in 0..<numberOfIndexes {
			indexes.append("\(self.index(atPosition: index))")
		}
		return "(" + indexes.joined(separator: ", ") + ")"
	}
	
}

extension IndexSet: DebugLoggable {
	
	var debugLogDescription: String {
		var result: [String] = []
		enumerateRanges { (range, stop) in
			switch range.length {
			case 0:
				result.append("empty")
			case 1:
				result.append("\(range.location)")
			default:
				result.append(range.debugLogDescription)
			}
		}
		return "(" + result.joined(separator: ", ") + ")"
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
		case .cell:
			type = "CELL"
		case .decorationView:
			type = "DECORATION"
		case .supplementaryView:
			type = "SUPPLEMENTARY"
		}
		let kind = representedElementKind ?? ""
		return "\(type) \(kind) indexPath=\(indexPath.debugLogDescription) frame=\(frame) hidden=\(isHidden.debugLogDescription)"
	}
	
}
