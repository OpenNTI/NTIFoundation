//
//  KeyValueDataSource.swift
//  AdvancedCollectionViewDemo
//
//  Created by Bryan Hoke on 2/26/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit
import NTICollectionView

typealias SourceType = AnyObject

class KeyValueDataSource: BasicCollectionDataSource {
	
	convenience init(object: SourceType?) {
		self.init()
		self.object = object
	}
	
	var object: SourceType? {
		didSet {
			guard object !== oldValue else {
				return
			}
			items = unfilteredItems
			notifySectionsRefreshed(NSIndexSet(index: 0))
		}
	}
	
	var titleColumnWidth = CGFloat.min
	
	private var unfilteredItems: [SourceType] = []
	
	override var items: [Item] {
		get {
			return super.items
		}
		set {
			unfilteredItems = newValue
			
			var newItems: [Item] = []
			for item in newValue {
				guard let item = item as? KeyValueItem,
					object = self.object,
					value = item.valueForObject(object)
					where value.characters.count > 0 else {
						continue
				}
				newItems.append(item)
			}
			super.items = newItems
		}
	}
	
	override var allowsSelection: Bool {
		return false
	}

	override func registerReusableViews(with collectionView: UICollectionView) {
		super.registerReusableViews(with: collectionView)
		collectionView.registerClass(AAPLKeyValueCell.self, forCellWithReuseIdentifier: "AAPLKeyValueCell")
	}
	
	override func collectionView(collectionView: UICollectionView, identifierForCellAt indexPath: NSIndexPath) -> String {
		return "AAPLKeyValueCell"
	}
	
	override func collectionView(collectionView: UICollectionView, configure cell: UICollectionViewCell, `for` indexPath: NSIndexPath) {
		guard let item = self.item(at: indexPath) as? KeyValueItem,
			cell = cell as? AAPLKeyValueCell else {
				return
		}
		
		guard let object = self.object,
			value = item.valueForObject(object) else {
				return
		}
		
		
		if titleColumnWidth != CGFloat.min {
			cell.titleColumnWidth = titleColumnWidth
		}
		
		switch item.itemType {
		case .Default:
			cell.configureWithTitle(item.localizedTitle, value: value)
		case .Button:
			cell.configureWithTitle(item.localizedTitle, buttonTitle: value, buttonImage: item.imageForObject(object), action: item.action!)
		case .URL:
			cell.configureWithTitle(item.localizedTitle, URL: value)
		}
	}
	
}
