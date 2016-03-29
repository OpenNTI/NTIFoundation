//
//  TextValueDataSource.swift
//  AdvancedCollectionViewDemo
//
//  Created by Bryan Hoke on 2/26/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

class TextValueDataSource: KeyValueDataSource {

	override func registerReusableViews(with collectionView: UICollectionView) {
		super.registerReusableViews(with: collectionView)
		collectionView.registerClass(AAPLTextValueCell.self, forCellWithReuseIdentifier: "AAPLTextValueCell")
	}
	
	override func collectionView(collectionView: UICollectionView, identifierForCellAt indexPath: NSIndexPath) -> String {
		return "AAPLTextValueCell"
	}
	
	override func collectionView(collectionView: UICollectionView, configure cell: UICollectionViewCell, `for` indexPath: NSIndexPath) {
		guard let item = self.item(at: indexPath) as? KeyValueItem,
			cell = cell as? AAPLTextValueCell else {
			return
		}
		
		guard let object = self.object,
			value = item.valueForObject(object) else {
				return
		}
		
		cell.configureWithTitle(item.localizedTitle, text: value)
	}
	
}
