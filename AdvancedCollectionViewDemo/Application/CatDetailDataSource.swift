//
//  CatDetailDataSource.swift
//  AdvancedCollectionViewDemo
//
//  Created by Bryan Hoke on 2/26/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import NTICollectionView

class CatDetailDataSource : ComposedCollectionDataSource {

	init(cat: AAPLCat) {
		self.cat = cat
		classificationDataSource = KeyValueDataSource<AAPLCat>(object: cat)
		descriptionDataSource = TextValueDataSource<AAPLCat>(object: cat)
		super.init()
		
		defaultMetrics = DataSourceSectionMetrics<TableLayout>()
		
		var classificationMetrics = DataSourceSectionMetrics<TableLayout>()
		
		var metrics = classificationMetrics.template
		metrics.estimatedRowHeight = 22
		
		classificationMetrics.applyValues(from: metrics)
		classificationDataSource.defaultMetrics = classificationMetrics
		
		let classificationSectionMetrics = DataSourceSectionMetrics<TableLayout>()
		classificationDataSource.setMetrics(classificationSectionMetrics, forSectionAtIndex: 0)
		classificationDataSource.title = "Classification"
		let classificationHeader = classificationDataSource.makeDataSourceTitleHeader()
		add(classificationHeader, forKey: DataSourceTitleHeaderKey)
		add(classificationDataSource)
		
		var descriptionMetrics = DataSourceSectionMetrics<TableLayout>()
		metrics.estimatedRowHeight = 100
		descriptionMetrics.applyValues(from: metrics)
		descriptionDataSource.defaultMetrics = descriptionMetrics
		add(descriptionDataSource)
	}
	
	private var cat: AAPLCat
	private var classificationDataSource: KeyValueDataSource<AAPLCat>
	private var descriptionDataSource: TextValueDataSource<AAPLCat>
	
	private func updateChildDataSources() {
		classificationDataSource.items = [
			KeyValueItem(localizedTitle: "Kingdom", keyPath: "classificationKingdom"),
			KeyValueItem(localizedTitle: "Phylum", keyPath: "classificationPhylum"),
			KeyValueItem(localizedTitle: "Class", keyPath: "classificationClass"),
			KeyValueItem(localizedTitle: "Order", keyPath: "classificationOrder"),
			KeyValueItem(localizedTitle: "Family", keyPath: "classificationFamily"),
			KeyValueItem(localizedTitle: "Genus", keyPath: "classificationGenus"),
			KeyValueItem(localizedTitle: "Species", keyPath: "classificationSpecies")
		]
		
		descriptionDataSource.items = [
			KeyValueItem(localizedTitle: "Description", keyPath: "longDescription"),
			KeyValueItem(localizedTitle: "Habitat", keyPath: "habitat")
		]
	}
	
	override func loadContent(with progress: LoadingProgress) {
		AAPLDataAccessManager.sharedManager().fetchDetailForCat(cat) { (cat, error) in
			guard !progress.isCancelled else {
				return
			}
			
			guard error == nil else {
				progress.done(with: error!)
				return
			}
			
			progress.updateWithContent { me in
				guard let me = me as? CatDetailDataSource else {
					return
				}
				me.updateChildDataSources()
			}
		}
	}
	
}
