//
//  CollectionViewLayout.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/11/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

/// A subclass of UICollectionViewLayoutInvalidationContext that adds invalidation for metrics.
public class CollectionViewLayoutInvalidationContext: UICollectionViewLayoutInvalidationContext {
	
	/// Any index paths that have been explicitly invalidated need to be remeasured.
	public var invalidateMetrics = false
	
}

public class CollectionViewSeparatorView: UICollectionReusableView {
	
	public override func applyLayoutAttributes(layoutAttributes: UICollectionViewLayoutAttributes) {
		guard let layoutAttributes = layoutAttributes as? CollectionViewLayoutAttributes else {
			return
		}
		backgroundColor = layoutAttributes.backgroundColor
		layer.cornerRadius = layoutAttributes.cornerRadius
	}
	
}

public class CollectionViewLayout: UICollectionViewLayout, CollectionViewLayoutMeasuring, CollectionDataSourceDelegate, ShadowRegistrarVending {
	
	public var isEditing = false {
		didSet {
			guard isEditing != oldValue else {
				return
			}
			layoutDataIsValid = false
			invalidateLayout()
		}
	}
	
	var layoutSize = CGSizeZero
	
	private var layoutInfo: LayoutInfo?
	private var oldLayoutInfo: LayoutInfo?
	
	private var updateSectionDirections: [Int: SectionOperationDirection] = [:]
	
	private var updateRecorder = CollectionUpdateRecorder()
	
	private var contentOffsetDelta = CGPointZero
	
	/// A duplicate registry of all the cell & supplementary view class/nibs used in this layout. These will be used to create views while measuring the layout instead of dequeueing reusable views, because that causes consternation in UICollectionView.
	public var shadowRegistrar = ShadowRegistrar()
	/// Flag used to lock out multiple calls to `buildLayout` which seems to happen when measuring cells and supplementary views.
	private var isBuildingLayout = false
	/// The attributes being currently measured. This allows short-circuiting the lookup in several API methods.
	private var measuringAttributes: CollectionViewLayoutAttributes?
	/// The collection view wrapper used while measuring views.
	private var collectionViewWrapper: CollectionViewWrapper?
	
	/// Whether the data source has the snapshot metrics method.
	private var dataSourceHasSnapshotMetrics = true
	/// Layout data becomes invalid if the data source changes.
	private var layoutDataIsValid = true
	
	public override init() {
		super.init()
		setUp()
	}

	public required init?(coder aDecoder: NSCoder) {
	    super.init(coder: aDecoder)
		setUp()
	}
	
	private func setUp() {
		registerDecorationViews()
	}
	
	public func registerDecorationViews() {
		// Subclasses should override to register custom decoration views
		// TODO: Encapsulate elsewhere
		registerClass(CollectionViewSeparatorView.self, forDecorationViewOfKind: collectionElementKindRowSeparator)
		registerClass(CollectionViewSeparatorView.self, forDecorationViewOfKind: collectionElementKindColumnSeparator)
		registerClass(CollectionViewSeparatorView.self, forDecorationViewOfKind: collectionElementKindSectionSeparator)
		registerClass(CollectionViewSeparatorView.self, forDecorationViewOfKind: collectionElementKindGlobalHeaderBackground)
		registerClass(CollectionViewSeparatorView.self, forDecorationViewOfKind: collectionElementKindContentBackground)
	}
	
	// MARK: - Editing helpers
	
	public func canEditItem(at indexPath: NSIndexPath) -> Bool {
		guard let collectionView = self.collectionView,
			dataSource = collectionView.dataSource as? CollectionDataSource else {
				return false
		}
		return dataSource.collectionView(collectionView, canEditItemAt: indexPath)
	}
	
	public func canMoveItem(at indexPath: NSIndexPath) -> Bool {
		guard let collectionView = self.collectionView,
			dataSource = collectionView.dataSource as? CollectionDataSource else {
				return false
		}
		return dataSource.collectionView(collectionView, canMoveItemAt: indexPath)
	}
	
	// MARK: - UICollectionViewLayout
	
	public override class func layoutAttributesClass() -> AnyClass {
		return CollectionViewLayoutAttributes.self
	}
	
	public override class func invalidationContextClass() -> AnyClass {
		return CollectionViewLayoutInvalidationContext.self
	}
	
