//
//  CollectionDataSource-Extensions.swift
//  AdvancedCollectionViewDemo
//
//  Created by Bryan Hoke on 2/26/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import NTICollectionView

let DataSourceTitleHeaderKey = "DataSourceTitleHeaderKey"

extension AbstractCollectionDataSource {
	
	var dataSourceTitleHeader: SupplementaryItem {
		return dataSourceHeaderWithTitle(title ?? "NULL")
	}
	
	func dataSourceHeaderWithTitle(title: String) -> SupplementaryItem {
		if let header = supplementaryItemForKey(DataSourceTitleHeaderKey) {
			return header
		}
		let header = BasicGridSupplementaryItem(elementKind: UICollectionElementKindSectionHeader)
		add(header, forKey: DataSourceTitleHeaderKey)
		header.supplementaryViewClass = AAPLSectionHeaderView.self
		header.configure { (view, dataSource, indexPath) in
			guard let view = view as? AAPLSectionHeaderView else {
				return
			}
			view.leftText = title
		}
		return header
	}
	
	func sectionHeaderForSectionAtIndex(sectionIndex: Int) -> SupplementaryItem {
		let newHeader = BasicGridSupplementaryItem(elementKind: UICollectionElementKindSectionHeader)
		newHeader.supplementaryViewClass = AAPLSectionHeaderView.self
		newHeader.backgroundColor = UIColor.blueColor()
		add(newHeader, forSectionAtIndex: sectionIndex)
		return newHeader
	}
	
	func sectionHeaderWithTitle(title: String, forSectionAtIndex sectionIndex: Int) -> SupplementaryItem {
		let newHeader = sectionHeaderForSectionAtIndex(sectionIndex)
		newHeader.configure { (view, dataSource, indexPath) in
			guard let view = view as? AAPLSectionHeaderView else {
				return
			}
			view.leftText = title
		}
		if let gridHeader = newHeader as? GridSupplementaryItem {
			gridHeader.backgroundColor = UIColor.redColor()
		}
		return newHeader
	}
	
}