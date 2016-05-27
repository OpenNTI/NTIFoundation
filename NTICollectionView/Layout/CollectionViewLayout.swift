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

private let estimatedPlaceholderHeight: CGFloat = 200

private let dragShadowHeight: CGFloat = 19

private let scrollSpeedMaxMultiplier: CGFloat = 4

private let framesPerSecond: CGFloat = 60

private enum AutoScrollDirection: String {
	
	case up, down, left, right
	
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
	
	/// - note: `nil` until `resetLayoutInfo()` has been called for the first time.
	private var layoutInfo: LayoutInfo!
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
//		supplementaryItem.resetLayoutAttributes()
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
//		item.resetLayoutAttributes()
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
//		placeholderInfo.resetLayoutAttributes()
		measuringAttributes = nil
		
		return attributes.frame.size
	}
	
	// MARK: - Drag & Drop
	
	private let scrollDirection: UICollectionViewScrollDirection = .Vertical
	
	private var scrollingSpeed: CGFloat = 0
	
	private var scrollingTriggerEdgeInsets: UIEdgeInsets = .zero
	
	private var selectedItemIndexPath: NSIndexPath?
	
	private var sourceItemIndexPath: NSIndexPath?
	
	private var currentView: UIView!
	
	private var currentViewCenter: CGPoint = .zero
	
	private var panTranslationInCollectionView: CGPoint = .zero
	
	private var displayLink: CADisplayLink?
	
	private var autoscrollDirection: AutoScrollDirection?
	
	private var autoscrollBounds: CGRect = .zero
	
	private var dragBounds: CGRect = .zero
	
	private var dragCellSize: CGSize = .zero
	
	
	public func beginDraggingItem(at indexPath: NSIndexPath) {
		guard let
			collectionView = self.collectionView,
			cell = collectionView.cellForItemAtIndexPath(indexPath) else {
				return
		}
		
		var dragFrame = cell.frame
		dragCellSize = dragFrame.size
		
		let snapshotView = cell.snapshotViewAfterScreenUpdates(true)
		
		let shadowView = UIImageView(frame: CGRectInset(dragFrame, 0, -dragShadowHeight))
		if let image = UIImage(named: "DragShadow") {
			shadowView.image = image.resizableImageWithCapInsets(UIEdgeInsets(top: dragShadowHeight, left: 1, bottom: dragShadowHeight, right: 1))
		}
		shadowView.opaque = false
		
		dragFrame.origin = CGPoint(x: 0, y: dragShadowHeight)
		snapshotView.frame = dragFrame
		shadowView.addSubview(snapshotView)
		currentView = shadowView
		
		currentView.center = cell.center
		collectionView.addSubview(currentView)
		
		currentViewCenter = currentView.center
		selectedItemIndexPath = indexPath
		sourceItemIndexPath = indexPath
		
		layoutInfo.mutateItem(at: indexPath) { (item) in
			item.isDragging = true
		}
		
		let context = CollectionViewLayoutInvalidationContext()
		context.invalidateItemsAtIndexPaths([indexPath])
		invalidateLayoutWithContext(context)
		
		autoscrollBounds = CGRectZero
		autoscrollBounds.size = collectionView.bounds.size
		autoscrollBounds = UIEdgeInsetsInsetRect(autoscrollBounds, scrollingTriggerEdgeInsets)
		
		let collectionViewFrame = collectionView.frame
		let collectionViewWidth = collectionViewFrame.width
		let collectionViewHeight = collectionViewFrame.height
		
		dragBounds = CGRect(x: dragCellSize.width/2, y: dragCellSize.height/2, width: collectionViewWidth - dragCellSize.width, height: collectionViewHeight - dragCellSize.height)
	}
	
	public func cancelDragging() {
		guard let
			currentView = self.currentView,
			sourceItemIndexPath = self.sourceItemIndexPath,
			selectedItemIndexPath = self.selectedItemIndexPath else {
				return
		}
		
		let sourceSectionIndex = sourceItemIndexPath.section
		let destinationSectionIndex = selectedItemIndexPath.section
		
		guard var
			sourceSection = sectionInfoForSectionAtIndex(sourceSectionIndex),
			destinationSection = sectionInfoForSectionAtIndex(destinationSectionIndex) else {
				return
		}
		
		currentView.removeFromSuperview()
		
		destinationSection.phantomCellIndex = nil
		destinationSection.phantomCellSize = .zero
		
		let fromIndex = sourceItemIndexPath.item
		
		sourceSection.mutateItem(at: fromIndex) { (item) in
			item.isDragging = false
		}
		
		let context = CollectionViewLayoutInvalidationContext()
		// TODO: Layout source and destination sections
		layoutInfo.setSection(sourceSection, at: sourceSectionIndex)
		layoutInfo.setSection(destinationSection, at: destinationSectionIndex)
		invalidateLayoutWithContext(context)
	}
	
	public func endDragging() {
		guard let
			currentView = self.currentView,
			fromIndexPath = self.sourceItemIndexPath,
			var toIndexPath = self.selectedItemIndexPath else {
				return
		}
		
		currentView.removeFromSuperview()
		
		let sourceSectionIndex = fromIndexPath.section
		let destinationSectionIndex = toIndexPath.section
		
		guard var
			sourceSection = sectionInfoForSectionAtIndex(sourceSectionIndex),
			destinationSection = sectionInfoForSectionAtIndex(destinationSectionIndex) else {
				return
		}
		
		destinationSection.phantomCellIndex = nil
		destinationSection.phantomCellSize = .zero
		
		let fromIndex = fromIndexPath.item
		var toIndex = toIndexPath.item
		
		sourceSection.mutateItem(at: fromIndex) { (item) in
			item.isDragging = false
		}
		
		var needsUpdate = true
		
		if sourceSection.isEqual(to: destinationSection) {
			if fromIndex == toIndex {
				needsUpdate = false
			}
			else if fromIndex < toIndex {
				toIndex -= 1
				toIndexPath = NSIndexPath(forItem: toIndex, inSection: destinationSectionIndex)
			}
		}
		
		if needsUpdate {
			// TODO: Modify source and destination section items
			
			// Tell the data source, but don't animate because we've already updated everything in place
			UIView.performWithoutAnimation {
				guard let
					collectionView = self.collectionView,
					dataSource = collectionView.dataSource as? CollectionDataSource else {
						return
				}
				
				dataSource.collectionView(collectionView, moveItemAt: fromIndexPath, to: toIndexPath)
			}
		}
		
		let context = CollectionViewLayoutInvalidationContext()
		// Layout source and destination sections
		layoutInfo.setSection(sourceSection, at: sourceSectionIndex)
		layoutInfo.setSection(destinationSection, at: destinationSectionIndex)
		invalidateLayoutWithContext(context)
		
		selectedItemIndexPath = nil
	}
	
	private func invalidateScrollTimer() {
		guard let displayLink = self.displayLink else {
			return
		}
		
		if !displayLink.paused {
			displayLink.invalidate()
		}
		
		self.displayLink = nil
	}
	
	private func setupScrollTimer(in direction: AutoScrollDirection) {
		if let displayLink = self.displayLink where !displayLink.paused {
			if autoscrollDirection == direction {
				return
			}
		}
		
		invalidateScrollTimer()
		
		displayLink = CADisplayLink(target: self, selector: #selector(CollectionViewLayout.handleScroll(_:)))
		autoscrollDirection = direction
		
		displayLink?.addToRunLoop(.mainRunLoop(), forMode: NSRunLoopCommonModes)
	}
	
	// Tight loop, allocate memory sparely, even if they are stack allocation
	public func handleScroll(displayLink: CADisplayLink) {
		guard let
			direction = autoscrollDirection,
			collectionView = self.collectionView else {
			return
		}
		
		let frameSize = collectionView.bounds.size
		let contentSize = collectionView.contentSize
		let contentOffset = collectionView.contentOffset
		let contentInset = collectionView.contentInset
		
		let insetBoundsSize = CGSize(width: frameSize.width - contentInset.width, height: frameSize.height - contentInset.height)
		
		// Need to keep the distance as an integer, because the contentOffset property is automatically rounded
		// This would cause the view center to begin to diverge from the scrolling and appear to slip away from under the user's finger
		var distance = rint(scrollingSpeed / framesPerSecond)
		var translation = CGPoint.zero
		
		switch direction {
		case .up:
			distance = -distance
			let minY: CGFloat = 0.0
			let posY = contentOffset.y + contentInset.top
			
			if (posY + distance) <= minY {
				distance = -posY
			}
			
			translation = CGPoint(x: 0, y: distance)
			
		case .down:
			let maxY = contentSize.height - insetBoundsSize.height
			let posY = contentOffset.y + contentInset.top
			
			if (posY + distance) >= maxY {
				distance = maxY - posY
			}
			
			translation = CGPoint(x: 0, y: distance)
			
		case .left:
			distance = -distance
			let minX: CGFloat = 0
			let posX = contentOffset.x + contentInset.left
			
			if (posX + distance) <= minX {
				distance = -posX
			}
			
			translation = CGPoint(x: distance, y: 0)
			
		case .right:
			let maxX = contentSize.width - insetBoundsSize.width
			let posX = contentOffset.x + contentInset.left
			
			if (contentOffset.x + distance) >= maxX {
				distance = maxX - posX
			}
			
			translation = CGPoint(x: distance, y: 0)
		}
		
		currentViewCenter = currentViewCenter + translation
		currentView.center = pointConstrainedToDragBounds(currentViewCenter + panTranslationInCollectionView)
		collectionView.contentOffset = contentOffset + translation
	}
	
	private func pointConstrainedToDragBounds(viewCenter: CGPoint) -> CGPoint {
		var viewCenter = viewCenter
		
		if scrollDirection == .Vertical {
			let left = dragBounds.minX
			let right = dragBounds.maxX
			if viewCenter.x < left {
				viewCenter.x = left
			}
			else if viewCenter.x > right {
				viewCenter.x = right
			}
		}
		
		return viewCenter
	}
	
	
	public func handlePanGesture(gestureRecognizer: UIPanGestureRecognizer) {
		guard let collectionView = self.collectionView else {
			return
		}
		
		let contentOffset = collectionView.contentOffset
		
		switch gestureRecognizer.state {
		case .Began:
			panTranslationInCollectionView = gestureRecognizer.translationInView(collectionView)
			let viewCenter = currentViewCenter + panTranslationInCollectionView
			
			currentView.center = pointConstrainedToDragBounds(viewCenter)
			
			makeSpaceForDraggedCell()
			
			let location = gestureRecognizer.locationInView(collectionView)
			
			switch scrollDirection {
			case .Vertical:
				let y = location.y - contentOffset.y
				let top = autoscrollBounds.minY
				let bottom = autoscrollBounds.maxY
				
				if y < top {
					scrollingSpeed = 300 * ((top - y) / scrollingTriggerEdgeInsets.top) * scrollSpeedMaxMultiplier
					setupScrollTimer(in: .up)
				}
				else if y > bottom {
					scrollingSpeed = 300 * ((y - bottom) / scrollingTriggerEdgeInsets.bottom) * scrollSpeedMaxMultiplier
					setupScrollTimer(in: .down)
				}
				else {
					invalidateScrollTimer()
				}
				
			case .Horizontal:
				let x = location.x - contentOffset.x
				let left = autoscrollBounds.minX
				let right = autoscrollBounds.maxX
				
				if viewCenter.x < left {
					scrollingSpeed = 300 * ((left - x) / scrollingTriggerEdgeInsets.left) * scrollSpeedMaxMultiplier
					setupScrollTimer(in: .left)
				}
				else if viewCenter.x > right {
					scrollingSpeed = 300 * ((x - right) / scrollingTriggerEdgeInsets.right) * scrollSpeedMaxMultiplier
					setupScrollTimer(in: .right)
				}
				else {
					invalidateScrollTimer()
				}
			}
			
		case .Cancelled, .Ended:
			invalidateScrollTimer()
			
		default:
			break
		}
	}
	
	private func makeSpaceForDraggedCell() {
		guard let
			collectionView = self.collectionView,
			dataSource = collectionView.dataSource as? CollectionDataSource,
			sourceItemIndexPath = self.sourceItemIndexPath,
			previousIndexPath = selectedItemIndexPath,
			var newIndexPath = collectionView.indexPathForItemAtPoint(currentView.center) else {
				return
		}
		
		let oldSectionIndex = previousIndexPath.section
		let newSectionIndex = newIndexPath.section
		
		guard var
			oldSection = sectionInfoForSectionAtIndex(oldSectionIndex),
			newSection = sectionInfoForSectionAtIndex(newSectionIndex) else {
				return
		}
		
		 // If we've already made space for the cell, all indexes in that section need to be incremented by 1
		if oldSection.phantomCellIndex == previousIndexPath.item
			&& newSectionIndex == oldSectionIndex
			&& newIndexPath.item >= oldSection.phantomCellIndex ?? NSNotFound {
			newIndexPath = NSIndexPath(forItem: newIndexPath.item+1, inSection: newSectionIndex)
		}
		
		guard newIndexPath != previousIndexPath else {
			return
		}
		
		guard dataSource.collectionView(collectionView, canMoveItemAt: sourceItemIndexPath, to: newIndexPath) else {
				return dragLog(#function, message: "Can't MOVE from \(sourceItemIndexPath) to \(newIndexPath)")
		}
		
		if !oldSection.isEqual(to: newSection) {
			oldSection.phantomCellIndex = nil
			oldSection.phantomCellSize = .zero
		}
		newSection.phantomCellIndex = newIndexPath.item
		newSection.phantomCellSize = dragCellSize
		selectedItemIndexPath = newIndexPath
		
		dragLog(#function, message: "newIndexPath = \(newIndexPath.debugLogDescription) previousIndexPath = \(previousIndexPath.debugLogDescription) phantomCellIndex = \(newSection.phantomCellIndex ?? NSNotFound)")
		
		let context = CollectionViewLayoutInvalidationContext()
		
		// TODO: Layout sections
		layoutInfo.setSection(oldSection, at: oldSectionIndex)
		layoutInfo.setSection(newSection, at: newSectionIndex)
		
		invalidateLayoutWithContext(context)
	}
	
	// MARK: - UICollectionViewLayout
	
	public override class func layoutAttributesClass() -> AnyClass {
		return CollectionViewLayoutAttributes.self
	}
	
	public override class func invalidationContextClass() -> AnyClass {
		return CollectionViewLayoutInvalidationContext.self
	}
	
	// This is necessarily called before `resetLayoutInfo` (from `loadView`)
	public override func invalidateLayoutWithContext(context: UICollectionViewLayoutInvalidationContext) {
		defer {
			super.invalidateLayoutWithContext(context)
		}
		
		guard let collectionView = self.collectionView else {
			return
		}
		
		let invalidateDataSourceCounts = context.invalidateDataSourceCounts
		var invalidateEverything = context.invalidateEverything
		
		// The collectionView has changed width, re-evaluate the layout
		if layoutInfo?.collectionViewSize.width != collectionView.bounds.size.width {
			invalidateEverything = true
		}
		
		layoutLog("\(#function) invalidateDataSourceCounts = \(invalidateDataSourceCounts.debugLogDescription) invalidateEverything = \(invalidateEverything.debugLogDescription)")
		
		if invalidateEverything || (layoutDataIsValid && invalidateDataSourceCounts) {
			layoutDataIsValid = false
		}
		
		guard let context = context as? CollectionViewLayoutInvalidationContext else {
			return
		}
		
		// If the layout data is valid, but we've been asked to update the metrics, do that
		if layoutDataIsValid && context.invalidateMetrics {
			for (kind, supplementaryIndexPaths) in context.invalidatedSupplementaryIndexPaths ?? [:] {
				for indexPath in supplementaryIndexPaths {
					invalidateMetricsForElement(ofKind: kind, at: indexPath, in: context)
				}
			}
			for indexPath in context.invalidatedItemIndexPaths ?? [] {
				invalidateMetricsForItem(at: indexPath, in: context)
			}
		}
		
		if layoutDebugging {
			for (kind, indexPaths) in context.invalidatedSupplementaryIndexPaths ?? [:] {
				let result = indexPaths.map { $0.debugLogDescription }
				let resultStr = result.joinWithSeparator(", ")
				debugPrint("\(#function) \(kind) invalidated supplementary indexPaths: \(resultStr)")
			}
		}
	}
	
	public func invalidateMetricsForItem(at indexPath: NSIndexPath, in context: CollectionViewLayoutInvalidationContext) {
		guard let cell = collectionView?.cellForItemAtIndexPath(indexPath) else {
			return
		}
		
		let attributes = layoutInfo.layoutAttributesForCell(at: indexPath)?.copy() as! CollectionViewLayoutAttributes
		attributes.shouldCalculateFittingSize = true
		
		let newAttributes = cell.preferredLayoutAttributesFittingAttributes(attributes)
		let newSize = newAttributes.frame.size
		
		guard newSize != attributes.frame.size else {
			return
		}
		
		layoutInfo.setSize(newSize, forItemAt: indexPath, invalidationContext: context)
	}
	
	private func invalidateMetricsForElement(ofKind kind: String, at indexPath: NSIndexPath, in context: CollectionViewLayoutInvalidationContext) {
		guard let view = collectionView?._supplementaryViewOfKind(kind, at: indexPath) else {
			return
		}
		
		let attributes = layoutInfo.layoutAttributesForSupplementaryElementOfKind(kind, at: indexPath)?.copy() as! CollectionViewLayoutAttributes
		attributes.shouldCalculateFittingSize = true
		
		let newAttributes = view.preferredLayoutAttributesFittingAttributes(attributes)
		let newSize = newAttributes.frame.size
		
		guard newSize != attributes.frame.size else {
			return
		}
		
		layoutInfo.setSize(newSize, forElementOfKind: kind, at: indexPath, invalidationContext: context)
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
		guard let collectionView = self.collectionView else {
			return nil
		}
		
		let contentOffset = targetContentOffsetForProposedContentOffset(collectionView.contentOffset)
		layoutInfo.contentInset = collectionView.contentInset
		layoutInfo.bounds = collectionView.bounds
		layoutInfo.updateSpecialItemsWithContentOffset(contentOffset, invalidationContext: nil)
		
		var result: [CollectionViewLayoutAttributes] = []
		for sectionInfo in layoutInfo.sections {
			result += sectionInfo.layoutAttributes.filter { $0.frame.intersects(rect) }
		}
		
		for attributes in result {
			finalizeConfiguration(of: attributes)
			
			layoutLog("\(#function) \(attributes.debugLogDescription)")
		}
		
		return result
	}
	
	public override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
		let sectionIndex = indexPath.section
		
		guard sectionIndex >= 0 && sectionIndex < layoutInfo.numberOfSections else {
			return nil
		}
		
		let attributes: CollectionViewLayoutAttributes
		
		if let measuringAttributes = self.measuringAttributes
			where measuringAttributes.indexPath == indexPath {
			attributes = measuringAttributes
			
			layoutLog("\(#function) indexPath=\(indexPath.debugLogDescription) measuringAttributes=\(measuringAttributes)")
		}
		else if let infoAttributes = layoutInfo.layoutAttributesForCell(at: indexPath) {
			attributes = infoAttributes
			
			layoutLog("\(#function) indexPath=\(indexPath.debugLogDescription) attributes=\(attributes)")
		}
		else {
			return nil
		}
		
		finalizeConfiguration(of: attributes)
		
		return attributes
	}
	
	public override func layoutAttributesForSupplementaryViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
		let attributes: CollectionViewLayoutAttributes
		
		if let measuringAttributes = self.measuringAttributes
			where measuringAttributes.indexPath == indexPath
				&& measuringAttributes.representedElementKind == elementKind {
			attributes = measuringAttributes
			
			layoutLog("\(#function) measuringAttributes=\(measuringAttributes)")
		}
		else if let infoAttributes = layoutInfo.layoutAttributesForSupplementaryElementOfKind(elementKind, at: indexPath) {
			attributes = infoAttributes
			
			layoutLog("\(#function) indexPath=\(indexPath.debugLogDescription) attributes=\(attributes)")
		}
		else {
			preconditionFailure("We should ALWAYS find layout attributes.")
		}
		
		finalizeConfiguration(of: attributes)
		
		return attributes
	}
	
	public override func layoutAttributesForDecorationViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
		return layoutInfo.layoutAttributesForDecorationViewOfKind(elementKind, at: indexPath)
	}
	
	private func finalizeConfiguration(of attributes: CollectionViewLayoutAttributes) {
		let indexPath = attributes.indexPath
		
		switch attributes.representedElementCategory {
		case .Cell:
			attributes.isEditing = isEditing ? canEditItem(at: indexPath) : false
			attributes.isMovable = isEditing ? canMoveItem(at: indexPath) : false
		default:
			attributes.isEditing = isEditing
		}
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
		
		layoutInfo.contentInset = collectionView.contentInset
		layoutInfo.bounds = collectionView.bounds
		layoutInfo.updateSpecialItemsWithContentOffset(contentOffset, invalidationContext: context)
		
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
		
		if let firstInsertedIndex = insertedSections.first,
			sectionInfo = sectionInfoForSectionAtIndex(firstInsertedIndex),
			globalSection = sectionInfoForSectionAtIndex(globalSectionIndex)
			where operationDirectionForSectionAtIndex(firstInsertedIndex) != nil {
			
			let minY = sectionInfo.frame.minY
			targetContentOffset = globalSection.targetContentOffsetForProposedContentOffset(targetContentOffset, firstInsertedSectionMinY: minY)
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
		guard let globalSection = layoutInfo.sectionAtIndex(globalSectionIndex),
			oldLayoutInfo = self.oldLayoutInfo,
			oldGlobalSection = oldLayoutInfo.sectionAtIndex(globalSectionIndex) else {
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
		
		guard let result = layoutInfo.layoutAttributesForDecorationViewOfKind(elementKind, at: decorationIndexPath)?.copy() as? UICollectionViewLayoutAttributes else {
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
			&& layoutInfo.layoutAttributesForDecorationViewOfKind(elementKind, at: decorationIndexPath) == nil {
				result.alpha = 0
		}
		
		return finalLayoutAttributesForAttributes(result)
	}
	
	public override func initialLayoutAttributesForAppearingSupplementaryElementOfKind(elementKind: String, atIndexPath elementIndexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
		layoutLog("\(#function) kind=\(elementKind) indexPath=\(elementIndexPath.debugLogDescription)")
		
		guard let result = layoutInfo.layoutAttributesForSupplementaryElementOfKind(elementKind, at: elementIndexPath)?.copy() as? UICollectionViewLayoutAttributes else {
			return nil
		}
		var attributes = result
		
		let section = elementIndexPath.layoutSection
		
		if let direction = operationDirectionForSectionAtIndex(section) {
			if elementKind == collectionElementKindPlaceholder {
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
			if elementKind == collectionElementKindPlaceholder {
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
		
		guard var result = layoutInfo.layoutAttributesForCell(at: itemIndexPath)?.copy() as? UICollectionViewLayoutAttributes else {
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
			&& layoutInfo.layoutAttributesForCell(at: itemIndexPath) == nil {
				// There's no item at this index path, so cross fade
				result.alpha = 0
		}
		
		return finalLayoutAttributesForAttributes(result)
	}
	
	// MARK: - Helpers
	
	func updateFlagsFromCollectionView() {
		dataSourceHasSnapshotMetrics = collectionView?.dataSource is CollectionDataSourceMetrics
	}
	
	func operationDirectionForSectionAtIndex(sectionIndex: Int) -> SectionOperationDirection? {
		guard !UIAccessibilityIsReduceMotionEnabled() else {
			return nil
		}
		
		return updateSectionDirections[sectionIndex]
	}
	
	func sectionInfoForSectionAtIndex(sectionIndex: Int) -> LayoutSection? {
		return layoutInfo.sectionAtIndex(sectionIndex)
	}
	
	func snapshotMetrics() -> [Int: DataSourceSectionMetricsProviding]? {
		guard dataSourceHasSnapshotMetrics else {
			return nil
		}
		return (collectionView!.dataSource as! CollectionDataSourceMetrics).snapshotMetrics()
	}
	
	private func registerDecorations(from layoutMetrics: [Int: DataSourceSectionMetricsProviding]) {
		for sectionMetrics in layoutMetrics.values {
			registerDecorations(from: sectionMetrics.metrics)
		}
	}
	
	private func registerDecorations(from sectionMetrics: SectionMetrics) {
		for kind in sectionMetrics.decorationsByKind.keys {
			registerClass(CollectionViewSeparatorView.self, forDecorationViewOfKind: kind)
		}
	}
	
	func buildLayout() {
		guard !layoutDataIsValid && !isBuildingLayout,
			let collectionView = self.collectionView else {
				return
		}
		
		isBuildingLayout = true
		defer { isBuildingLayout = false }
		
		// Create the collection view wrapper that will be used for measuring
		collectionViewWrapper = WrapperCollectionView(collectionView: collectionView, mapping: nil, isUsedForMeasuring: true)
		defer { collectionViewWrapper = nil }
		
		layoutLog("\(#function)")
		
		updateFlagsFromCollectionView()
		
		createLayoutInfoFromDataSource()
		
		layoutInfo.isEditing = isEditing
		
		layoutDataIsValid = true
		
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
		
		if let globalSection = sectionInfoForSectionAtIndex(globalSectionIndex) {
			layoutHeight = globalSection.targetLayoutHeightForProposedLayoutHeight(layoutHeight, layoutInfo: layoutInfo)
		}
		
		layoutSize = CGSize(width: width, height: layoutHeight)
		
		contentOffset = targetContentOffsetForProposedContentOffset(contentOffset)
		layoutInfo.updateSpecialItemsWithContentOffset(contentOffset, invalidationContext: nil)
		
		layoutInfo.finalizeLayout()
		
		layoutLog("\(#function) Final layout height: \(layoutHeight)")
	}
	
	func createLayoutInfoFromDataSource() {
		resetLayoutInfo()
		
		guard let collectionView = self.collectionView else {
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
		
		if let globalMetrics = layoutMetrics[globalSectionIndex] {
			// TODO: Section type shouldn't be decided here
			var sectionInfo: LayoutSection = BasicGridLayoutSection()
			sectionInfo.sectionIndex = globalSectionIndex
			populate(&sectionInfo, from: globalMetrics)
			layoutInfo.add(sectionInfo, sectionIndex: globalSectionIndex)
		}
		
		var placeholder: AnyObject?
		var placeholderInfo: LayoutPlaceholder?
		
		for sectionIndex in 0..<numberOfSections {
			guard let metrics = layoutMetrics[sectionIndex] else {
				continue
			}
			
			// FIXME: Section type shouldn't be decided here
			var sectionInfo: LayoutSection = BasicGridLayoutSection()
			sectionInfo.sectionIndex = sectionIndex
			
			if let metricsPlaceholder = metrics.placeholder {
				if metricsPlaceholder !== placeholder {
					placeholderInfo = layoutInfo.newPlaceholderStartingAtSectionIndex(sectionIndex)
					placeholderInfo?.height = estimatedPlaceholderHeight
					placeholderInfo?.hasEstimatedHeight = true
				}
				
				sectionInfo.placeholderInfo = placeholderInfo
			}
			else {
				placeholderInfo = nil
			}
			
			placeholder = metrics.placeholder
			
			populate(&sectionInfo, from: metrics)

			layoutInfo.add(sectionInfo, sectionIndex: sectionIndex)
		}
	}
	
	/// - postcondition: `layoutInfo` is not `nil`.
	func resetLayoutInfo() {
		if layoutInfo != nil {
			oldLayoutInfo = layoutInfo
		}
		
		layoutInfo = BasicLayoutInfo(layoutMeasure: self)
		
		guard layoutInfo != nil else {
			preconditionFailure("Could not create layout info.")
		}
	}
	
	// TODO: Abstract somewhere else
	public func populate(inout section: LayoutSection, from metrics: DataSourceSectionMetricsProviding) {
		guard let collectionView = self.collectionView,
			let gridMetrics = metrics.metrics as? GridSectionMetrics,
			var gridSection = section as? GridLayoutSection else {
				return
		}
		
		let sectionIndex = gridSection.sectionIndex
		
		gridSection.reset()
		gridSection.applyValues(from: gridMetrics)
		gridSection.metrics.resolveMissingValuesFromTheme()
		
		func setupSupplementaryMetrics(supplementaryMetrics: SupplementaryItem) {
			// FIXME: Supplementary item kind shouldn't be decided here
			var supplementaryItem = GridLayoutSupplementaryItem(supplementaryItem: supplementaryMetrics)
			supplementaryItem.applyValues(from: gridSection.metrics)
			gridSection.add(supplementaryItem)
		}
		
		for supplementaryItem in metrics.supplementaryItemsByKind.contents {
			setupSupplementaryMetrics(supplementaryItem)
		}
		
		let isGlobalSection = sectionIndex == globalSectionIndex
		let numberOfItemsInSection = isGlobalSection ? 0 : collectionView.numberOfItemsInSection(sectionIndex)
		
		layoutLog("\(#function) section \(sectionIndex): numberOfItems=\(numberOfItemsInSection) hasPlaceholder=\(metrics.placeholder != nil)")
		
		var rowHeight = gridMetrics.rowHeight ?? automaticLength
		let isVariableRowHeight = rowHeight == automaticLength
		if isVariableRowHeight {
			rowHeight = gridMetrics.estimatedRowHeight
		}
		
		let columnWidth = gridSection.columnWidth
		
		for itemIndex in 0..<numberOfItemsInSection {
			var itemInfo = GridLayoutItem()
			itemInfo.itemIndex = itemIndex
			itemInfo.frame = CGRect(x: 0, y: 0, width: columnWidth, height: rowHeight)
			if isVariableRowHeight {
				itemInfo.hasEstimatedHeight = true
			}
			gridSection.add(itemInfo)
		}
		
		section = gridSection
	}
	
	private func initialLayoutAttributesForAttributes(attributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
		attributes.frame.offsetInPlace(dx: -contentOffsetDelta.x, dy: -contentOffsetDelta.y)
		return attributes
	}
	
	private func finalLayoutAttributesForAttributes(attributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
		let deltaX = contentOffsetDelta.x
		let deltaY = contentOffsetDelta.y
		var frame = attributes.frame
		
		// TODO: Abstract away pinning logic
		if let attributes = attributes as? CollectionViewLayoutAttributes
			where attributes.isPinned {
				let newX = max(attributes.unpinnedOrigin.x, frame.minX + deltaX)
				frame.origin.x = newX
			
				let newY = max(attributes.unpinnedOrigin.y, frame.minY + deltaY)
				frame.origin.y = newY
		}
		else {
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
		
		frame.offsetInPlace(dx: contentOffsetDelta.x, dy: contentOffsetDelta.y)
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
