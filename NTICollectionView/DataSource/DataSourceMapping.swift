//
//  DataSourceMapping.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/23/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

/// Maps global sections to local sections for a given data source.
public protocol DataSourceMapping: NSObjectProtocol {
	
	/// The data source associated with this mapping.
	var dataSource: CollectionDataSource { get set }
	
	/// The number of sections in this mapping.
	var numberOfSections: Int { get }
	
	/// Return the local section for a global section.
	func localSectionForGlobalSection(_ globalSection: Int) -> Int?
	func localSectionsForGlobalSections(_ globalSections: IndexSet) -> IndexSet
	
	/// Return the global section for a local section.
	func globalSectionForLocalSection(_ localSection: Int) -> Int
	func globalSectionsForLocalSections(_ localSections: IndexSet) -> IndexSet
	
	/// Return a local index path for a global index path. Returns nil when the global indexPath does not map locally.
	func localIndexPathForGlobal(_ globalIndexPath: IndexPath) -> IndexPath?
	
	/// Return a global index path for a local index path.
	func globalIndexPathForLocal(_ localIndexPath: IndexPath) -> IndexPath
	
	/// Return an array of local index paths from an array of global index paths.
	func localIndexPathsForGlobal(_ globalIndexPaths: [IndexPath]) -> [IndexPath]
	
	/// Return an array of global index paths from an array of local index paths.
	func globalIndexPathsForLocal(_ localIndexPaths: [IndexPath]) -> [IndexPath]
	
	/// The func argument is called once for each mapped section and passed the global section index.
	func updateMappingStartingAtGlobalSection(_ globalSection: Int, withUpdater updater: ((_ globalSection: Int) -> Void)?)
	
}

extension DataSourceMapping {
	
	public func localSectionsForGlobalSections(_ globalSections: IndexSet) -> IndexSet {
		let localSections = NSMutableIndexSet()
		for globalSection in globalSections {
			guard let localSection = localSectionForGlobalSection(globalSection) else {
				continue
			}
			localSections.add(localSection)
		}
		return localSections as IndexSet
	}
	
	public func globalSectionsForLocalSections(_ localSections: IndexSet) -> IndexSet {
		let globalSections = NSMutableIndexSet()
		for localSection in localSections {
			let globalSection = globalSectionForLocalSection(localSection)
			globalSections.add(globalSection)
		}
		return globalSections as IndexSet
	}
	
	public func localIndexPathsForGlobal(_ globalIndexPaths: [IndexPath]) -> [IndexPath] {
		return globalIndexPaths.flatMap {
			localIndexPathForGlobal($0)
		}
	}
	
	public func globalIndexPathsForLocal(_ localIndexPaths: [IndexPath]) -> [IndexPath] {
		return localIndexPaths.map { globalIndexPathForLocal($0) }
	}
	
}

open class BasicDataSourceMapping: NSObject, DataSourceMapping {
	
	public init(dataSource: CollectionDataSource, globalSectionIndex: Int? = nil) {
		self.dataSource = dataSource
		super.init()
		if let globalSectionIndex = globalSectionIndex {
			updateMappingStartingAtGlobalSection(globalSectionIndex)
		}
	}
	
	open var dataSource: CollectionDataSource
	
	open fileprivate(set) var numberOfSections: Int = 0
	
	fileprivate var globalToLocalSections: [Int: Int] = [:]
	fileprivate var localToGlobalSections: [Int: Int] = [:]
	
	open func localSectionForGlobalSection(_ globalSection: Int) -> Int? {
		return globalToLocalSections[globalSection]
	}
	
	open func globalSectionForLocalSection(_ localSection: Int) -> Int {
		guard let globalSection = localToGlobalSections[localSection] else {
			preconditionFailure("localSection \(localSection) not found in localToGlobalSections: \(localToGlobalSections)")
		}
		return globalSection
	}
	
	open func localIndexPathForGlobal(_ globalIndexPath: IndexPath) -> IndexPath? {
		guard let section = localSectionForGlobalSection(globalIndexPath.section) else {
			return nil
		}
		return IndexPath(item: globalIndexPath.item, section: section)
	}
	
	open func globalIndexPathForLocal(_ localIndexPath: IndexPath) -> IndexPath {
		let section = globalSectionForLocalSection(localIndexPath.section)
		return IndexPath(item: localIndexPath.item, section: section)
	}
	
	fileprivate func addMappingFromGlobalSection(_ globalSection: Int, toLocalSection localSection: Int) {
		assert(!localSectionExistsForGlobalSection(globalSection), "Collision while trying to add a mapping from globalSection \(globalSection) to localSection \(localSection)")
		globalToLocalSections[globalSection] = localSection
		localToGlobalSections[localSection] = globalSection
	}
	
	fileprivate func localSectionExistsForGlobalSection(_ globalSection: Int) -> Bool {
		return globalToLocalSections[globalSection] != nil
	}
	
	open func updateMappingStartingAtGlobalSection(_ globalSection: Int, withUpdater updater: ((_ globalSection: Int) -> Void)? = nil) {
		numberOfSections = dataSource.numberOfSections
		globalToLocalSections.removeAll(keepingCapacity: true)
		localToGlobalSections.removeAll(keepingCapacity: true)
		
		var globalSection = globalSection
		for localSection in 0..<numberOfSections {
			addMappingFromGlobalSection(globalSection, toLocalSection: localSection)
			updater?(globalSection)
			globalSection += 1
		}
	}
	
}
