//
//  CatListViewController.swift
//  AdvancedCollectionViewDemo
//
//  Created by Bryan Hoke on 2/29/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import NTICollectionView

private let DetailSegueIdentifier = "detail"

class CatListViewController: CollectionViewController, SegmentedCollectionDataSourceDelegate {
	
	private var segmentedDataSource = SegmentedCollectionDataSource()
	private var catsDataSource = CatListDataSource()
	private var favoriteCatsDataSource = CatListDataSource()
	private var selectedIndexPath: NSIndexPath!

    override func viewDidLoad() {
        super.viewDidLoad()

		configureAllCatsDataSource()
		configureFavoriteCatsDataSource()
		
		let metrics = GridDataSourceSectionMetrics()
		if let gridMetrics = metrics.metrics as? BasicGridSectionMetrics {
			gridMetrics.estimatedRowHeight = 44
			gridMetrics.showsRowSeparator = true
			gridMetrics.separatorInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
		}
		segmentedDataSource.defaultMetrics = metrics
		
		segmentedDataSource.segmentedCollectionDataSourceDelegate = self
		
		segmentedDataSource.add(catsDataSource)
		segmentedDataSource.add(favoriteCatsDataSource)
		
		collectionView?.dataSource = segmentedDataSource
		
		let segmentedControl = SegmentedControl(items: [])
		navigationItem.titleView = segmentedControl
		segmentedDataSource.configure(segmentedControl)
    }
	
	private func configureAllCatsDataSource() {
		catsDataSource.isShowingFavorites = false
		catsDataSource.title = "All"
		catsDataSource.noContentPlaceholder = BasicDataSourcePlaceholder(title: "No Cats", message: "All the big cats are napping or roaming elsewhere. Please try again later.", image: nil)
		catsDataSource.errorPlaceholder = BasicDataSourcePlaceholder(title: "Unable to Load Cats", message: "A problem with the network prevented loading the available cats.\nPlease, check your network settings.", image: nil)
	}
	
	private func configureFavoriteCatsDataSource() {
		favoriteCatsDataSource.isShowingFavorites = true
		favoriteCatsDataSource.title = "Favorites"
		favoriteCatsDataSource.noContentPlaceholder = BasicDataSourcePlaceholder(title: "No Favorites", message: "You have no favorite cats. Tap the star icon to add a cat to your list of favorites.", image: nil)
		favoriteCatsDataSource.errorPlaceholder = BasicDataSourcePlaceholder(title: "Unable to Load Favorites", message: "A problem with the network prevented loading your favorite cats. Please check your network settings.", image: nil)
	}
	
	func segmentedCollectionDataSourceDidChangeSelectedDataSource(segmentedCollectionDataSource: SegmentedCollectionDataSourceProtocol) {
		let dataSource = segmentedCollectionDataSource.selectedDataSource
		
		title = dataSource.title
		
		if dataSource === catsDataSource {
			editing = false
			navigationItem.rightBarButtonItem = nil
		} else {
			navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Edit, target: self, action: "beginEditing")
		}
	}
	
	func beginEditing() {
		editing = true
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "endEditing")
	}
	
	func endEditing() {
		editing = false
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Edit, target: self, action: "beginEditing")
	}
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		guard segue.identifier == DetailSegueIdentifier,
			let controller = segue.destinationViewController as? CatDetailViewController,
			cat = segmentedDataSource.item(at: selectedIndexPath) as? AAPLCat else {
				return
		}
		controller.cat = cat
	}
	
	override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
		selectedIndexPath = indexPath
		performSegueWithIdentifier(DetailSegueIdentifier, sender: self)
	}

}
