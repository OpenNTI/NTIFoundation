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
	func localSectionForGlobalSection(globalSection: Int) -> Int
	func localSectionsForGlobalSections(globalSections: NSIndexSet) -> NSIndexSet
	
	/// Return the global section for a local section.
	func globalSectionForLocalSection(localSection: Int) -> Int
	func globalSectionsForLocalSections(localSections: NSIndexSet) -> NSIndexSet
	
	/// Return a local index path for a global index path. Returns nil when the global indexPath does not map locally.
	func localIndexPathForGlobal(globalIndexPath: NSIndexPath) -> NSIndexPath
	
	/// Return a global index path for a local index path.
	func globalIndexPathForLocal(localIndexPath: NSIndexPath) -> NSIndexPath
	
	/// Return an array of local index paths from an array of global index paths.
	func localIndexPathsForGlobal(globalIndexPaths: [NSIndexPath]) -> [NSIndexPath]
	
	/// Return an array of global index paths from an array of local index paths.
	func globalIndexPathsForLocal(localIndexPaths: [NSIndexPath]) -> [NSIndexPath]
	
	/// The func argument is called once for each mapped section and passed the global section index.
	func updateMappingStartingAtGlobalSection(globalSection: Int, withUpdater updater: ((globalSection: Int) -> Void)?)
	
}

extension DataSourceMapping {
	
	public func localSectionsForGlobalSections(globalSections: NSIndexSet) -> NSIndexSet {
		let localSections = NSMutableIndexSet()
		for globalSection in globalSections {
			let localSection = localSectionForGlobalSection(globalSection)
			localSections.addIndex(localSection)
		}
		return localSections
	}
	
	public func globalSectionsForLocalSections(localSections: NSIndexSet) -> NSIndexSet {
		let globalSections = NSMutableIndexSet()
		for localSection in localSections {
			let globalSection = globalSectionForLocalSection(localSection)
			globalSections.addIndex(globalSection)
		}
		return globalSections
	}
	
	public func localIndexPathsForGlobal(globalIndexPaths: [NSIndexPath]) -> [NSIndexPath] {
		return globalIndexPaths.flatMap {
			localIndexPathForGlobal($0)
		}
	}
	
	public func globalIndexPathsForLocal(localIndexPaths: [NSIndexPath]) -> [NSIndexPath] {
		return localIndexPaths.map { globalIndexPathForLocal($0) }
	}
	
}

public class BasicDataSourceMapping: NSObject, DataSourceMapping {
	
	public init(dataSource: CollectionDataSource, GlobalSectionIndex: Int? = nil) {
		self.dataSource = dataSource
		super.init()
		if let GlobalSectionIndex = GlobalSectionIndex {
			updateMappingStartingAtGlobalSection(GlobalSectionIndex)
		}
	}
	
	public var dataSource: CollectionDataSource
	
	public private(set) var numberOfSections: Int = 0
	
	private var globalToLocalSections: [Int: Int] = [:]
	private var localToGlobalSections: [Int: Int] = [:]
	
	public func localSectionForGlobalSection(globalSection: Int) -> Int {
		return globalToLocalSections[globalSection]!
	}
	
	public func globalSectionForLocalSection(localSection: Int) -> Int {
		guard let globalSection = localToGlobalSections[localSection] else {
			preconditionFailure("localSection \(localSection) not found in localToGlobalSections: \(localToGlobalSections)")
		}
		return globalSection
	}
	
	public func localIndexPathForGlobal(globalIndexPath: NSIndexPath) -> NSIndexPath {
		let section = localSectionForGlobalSection(globalIndexPath.section)
		return NSIndexPath(forItem: globalIndexPath.item, inSection: section)
	}
	
	public func globalIndexPathForLocal(localIndexPath: NSIndexPath) -> NSIndexPath {
		let section = globalSectionForLocalSection(localIndexPath.section)
		return NSIndexPath(forItem: localIndexPath.item, inSection: section)
	}
	
	private func addMappingFromGlobalSection(globalSection: Int, toLocalSection localSection: Int) {
		assert(!localSectionExistsForGlobalSection(globalSection), "Collision while trying to add a mapping from globalSection \(globalSection) to localSection \(localSection)")
		globalToLocalSections[globalSection] = localSection
		localToGlobalSections[localSection] = globalSection
	}
	
	private func localSectionExistsForGlobalSection(globalSection: Int) -> Bool {
		return globalToLocalSections[globalSection] != nil
	}
	
	public func updateMappingStartingAtGlobalSection(globalSection: Int, withUpdater updater: ((globalSection: Int) -> Void)? = nil) {
		numberOfSections = dataSource.numberOfSections
		globalToLocalSections.removeAll(keepCapacity: true)
		localToGlobalSections.removeAll(keepCapacity: true)
		
		var globalSection = globalSection
		for localSection in 0..<numberOfSections {
			addMappingFromGlobalSection(globalSection, toLocalSection: localSection)
			updater?(globalSection: globalSection)
			globalSection += 1
		}
	}
	
}