	public override func invalidateLayoutWithContext(context: UICollectionViewLayoutInvalidationContext) {
		defer {
			super.invalidateLayoutWithContext(context)
		}
		let invalidateDataSourceCounts = context.invalidateDataSourceCounts
		var invalidateEverything = context.invalidateEverything
		
		// The collectionView has changed width, re-evaluate the layout
		if layoutInfo?.collectionViewSize.width != collectionView?.bounds.size.width {
			invalidateEverything = true
		}
		
		layoutLog("\(#function) invalidateDataSourceCounts = \(invalidateDataSourceCounts.debugLogDescription) invalidateEverything = \(invalidateEverything.debugLogDescription)")
		
		if invalidateEverything || (layoutDataIsValid && invalidateDataSourceCounts) {
			layoutDataIsValid = false
		}
		
		guard let context = context as? CollectionViewLayoutInvalidationContext,
			layoutInfo = self.layoutInfo else {
				return
		}
		
		// If the layout data is valid, but we've been asked to update the metrics, do that
		if layoutDataIsValid && context.invalidateMetrics {
			for (kind, supplementaryIndexPaths) in context.invalidatedSupplementaryIndexPaths ?? [:] {
				for indexPath in supplementaryIndexPaths {
					layoutInfo.invalidateMetricsForElementOfKind(kind, at: indexPath, invalidationContext: context)
				}
			}
			for indexPath in context.invalidatedItemIndexPaths ?? [] {
				layoutInfo.invalidateMetricsForItemAt(indexPath, invalidationContext: context)
			}
		}
		
		if LayoutDebugging {
			for (kind, indexPaths) in context.invalidatedSupplementaryIndexPaths ?? [:] {
				let result = indexPaths.map { $0.debugLogDescription }
				let resultStr = result.joinWithSeparator(", ")
				debugPrint("\(#function) \(kind) invalidated supplementary indexPaths: \(resultStr)")
			}
		}
	}
	
	public override func prepareLayout() {
		layoutLog("\(#function) bounds=\(collectionView!.bounds)")
		if let bounds = collectionView?.bounds where !bounds.isEmpty {
			buildLayout()
		}
		super.prepareLayout()
	}
	
	public override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
		layoutLog("\(#function) rect=\(rect)")
		guard let collectionView = self.collectionView,
			layoutInfo = self.layoutInfo else {
				return nil
		}
		
		let contentOffset = targetContentOffsetForProposedContentOffset(collectionView.contentOffset)
		layoutInfo.contentInset = collectionView.contentInset
		layoutInfo.bounds = collectionView.bounds
		layoutInfo.updateSpecialItemsWithContentOffset(contentOffset, invalidationContext: nil)
		
		var result: [UICollectionViewLayoutAttributes] = []
		for sectionInfo in layoutInfo.sections {
			result += sectionInfo.layoutAttributes.filter { $0.frame.intersects(rect) }
		}
		
		if LayoutDebugging {
			for attr in result {
				print("\(#function) \(attr.debugLogDescription)")
			}
		}
		
