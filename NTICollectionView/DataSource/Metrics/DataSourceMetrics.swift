//
//  DataSourceMetrics.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/12/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public protocol DataSourceSectionMetrics: DataSourceSectionInfo, SectionMetrics {
	
	var metrics: SectionMetrics { get set }
	
	func copy() -> AnyObject
	
}
