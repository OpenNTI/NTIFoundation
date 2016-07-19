//
//  ImageDataSource.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 5/31/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

/// A `BasicCollectionDataSource` which vends instances of `ImageCell`.
public class ImageDataSource : BasicCollectionDataSource<UIImage> {
	
	public let imageCellReuse = "imageCellReuse"
	
	/// An optional transformation applied to images before being stored in `items`.
	public var imageTransform: ((UIImage) -> UIImage)?
	
	public override init() {
		super.init()
	}
	
	public override func setItems(items: [UIImage], animated: Bool) {
		var items = items
		if let transform = imageTransform {
			items = items.map(transform)
		}
		
		super.setItems(items, animated: animated)
	}
	
	public override func registerReusableViews(with collectionView: UICollectionView) {
		super.registerReusableViews(with: collectionView)
		
		collectionView.registerClass(ImageCell.self, forCellWithReuseIdentifier: imageCellReuse)
	}
	
	public override func collectionView(collectionView: UICollectionView, identifierForCellAt indexPath: NSIndexPath) -> String {
		return imageCellReuse
	}
	
	public override func collectionView(collectionView: UICollectionView, configure cell: UICollectionViewCell, for indexPath: NSIndexPath) {
		guard let cell = cell as? ImageCell else {
			return
		}
		cell.image = value(at: indexPath)
	}

}
