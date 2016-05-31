//
//  CatSightingsDataSource.swift
//  AdvancedCollectionViewDemo
//
//  Created by Bryan Hoke on 2/27/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import NTICollectionView

class CatSightingsDataSource : BasicCollectionDataSource<AAPLCatSighting> {
	
	init(cat: AAPLCat) {
		self.cat = cat
		super.init()
		dateFormatter.dateStyle = .ShortStyle
		dateFormatter.timeStyle = .ShortStyle
		defaultMetrics = GridDataSourceSectionMetrics()
	}
	
	private var cat: AAPLCat
	private let dateFormatter = NSDateFormatter()
	
	override func loadContent(with progress: LoadingProgress) {
		AAPLDataAccessManager.sharedManager().fetchSightingsForCat(cat) { (sightings, error) in
			guard !progress.isCancelled else {
				return
			}
			guard error == nil else {
				progress.done(with: error)
				return
			}
			progress.updateWithContent { me in
				guard let me = me as? CatSightingsDataSource else {
					return
				}
				me.items = sightings
			}
		}
	}
	
	override func registerReusableViews(with collectionView: UICollectionView) {
		super.registerReusableViews(with: collectionView)
		collectionView.registerClass(AAPLCatSightingCell.self, forCellWithReuseIdentifier: "AAPLCatSightingCell")
	}
	
	override func collectionView(collectionView: UICollectionView, identifierForCellAt indexPath: NSIndexPath) -> String {
		return "AAPLCatSightingCell"
	}
	
	override func collectionView(collectionView: UICollectionView, configure cell: UICollectionViewCell, `for` indexPath: NSIndexPath) {
		guard let cell = cell as? AAPLCatSightingCell,
			catSighting = value(at: indexPath) else {
				return
		}
		cell.configureWithCatSighting(catSighting, dateFormatter: dateFormatter)
	}
	
}