		return result
	}
	
	public override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
		let sectionIndex = indexPath.section
		
		guard let layoutInfo = self.layoutInfo
			where sectionIndex >= 0 && sectionIndex < layoutInfo.numberOfSections else {
				return nil
		}
		
		if let measuringAttributes = self.measuringAttributes
			where measuringAttributes.indexPath == indexPath {
			layoutLog("\(#function) indexPath=\(indexPath.debugLogDescription) measuringAttributes=\(measuringAttributes)")
			return measuringAttributes
		}
		
		let attributes = layoutInfo.layoutAttributesForCell(at: indexPath)
		layoutLog("\(#function) indexPath=\(indexPath.debugLogDescription) attributes=\(attributes)")
		return attributes
	}
	
	public override func layoutAttributesForSupplementaryViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
		if let measuringAttributes = self.measuringAttributes
			where measuringAttributes.indexPath == indexPath
				&& measuringAttributes.representedElementKind == elementKind {
					layoutLog("\(#function) measuringAttributes=\(measuringAttributes)")
					return measuringAttributes
		}
		
		guard let attributes = layoutInfo?.layoutAttributesForSupplementaryElementOfKind(elementKind, at: indexPath) else {
			preconditionFailure("We should ALWAYS find layout attributes.")
		}
		layoutLog("\(#function) indexPath=\(indexPath.debugLogDescription) attributes=\(attributes)")
		return attributes
	}
	
	public override func layoutAttributesForDecorationViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
		return layoutInfo?.layoutAttributesForDecorationViewOfKind(elementKind, at: indexPath)
	}
	
	public override func shouldInvalidateLayoutForPreferredLayoutAttributes(preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> Bool {
		// Invalidate if the cell changed height
		return preferredAttributes.frame.height != originalAttributes.frame.height
	}
	
	/*
	public override func invalidationContextForPreferredLayoutAttributes(preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutInvalidationContext {
		layoutLog("\(#function) originalAttributes=\(originalAttributes) preferredAttributes=\(preferredAttributes)")
		
		let indexPath = preferredAttributes.indexPath
		let size = preferredAttributes.frame.size
		
		let context = super.invalidationContextForPreferredLayoutAttributes(preferredAttributes, withOriginalAttributes: originalAttributes)
		
		switch preferredAttributes.representedElementCategory {
		case .Cell:
			layoutInfo?.setSize(size, forItemAt: indexPath, invalidationContext: context)
		case .SupplementaryView:
			layoutInfo?.setSize(size, forElementOfKind: preferredAttributes.representedElementKind!, at: indexPath, invalidationContext: context)
		default:
			break
		}
		
		layoutSize.height += context.contentSizeAdjustment.height
//		layoutLog("\(#function) contentSizeAdjustment=\(context.contentSizeAdjustment)")
		return context
	}
*/
	
	public override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
		return true
	}
	
	public override func invalidationContextForBoundsChange(newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
		let context = super.invalidationContextForBoundsChange(newBounds)
		
		guard let collectionView = self.collectionView else {
			return context
		}
		
		let bounds = collectionView.bounds
		let origin = bounds.origin, newOrigin = newBounds.origin
		
		let isRotation = origin == newOrigin
			&& bounds.width == newBounds.height
			&& bounds.height == newBounds.width
		
		let boundsChanged = newOrigin.x != origin.x
			|| newOrigin.y != origin.y
			|| newBounds.height > layoutSize.height
		
		if isRotation || !boundsChanged {
			return context
		}
		
		// Update the contentOffset so the special items will layout correctly
		var contentOffset = collectionView.contentOffset
		contentOffset.y += newOrigin.y - origin.y
		contentOffset.x += newOrigin.x - origin.x
		
		if let layoutInfo = self.layoutInfo {
			layoutInfo.contentInset = collectionView.contentInset
			layoutInfo.bounds = collectionView.bounds
			layoutInfo.updateSpecialItemsWithContentOffset(contentOffset, invalidationContext: context)
		}
		
		return context
	}
	
	public override func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
		return proposedContentOffset
	}
	
	public override func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint) -> CGPoint {
		guard let collectionView = self.collectionView else {
			return proposedContentOffset
		}
		
		let insets = collectionView.contentInset
		var targetContentOffset = proposedContentOffset
		
		// TODO: Adjust targetContentOffset.x?
		
		targetContentOffset.y += insets.top
		
		let availableHeight = UIEdgeInsetsInsetRect(collectionView.bounds, insets).height
		targetContentOffset.y = min(targetContentOffset.y, max(0, layoutSize.height - availableHeight))
		
		// TODO: Abstract into layout sections
		if let firstInsertedIndex = insertedSections.first,
			sectionInfo = sectionInfoForSectionAtIndex(firstInsertedIndex),
			globalSection = sectionInfoForSectionAtIndex(GlobalSectionIndex)
			where operationDirectionForSectionAtIndex(firstInsertedIndex) != nil {
			
			let globalNonPinnableHeight = globalSection.heightOfNonPinningHeaders
			let globalPinnableHeight = globalSection.heightOfPinningHeaders
			let minY = sectionInfo.frame.minY
			
			if targetContentOffset.y + globalPinnableHeight > minY {
				// Need to make the section visible
				targetContentOffset.y = max(globalNonPinnableHeight, minY - globalPinnableHeight)
			}
		}
		
		targetContentOffset.y -= insets.top
		
		layoutLog("\(#function) proposedContentOffset=\(proposedContentOffset) layoutSize=\(layoutSize) availableHeight=\(availableHeight) targetContentOffset=\(targetContentOffset)")
		return targetContentOffset
	}
	
	public override func collectionViewContentSize() -> CGSize {
		layoutLog("\(#function) \(layoutSize)")
		return layoutSize
	}
	
	public override func prepareForCollectionViewUpdates(updateItems: [UICollectionViewUpdateItem]) {
		resetUpdates()
		updateRecorder.record(updateItems, sectionProvider: layoutInfo, oldSectionProvider: oldLayoutInfo)
		processGlobalSectionUpdate()
		adjustContentOffsetDelta()
		
		super.prepareForCollectionViewUpdates(updateItems)
	}
	
	private func resetUpdates() {
		updateRecorder.reset()
	}
	
	/// Finds any global elements that disappeared during the update and records them for deletion.
	///
	/// This becomes necessary when the selected data source of a segmented data source contributes a kind of global element, and then a new data source is selected which does not contribute that kind of global element.
	private func processGlobalSectionUpdate() {
		guard let layoutInfo = self.layoutInfo,
			globalSection = layoutInfo.sectionAtIndex(GlobalSectionIndex),
			oldLayoutInfo = self.oldLayoutInfo,
			oldGlobalSection = oldLayoutInfo.sectionAtIndex(GlobalSectionIndex) else {
				return
		}
		
		processGlobalSectionDecorationUpdate(from: oldGlobalSection, to: globalSection)
		processGlobalSectionSupplementaryUpdate(from: oldGlobalSection, to: globalSection)
	}
	
	private func processGlobalSectionDecorationUpdate(from oldGlobalSection: LayoutSection, to globalSection: LayoutSection) {
		let decorationAttributes = globalSection.decorationAttributesByKind
		let oldDecorationAttributes = oldGlobalSection.decorationAttributesByKind
		let decorationDiff = decorationAttributes.countDiff(with: oldDecorationAttributes)
		for (kind, countDiff) in decorationDiff {
			let count = (decorationAttributes[kind] ?? []).count
			let oldCount = (oldDecorationAttributes[kind] ?? []).count
			if countDiff < 0 {
				let indexPaths = (count..<oldCount).map { NSIndexPath(index: $0) }
				updateRecorder.recordAdditionalDeletedIndexPaths(indexPaths, forElementOf: kind)
			}
			else if countDiff > 0 {
				let indexPaths = (oldCount..<count).map { NSIndexPath(index: $0) }
				updateRecorder.recordAdditionalInsertedIndexPaths(indexPaths, forElementOf: kind)
			}
		}
	}
	
	private func processGlobalSectionSupplementaryUpdate(from oldGlobalSection: LayoutSection, to globalSection: LayoutSection) {
		let supplementaryItems = globalSection.supplementaryItemsByKind
		let oldSupplementaryItems = oldGlobalSection.supplementaryItemsByKind
		let supplementaryDiff = supplementaryItems.countDiff(with: oldSupplementaryItems)
		for (kind, countDiff) in supplementaryDiff {
			let count = (supplementaryItems[kind] ?? []).count
			let oldCount = (oldSupplementaryItems[kind] ?? []).count
			if countDiff < 0 {
				let indexPaths = (count..<oldCount).map { NSIndexPath(index: $0) }
				updateRecorder.recordAdditionalDeletedIndexPaths(indexPaths, forElementOf: kind)
			}
			else if countDiff > 0 {
				let indexPaths = (oldCount..<count).map { NSIndexPath(index: $0) }
				updateRecorder.recordAdditionalInsertedIndexPaths(indexPaths, forElementOf: kind)
			}
		}
	}
	
	private func adjustContentOffsetDelta() {
		guard let collectionView = self.collectionView else {
			return
		}
		let contentOffset = collectionView.contentOffset
		let newContentOffset = targetContentOffsetForProposedContentOffset(contentOffset)
		contentOffsetDelta = CGPoint(x: newContentOffset.x - contentOffset.x, y: newContentOffset.y - contentOffset.y)
	}
	
	public override func finalizeCollectionViewUpdates() {
		super.finalizeCollectionViewUpdates()
		resetUpdates()
		updateSectionDirections.removeAll(keepCapacity: true)
	}
	
	public override func indexPathsToDeleteForDecorationViewOfKind(elementKind: String) -> [NSIndexPath] {
		var superValue = super.indexPathsToDeleteForDecorationViewOfKind(elementKind)
		if let additionalValues = additionalDeletedIndexPathsByKind[elementKind] {
			superValue += additionalValues
		}
		layoutLog("\(#function) kind=\(elementKind) value=\(superValue)")
		return superValue
	}
	
	public override func initialLayoutAttributesForAppearingDecorationElementOfKind(elementKind: String, atIndexPath decorationIndexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
		layoutLog("\(#function) kind=\(elementKind) indexPath=\(decorationIndexPath.debugLogDescription)")
		
		guard let result = layoutInfo?.layoutAttributesForDecorationViewOfKind(elementKind, at: decorationIndexPath)?.copy() as? UICollectionViewLayoutAttributes else {
			return nil
		}
		
		let section = decorationIndexPath.layoutSection
		
		if let direction = operationDirectionForSectionAtIndex(section) {
			return initialLayoutAttributesForAttributes(result, slidingInFrom: direction)
		}
		
		let isInserted = insertedSections.contains(section)
		if isInserted {
			result.alpha = 0
		}
		
		let isReloaded = reloadedSections.contains(section)
		if isReloaded
			&& oldLayoutInfo?.layoutAttributesForDecorationViewOfKind(elementKind, at: decorationIndexPath) == nil {
				result.alpha = 0
		}
		
		return initialLayoutAttributesForAttributes(result)
	}
	
	public override func finalLayoutAttributesForDisappearingDecorationElementOfKind(elementKind: String, atIndexPath decorationIndexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
		layoutLog("\(#function) kind=\(elementKind) indexPath=\(decorationIndexPath.debugLogDescription)")
		
		guard let result = oldLayoutInfo?.layoutAttributesForDecorationViewOfKind(elementKind, at: decorationIndexPath)?.copy() as? UICollectionViewLayoutAttributes else {
			return nil
		}
		
		let section = decorationIndexPath.layoutSection
		
		if let direction = operationDirectionForSectionAtIndex(section) {
			return finalLayoutAttributesForAttributes(result, slidingAwayFrom: direction)
		}
		
		let isRemoved = removedSections.contains(section)
		if isRemoved {
			result.alpha = 0
		}
		
		let isReloaded = reloadedSections.contains(section)
		if isReloaded
			&& layoutInfo?.layoutAttributesForDecorationViewOfKind(elementKind, at: decorationIndexPath) == nil {
				result.alpha = 0
		}
		
		return finalLayoutAttributesForAttributes(result)
	}
	
	public override func initialLayoutAttributesForAppearingSupplementaryElementOfKind(elementKind: String, atIndexPath elementIndexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
		layoutLog("\(#function) kind=\(elementKind) indexPath=\(elementIndexPath.debugLogDescription)")
		
		guard let result = layoutInfo?.layoutAttributesForSupplementaryElementOfKind(elementKind, at: elementIndexPath)?.copy() as? UICollectionViewLayoutAttributes else {
			return nil
		}
		var attributes = result
		
		let section = elementIndexPath.layoutSection
		
		if let direction = operationDirectionForSectionAtIndex(section) {
			if elementKind == CollectionElementKindPlaceholder {
				result.alpha = 0
				return initialLayoutAttributesForAttributes(result)
			}
			return initialLayoutAttributesForAttributes(result, slidingInFrom: direction)
		}
		
		let isInserted = insertedSections.contains(section)
		let isReloaded = reloadedSections.contains(section)
		
		if isInserted {
			attributes.alpha = 0
			attributes = initialLayoutAttributesForAttributes(attributes)
		} else if isReloaded
			&& oldLayoutInfo?.layoutAttributesForSupplementaryElementOfKind(elementKind, at: elementIndexPath) == nil {
				attributes.alpha = 0
		}
		
		return attributes
	}
	
	public override func finalLayoutAttributesForDisappearingSupplementaryElementOfKind(elementKind: String, atIndexPath elementIndexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
		layoutLog("\(#function) kind=\(elementKind) indexPath=\(elementIndexPath.debugLogDescription)")
		
		guard let result = oldLayoutInfo?.layoutAttributesForSupplementaryElementOfKind(elementKind, at: elementIndexPath)?.copy() as? UICollectionViewLayoutAttributes else {
			return nil
		}
		
		let section = elementIndexPath.layoutSection
		
		if let direction = operationDirectionForSectionAtIndex(section) {
			if elementKind == CollectionElementKindPlaceholder {
				result.alpha = 0
				return finalLayoutAttributesForAttributes(result)
			}
			return finalLayoutAttributesForAttributes(result, slidingAwayFrom: direction)
		}
		
		let isRemoved = removedSections.contains(section)
		let isReloaded = reloadedSections.contains(section)
		
		if isRemoved || isReloaded {
			result.alpha = 0
		}
		
		return finalLayoutAttributesForAttributes(result)
	}
	
	public override func initialLayoutAttributesForAppearingItemAtIndexPath(itemIndexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
		layoutLog("\(#function) indexPath=\(itemIndexPath.debugLogDescription)")
		
		guard var result = layoutInfo?.layoutAttributesForCell(at: itemIndexPath)?.copy() as? UICollectionViewLayoutAttributes else {
			return nil
		}
		
		let section = itemIndexPath.layoutSection
		
		if let direction = operationDirectionForSectionAtIndex(section) {
			return initialLayoutAttributesForAttributes(result, slidingInFrom: direction)
		}
		
		let isInserted = insertedSections.contains(section) || insertedIndexPaths.contains(itemIndexPath)
		if isInserted {
			result.alpha = 0
		}
		
		let isReloaded = reloadedSections.contains(section)
		if isReloaded
			&& oldLayoutInfo?.layoutAttributesForCell(at: itemIndexPath) == nil {
				result.alpha = 0
		}
		
		result = initialLayoutAttributesForAttributes(result)
		layoutLog("\(#function) frame=\(result.frame)")
		return result
	}
	
	public override func finalLayoutAttributesForDisappearingItemAtIndexPath(itemIndexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
		layoutLog("\(#function) indexPath=\(itemIndexPath.debugLogDescription)")
		
		guard let result = oldLayoutInfo?.layoutAttributesForCell(at: itemIndexPath)?.copy() as? UICollectionViewLayoutAttributes else {
			return nil
		}
		
		let section = itemIndexPath.layoutSection
		
		if let direction = operationDirectionForSectionAtIndex(section) {
			return finalLayoutAttributesForAttributes(result, slidingAwayFrom: direction)
		}
		
		let isDeletedItem = removedIndexPaths.contains(itemIndexPath)
		let isRemoved = removedSections.contains(section)
		if isDeletedItem || isRemoved {
			result.alpha = 0
		}
		
		let isReloaded = reloadedSections.contains(section)
		if isReloaded
			&& layoutInfo?.layoutAttributesForCell(at: itemIndexPath) == nil {
				// There's no item at this index path, so cross fade
				result.alpha = 0
		}
		
		return finalLayoutAttributesForAttributes(result)
	}
	
	// MARK: - CollectionViewLayoutMeasuring
	
	public func measuredSizeForSupplementaryItem(supplementaryItem: LayoutSupplementaryItem) -> CGSize {
		guard let collectionView = collectionViewWrapper as? WrapperCollectionView,
			dataSource = collectionView.dataSource else {
				return CGSizeZero
		}
		
		measuringAttributes = supplementaryItem.layoutAttributes.copy() as? CollectionViewLayoutAttributes
		measuringAttributes!.hidden = true
		
		let view = dataSource.collectionView!(collectionView, viewForSupplementaryElementOfKind: supplementaryItem.elementKind, atIndexPath: supplementaryItem.indexPath)
		let attributes = view.preferredLayoutAttributesFittingAttributes(measuringAttributes!)
		view.removeFromSuperview()
		
		// Allow regeneration of the layout attributes later
		supplementaryItem.resetLayoutAttributes()
		measuringAttributes = nil
		
		return attributes.frame.size
	}
	
	public func measuredSizeForItem(item: LayoutItem) -> CGSize {
		guard let collectionView = collectionViewWrapper as? WrapperCollectionView,
			dataSource = collectionView.dataSource else {
				return CGSizeZero
		}
		
		measuringAttributes = item.layoutAttributes.copy() as? CollectionViewLayoutAttributes
		measuringAttributes!.hidden = true
		
		let view = dataSource.collectionView(collectionView, cellForItemAtIndexPath: item.indexPath)
		let attributes = view.preferredLayoutAttributesFittingAttributes(measuringAttributes!)
		view.removeFromSuperview()
		
		// Allow regeneration of the layout attributes later
		item.resetLayoutAttributes()
		measuringAttributes = nil
		
		return attributes.frame.size
	}
	
	public func measuredSizeForPlaceholder(placeholderInfo: LayoutPlaceholder) -> CGSize {
		guard let collectionView = collectionViewWrapper as? WrapperCollectionView,
			dataSource = collectionView.dataSource else {
				return CGSizeZero
		}
		
		measuringAttributes = placeholderInfo.layoutAttributes.copy() as? CollectionViewLayoutAttributes
		measuringAttributes!.hidden = true
		
		let view = dataSource.collectionView!(collectionView, viewForSupplementaryElementOfKind: measuringAttributes!.representedElementKind!, atIndexPath: placeholderInfo.indexPath)
		let attributes = view.preferredLayoutAttributesFittingAttributes(measuringAttributes!)
		view.removeFromSuperview()
		
		// Allow regeneration of the layout attributes later
		placeholderInfo.resetLayoutAttributes()
		measuringAttributes = nil
		
		return attributes.frame.size
	}
	
	// MARK: - Helpers
	
	func updateFlagsFromCollectionView() {
		dataSourceHasSnapshotMetrics = collectionView?.dataSource is CollectionDataSourceMetrics
	}
	
	func operationDirectionForSectionAtIndex(sectionIndex: Int) -> SectionOperationDirection? {
		guard !UIAccessibilityIsReduceMotionEnabled() else {
			return nil
		}
		if sectionIndex == GlobalSectionIndex && updateSectionDirections[sectionIndex] == nil {
			return updateSectionDirections[0]
		}
		return updateSectionDirections[sectionIndex]
	}
	
	func sectionInfoForSectionAtIndex(sectionIndex: Int) -> LayoutSection? {
		return layoutInfo?.sectionAtIndex(sectionIndex)
	}
	
	func snapshotMetrics() -> [Int: DataSourceSectionMetrics]? {
		guard dataSourceHasSnapshotMetrics else {
			return nil
		}
		return (collectionView!.dataSource as! CollectionDataSourceMetrics).snapshotMetrics()
	}
	
	func resetLayoutInfo() {
		oldLayoutInfo = layoutInfo
		layoutInfo = BasicLayoutInfo(layout: self)
	}
	
	func createLayoutInfoFromDataSource() {
		resetLayoutInfo()
		
		guard let collectionView = self.collectionView, layoutInfo = self.layoutInfo else {
			return
		}
		
		let contentInset = collectionView.contentInset
		let bounds = collectionView.bounds
		let width = bounds.width - contentInset.width
		let height = bounds.height - contentInset.height
		
		let numberOfSections = collectionView.numberOfSections()
		
		layoutLog("\(#function) numberOfSections = \(numberOfSections)")
		
		layoutInfo.collectionViewSize = bounds.size
		layoutInfo.width = width
		layoutInfo.height = height
		
		guard let layoutMetrics = snapshotMetrics() else {
			return
		}
		
		registerDecorations(from: layoutMetrics)
		
		if let globalMetrics = layoutMetrics[GlobalSectionIndex] {
			// TODO: Section type shouldn't be decided here
//			let sectionInfo = layoutInfo.newSection(sectionIndex: GlobalSectionIndex)
			let sectionInfo = BasicGridLayoutSection()
			layoutInfo.add(sectionInfo, sectionIndex: GlobalSectionIndex)
			populate(sectionInfo, from: globalMetrics)
		}
		
		var placeholder: AnyObject?
		var placeholderInfo: LayoutPlaceholder?
		
		for sectionIndex in 0..<numberOfSections {
			guard let metrics = layoutMetrics[sectionIndex] else {
				continue
			}
			// FIXME: Section type shouldn't be decided here
//			let sectionInfo = layoutInfo.newSection(sectionIndex: sectionIndex)
			let sectionInfo = BasicGridLayoutSection()
			layoutInfo.add(sectionInfo, sectionIndex: sectionIndex)
			
			if let metricsPlaceholder = metrics.placeholder {
				if metricsPlaceholder !== placeholder {
					placeholderInfo = layoutInfo.newPlaceholderStartingAtSectionIndex(sectionIndex)
					// FIXME: Magic number
					placeholderInfo?.height = 200
					placeholderInfo?.hasEstimatedHeight = true
				}
				sectionInfo.placeholderInfo = placeholderInfo
			}
			else {
				placeholderInfo = nil
			}
			
			placeholder = metrics.placeholder
			
			populate(sectionInfo, from: metrics)
		}
	}
	
	private func registerDecorations(from layoutMetrics: [Int: DataSourceSectionMetrics]) {
		for sectionMetrics in layoutMetrics.values {
			registerDecorations(from: sectionMetrics.metrics)
		}
	}
	
	private func registerDecorations(from sectionMetrics: SectionMetrics) {
		for kind in sectionMetrics.decorationsByKind.keys {
			registerClass(CollectionViewSeparatorView.self, forDecorationViewOfKind: kind)
		}
	}

	// TODO: Encapsulate
	/// Subclasses should override to create new sections from the metrics.
	public func populate(section: LayoutSection, from metrics: DataSourceSectionMetrics) {
		guard let collectionView = self.collectionView,
			let gridMetrics = metrics.metrics as? GridSectionMetrics,
			section = section as? GridLayoutSection else {
				return
		}
		
		let sectionIndex = section.sectionIndex
		
		section.reset()
		section.applyValues(from: gridMetrics)
		section.resolveMissingValuesFromTheme()
		
		func setupSupplementaryMetrics(supplementaryMetrics: SupplementaryItem) {
			// FIXME: Supplementary item kind shouldn't be decided here
			let supplementaryItem = BasicGridSupplementaryItem(elementKind: supplementaryMetrics.elementKind)
			supplementaryItem.applyValues(from: supplementaryMetrics)
			section.add(supplementaryItem)
		}
		
		for supplementaryItem in metrics.supplementaryItemsByKind.contents {
			setupSupplementaryMetrics(supplementaryItem)
		}
		
		let isGlobalSection = sectionIndex == GlobalSectionIndex
		let numberOfItemsInSection = isGlobalSection ? 0 : collectionView.numberOfItemsInSection(sectionIndex)
		
		layoutLog("\(#function) section \(sectionIndex): numberOfItems=\(numberOfItemsInSection) hasPlaceholder=\(metrics.placeholder != nil)")
		
		var rowHeight = gridMetrics.rowHeight ?? AutomaticLength
		let isVariableRowHeight = rowHeight == AutomaticLength
		if isVariableRowHeight {
			rowHeight = gridMetrics.estimatedRowHeight
		}
		
		let columnWidth = section.columnWidth
		
		for itemIndex in 0..<numberOfItemsInSection {
			let itemInfo = GridLayoutItem()
			itemInfo.itemIndex = itemIndex
			itemInfo.frame = CGRect(x: 0, y: 0, width: columnWidth, height: rowHeight)
			if isVariableRowHeight {
				itemInfo.hasEstimatedHeight = true
			}
			section.add(itemInfo)
		}
	}
	
	func buildLayout() {
		guard !layoutDataIsValid && !isBuildingLayout,
			let collectionView = self.collectionView else {
				return
		}
		isBuildingLayout = true
		defer {
			isBuildingLayout = false
		}
		// Create the collection view wrapper that will be used for measuring
		collectionViewWrapper = WrapperCollectionView(collectionView: collectionView, mapping: nil, isUsedForMeasuring: true)
		
		layoutLog("\(#function)")
		
		updateFlagsFromCollectionView()
		
		createLayoutInfoFromDataSource()
		layoutDataIsValid = true
		
		guard let layoutInfo = self.layoutInfo else {
			return
		}
		
		layoutSize = CGSizeZero
		
		let contentInset = collectionView.contentInset
		var contentOffset = collectionView.contentOffset
		let bounds = collectionView.bounds
		let width = bounds.width - contentInset.width
		let height = bounds.height - contentInset.height
		
		layoutInfo.width = width
		layoutInfo.height = height
		layoutInfo.contentOffset.x = contentOffset.x + contentInset.left
		layoutInfo.contentOffset.y = contentOffset.y + contentInset.top
		layoutInfo.contentInset = contentInset
		layoutInfo.bounds = bounds
		
		layoutInfo.prepareForLayout()
		
		var start = CGPointZero
		
		let layoutEngine = GridLayoutEngine(layoutInfo: layoutInfo)
		start = layoutEngine.layoutWithOrigin(start, layoutSizing: layoutInfo, invalidationContext: nil)
		
		var layoutHeight = start.y
		
		// The layoutHeight is the total height of the layout including any placeholders in their default size. Determine how much space is left to be shared out among the placeholders
		layoutInfo.heightAvailableForPlaceholders = max(0, height - layoutHeight)
		
		if let globalSection = sectionInfoForSectionAtIndex(GlobalSectionIndex) {
			layoutHeight = globalSection.targetLayoutHeightForProposedLayoutHeight(layoutHeight, layoutInfo: layoutInfo)
		}
		
		layoutSize = CGSize(width: width, height: layoutHeight)
		
		contentOffset = targetContentOffsetForProposedContentOffset(contentOffset)
		layoutInfo.updateSpecialItemsWithContentOffset(contentOffset, invalidationContext: nil)
		
		layoutInfo.finalizeLayout()
		
		collectionViewWrapper = nil
		
		layoutLog("\(#function) Final layout height: \(layoutHeight)")
	}
	
	private func initialLayoutAttributesForAttributes(attributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
		attributes.frame.offsetInPlace(dx: -contentOffsetDelta.x, dy: -contentOffsetDelta.y)
		return attributes
	}
	
	private func finalLayoutAttributesForAttributes(attributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
		let deltaX = contentOffsetDelta.x, deltaY = contentOffsetDelta.y
		var frame = attributes.frame
		if let attributes = attributes as? CollectionViewLayoutAttributes
			where attributes.isPinned {
				let newX = max(attributes.unpinnedOrigin.x, frame.minX + deltaX)
				frame.origin.x = newX
				let newY = max(attributes.unpinnedOrigin.y, frame.minY + deltaY)
				frame.origin.y = newY
		} else {
			frame.offsetInPlace(dx: deltaX, dy: deltaY)
		}
		
		attributes.frame = frame
		
		return attributes
	}
	
	private func initialLayoutAttributesForAttributes(attributes: UICollectionViewLayoutAttributes, slidingInFrom direction: SectionOperationDirection) -> UICollectionViewLayoutAttributes {
		var frame = attributes.frame
		let cvBounds = collectionView?.bounds ?? CGRectZero
		switch direction {
		case .Left:
			frame.origin.x -= cvBounds.size.width
		default:
			frame.origin.x += cvBounds.size.width
		}
		attributes.frame = frame
		return initialLayoutAttributesForAttributes(attributes)
	}
	
	private func finalLayoutAttributesForAttributes(attributes: UICollectionViewLayoutAttributes, slidingAwayFrom direction: SectionOperationDirection) -> UICollectionViewLayoutAttributes {
		var frame = attributes.frame
		let bounds = collectionView?.bounds ?? CGRectZero
		
		switch direction {
		case .Left:
			frame.origin.x += bounds.size.width
		default:
			frame.origin.x -= bounds.size.width
		}
		attributes.frame = frame
		attributes.alpha = 0
		return attributes
	}
	
	// MARK: - CollectionDataSourceDelegate
	
	public func dataSource(dataSource: CollectionDataSource, didInsertSections sections: NSIndexSet, direction: SectionOperationDirection?) {
		for sectionIndex in sections {
			updateSectionDirections[sectionIndex] = direction
		}
	}
	
	public func dataSource(dataSource: CollectionDataSource, didRemoveSections sections: NSIndexSet, direction: SectionOperationDirection?) {
		for sectionIndex in sections {
			updateSectionDirections[sectionIndex] = direction
		}
	}
	
	public func dataSource(dataSource: CollectionDataSource, didMoveSectionFrom oldSection: Int, to newSection: Int, direction: SectionOperationDirection?) {
		updateSectionDirections[oldSection] = direction
		updateSectionDirections[newSection] = direction
	}
	
}

// MARK: - CollectionUpdateInfoWrapper

extension CollectionViewLayout: CollectionUpdateInfoWrapper {
	
	public var updateInfo: CollectionUpdateInfo {
		get {
			return updateRecorder.updateInfo
		}
		set {
			updateRecorder.updateInfo = newValue
		}
	}
	
}
