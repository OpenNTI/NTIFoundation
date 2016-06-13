//
//  CatListDataSource.swift
//  AdvancedCollectionViewDemo
//
//  Created by Bryan Hoke on 2/27/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import NTICollectionView

class CatListDataSource : BasicCollectionDataSource<AAPLCat> {
	
	override init() {
		super.init()
		defaultMetrics = DataSourceSectionMetrics<TableLayout>()
	}
	
	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self, name: AAPLCatFavoriteToggledNotificationName, object: nil)
	}

	var isShowingFavorites = false {
		didSet {
			guard isShowingFavorites != oldValue else {
				return
			}
			
			resetContent()
			setNeedsLoadContent()
			
			if isShowingFavorites {
				NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CatListDataSource.observeFavoriteToggledNotification(_:)), name: AAPLCatFavoriteToggledNotificationName, object: nil)
			}
		}
	}
	
	@objc func observeFavoriteToggledNotification(notification: NSNotification) {
		dispatch_async(dispatch_get_main_queue()) {
			guard let cat = notification.object as? AAPLCat else {
				return
			}
			var items = self.items
			let position = items.indexOf({ $0 === cat })
			
			if cat.favorite {
				if position == nil {
					items.append(cat)
				}
			} else {
				if position != nil {
					items.removeAtIndex(position!)
				}
			}
			
			self.performUpdate({ () -> Void in
				self.items = items
			})
		}
	}
	
	override func registerReusableViews(with collectionView: UICollectionView) {
		super.registerReusableViews(with: collectionView)
		collectionView.registerClass(AAPLBasicCell.self, forCellWithReuseIdentifier: "AAPLBasicCell")
	}
	
	override func collectionView(collectionView: UICollectionView, identifierForCellAt indexPath: NSIndexPath) -> String {
		return "AAPLBasicCell"
	}
	
	override func collectionView(collectionView: UICollectionView, configure cell: UICollectionViewCell, `for` indexPath: NSIndexPath) {
		guard let cell = cell as? AAPLBasicCell,
			cat = value(at: indexPath) else {
				return
		}
		cell.style = .Subtitle
		cell.primaryLabel.text = cat.name
		cell.primaryLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
		cell.secondaryLabel.text = cat.shortDescription
		cell.secondaryLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline)
	}
	
	override func loadContent(with progress: LoadingProgress) {
		let handler = { (cats: [AAPLCat]!, error: NSError!) in
			guard !progress.isCancelled else {
				return
			}
			
			guard error == nil else {
				progress.done(with: error!)
				return
			}
			
			if cats.count > 0 {
				progress.updateWithContent { me in
					guard let me = me as? CatListDataSource else {
						return
					}
					me.items = cats
				}
			} else {
				progress.updateWithNoContent { me in
					guard let me = me as? CatListDataSource else {
						return
					}
					me.items = []
				}
			}
		}
		
		if isShowingFavorites {
			AAPLDataAccessManager.sharedManager().fetchFavoriteCatListWithCompletionHandler(handler)
		} else {
			AAPLDataAccessManager.sharedManager().fetchCatListWithCompletionHandler(handler)
		}
	}
	
	// MARK: - Drag reorder support
	
	override func collectionView(collectionView: UICollectionView, canMoveItemAt indexPath: NSIndexPath) -> Bool {
		return true
	}
	
	override func collectionView(collectionView: UICollectionView, canMoveItemAt indexPath: NSIndexPath, to destinationIndexPath: NSIndexPath) -> Bool {
		return true
	}
	
}
