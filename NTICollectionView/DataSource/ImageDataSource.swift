//
//  ImageDataSource.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 5/31/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

/// A `BasicCollectionDataSource` which vends instances of `ImageCell`.
open class ImageDataSource : BasicCollectionDataSource<UIImage> {
	
	open let imageCellReuse = "imageCellReuse"
	
	/// An optional transformation applied to images before being stored in `items`.
	open var imageTransform: ((UIImage) -> UIImage)?
	
	public override init() {
		super.init()
	}
	
	open override func setItems(_ items: [UIImage], animated: Bool) {
		var items = items
		if let transform = imageTransform {
			items = items.map(transform)
		}
		
		super.setItems(items, animated: animated)
	}
	
	open override func registerReusableViews(with collectionView: UICollectionView) {
		super.registerReusableViews(with: collectionView)
		
		collectionView.register(ImageCell.self, forCellWithReuseIdentifier: imageCellReuse)
	}
	
	open override func collectionView(_ collectionView: UICollectionView, identifierForCellAt indexPath: IndexPath) -> String {
		return imageCellReuse
	}
	
	open override func collectionView(_ collectionView: UICollectionView, configure cell: UICollectionViewCell, for indexPath: IndexPath) {
		guard let cell = cell as? ImageCell else {
			return
		}
		cell.image = value(at: indexPath)
	}

}
