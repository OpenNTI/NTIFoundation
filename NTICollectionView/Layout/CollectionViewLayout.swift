//
//  CollectionViewLayout.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/11/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

/// A subclass of UICollectionViewLayoutInvalidationContext that adds invalidation for metrics.
open class CollectionViewLayoutInvalidationContext: UICollectionViewLayoutInvalidationContext {
	
	/// Any index paths that have been explicitly invalidated need to be remeasured.
	open var invalidateMetrics = false
	
}

open class CollectionViewSeparatorView: UICollectionReusableView {
	
	open override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
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

open class CollectionViewLayout: UICollectionViewLayout, CollectionViewLayoutMeasuring, CollectionDataSourceDelegate, ShadowRegistrarVending {
	
	open var isEditing = false {
		didSet {
			guard isEditing != oldValue else {
				return
			}
			layoutDataIsValid = false
			invalidateLayout()
		}
	}
	
	var layoutSize = CGSize.zero
	
	/// - note: `nil` until `resetLayoutInfo()` has been called for the first time.
	fileprivate var layoutInfo: LayoutInfo!
	fileprivate var oldLayoutInfo: LayoutInfo?
	
	fileprivate var updateSectionDirections: [Int: SectionOperationDirection] = [:]
	
	fileprivate var updateRecorder = CollectionUpdateRecorder()
	
	fileprivate var contentOffsetDelta = CGPoint.zero
	
	/// A duplicate registry of all the cell & supplementary view class/nibs used in this layout. These will be used to create views while measuring the layout instead of dequeueing reusable views, because that causes consternation in UICollectionView.
	open var shadowRegistrar = ShadowRegistrar()
	/// Flag used to lock out multiple calls to `buildLayout` which seems to happen when measuring cells and supplementary views.
	fileprivate var isBuildingLayout = false
	/// The attributes being currently measured. This allows short-circuiting the lookup in several API methods.
	fileprivate var measuringAttributes: CollectionViewLayoutAttributes?
	/// The collection view wrapper used while measuring views.
	fileprivate var collectionViewWrapper: CollectionViewWrapper?
	
	/// Whether the data source has the snapshot metrics method.
	fileprivate var dataSourceHasSnapshotMetrics = true
	/// Layout data becomes invalid if the data source changes.
	fileprivate var layoutDataIsValid = true
	
	public override init() {
		super.init()
		setUp()
	}

	public required init?(coder aDecoder: NSCoder) {
	    super.init(coder: aDecoder)
		setUp()
	}
	
	fileprivate func setUp() {
		registerDecorationViews()
	}
	
	open func registerDecorationViews() {
		// Subclasses should override to register custom decoration views
		// TODO: Encapsulate elsewhere
		register(CollectionViewSeparatorView.self, forDecorationViewOfKind: collectionElementKindRowSeparator)
		register(CollectionViewSeparatorView.self, forDecorationViewOfKind: collectionElementKindColumnSeparator)
		register(CollectionViewSeparatorView.self, forDecorationViewOfKind: collectionElementKindSectionSeparator)
		register(CollectionViewSeparatorView.self, forDecorationViewOfKind: collectionElementKindGlobalHeaderBackground)
		register(CollectionViewSeparatorView.self, forDecorationViewOfKind: collectionElementKindContentBackground)
	}
	
	// MARK: - Editing helpers
	
	open func canEditItem(at indexPath: IndexPath) -> Bool {
		guard let collectionView = self.collectionView,
			let dataSource = collectionView.dataSource as? CollectionDataSource else {
				return false
		}
		return dataSource.collectionView(collectionView, canEditItemAt: indexPath)
	}
	
	open func canMoveItem(at indexPath: IndexPath) -> Bool {
		guard let collectionView = self.collectionView,
			let dataSource = collectionView.dataSource as? CollectionDataSource else {
				return false
		}
		return dataSource.collectionView(collectionView, canMoveItemAt: indexPath)
	}
	
	// MARK: - CollectionViewLayoutMeasuring
	
	open func measuredSizeForSupplementaryItem(_ supplementaryItem: LayoutSupplementaryItem) -> CGSize {
		guard let collectionView = collectionViewWrapper as? WrapperCollectionView,
			let dataSource = collectionView.dataSource else {
				return CGSize.zero
		}
		
		measuringAttributes = supplementaryItem.layoutAttributes.copy() as? CollectionViewLayoutAttributes
		measuringAttributes!.isHidden = true
		
		let view = dataSource.collectionView!(collectionView, viewForSupplementaryElementOfKind: supplementaryItem.elementKind, at: supplementaryItem.indexPath as IndexPath)
		let attributes = view.preferredLayoutAttributesFitting(measuringAttributes!)
		view.removeFromSuperview()
		
		// Allow regeneration of the layout attributes later
//		supplementaryItem.resetLayoutAttributes()
		measuringAttributes = nil
		
		return attributes.frame.size
	}
	
	open func measuredSizeForItem(_ item: LayoutItem) -> CGSize {
		guard let collectionView = collectionViewWrapper as? WrapperCollectionView,
			let dataSource = collectionView.dataSource else {
				return CGSize.zero
		}
		
		measuringAttributes = item.layoutAttributes.copy() as? CollectionViewLayoutAttributes
		measuringAttributes!.isHidden = true
		
		let view = dataSource.collectionView(collectionView, cellForItemAt: item.indexPath as IndexPath)
		let attributes = view.preferredLayoutAttributesFitting(measuringAttributes!)
		view.removeFromSuperview()
		
		// Allow regeneration of the layout attributes later
//		item.resetLayoutAttributes()
		measuringAttributes = nil
		
		return attributes.frame.size
	}
	
	open func measuredSizeForPlaceholder(_ placeholderInfo: LayoutPlaceholder) -> CGSize {
		guard let collectionView = collectionViewWrapper as? WrapperCollectionView,
			let dataSource = collectionView.dataSource else {
				return CGSize.zero
		}
		
		measuringAttributes = placeholderInfo.layoutAttributes.copy() as? CollectionViewLayoutAttributes
		measuringAttributes!.isHidden = true
		
		let view = dataSource.collectionView!(collectionView, viewForSupplementaryElementOfKind: measuringAttributes!.representedElementKind!, at: placeholderInfo.indexPath as IndexPath)
		let attributes = view.preferredLayoutAttributesFitting(measuringAttributes!)
		view.removeFromSuperview()
		
		// Allow regeneration of the layout attributes later
//		placeholderInfo.resetLayoutAttributes()
		measuringAttributes = nil
		
		return attributes.frame.size
	}
	
	// MARK: - Drag & Drop
	
	fileprivate let scrollDirection: UICollectionViewScrollDirection = .vertical
	
	fileprivate var scrollingSpeed: CGFloat = 0
	
	fileprivate var scrollingTriggerEdgeInsets: UIEdgeInsets = .zero
	
	fileprivate var selectedItemIndexPath: IndexPath?
	
	fileprivate var sourceItemIndexPath: IndexPath?
	
	fileprivate var currentView: UIView!
	
	fileprivate var currentViewCenter: CGPoint = .zero
	
	fileprivate var panTranslationInCollectionView: CGPoint = .zero
	
	fileprivate var displayLink: CADisplayLink?
	
	fileprivate var autoscrollDirection: AutoScrollDirection?
	
	fileprivate var autoscrollBounds: CGRect = .zero
	
	fileprivate var dragBounds: CGRect = .zero
	
	fileprivate var dragCellSize: CGSize = .zero
	
	
	open func beginDraggingItem(at indexPath: IndexPath) {
		guard let
			collectionView = self.collectionView,
			let cell = collectionView.cellForItem(at: indexPath) else {
				return
		}
		
		var dragFrame = cell.frame
		dragCellSize = dragFrame.size
		
		let snapshotView = cell.snapshotView(afterScreenUpdates: true)
		
		let shadowView = UIImageView(frame: dragFrame.insetBy(dx: 0, dy: -dragShadowHeight))
		if let image = UIImage(named: "DragShadow") {
			shadowView.image = image.resizableImage(withCapInsets: UIEdgeInsets(top: dragShadowHeight, left: 1, bottom: dragShadowHeight, right: 1))
		}
		shadowView.isOpaque = false
		
		dragFrame.origin = CGPoint(x: 0, y: dragShadowHeight)
		snapshotView!.frame = dragFrame
		shadowView.addSubview(snapshotView!)
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
		context.invalidateItems(at: [indexPath])
		invalidateLayout(with: context)
		
		autoscrollBounds = CGRect.zero
		autoscrollBounds.size = collectionView.bounds.size
		autoscrollBounds = UIEdgeInsetsInsetRect(autoscrollBounds, scrollingTriggerEdgeInsets)
		
		let collectionViewFrame = collectionView.frame
		let collectionViewWidth = collectionViewFrame.width
		let collectionViewHeight = collectionViewFrame.height
		
		dragBounds = CGRect(x: dragCellSize.width/2, y: dragCellSize.height/2, width: collectionViewWidth - dragCellSize.width, height: collectionViewHeight - dragCellSize.height)
	}
	
	open func cancelDragging() {
		guard let
			currentView = self.currentView,
			let sourceItemIndexPath = self.sourceItemIndexPath,
			let selectedItemIndexPath = self.selectedItemIndexPath else {
				return
		}
		
		let sourceSectionIndex = sourceItemIndexPath.section
		let destinationSectionIndex = selectedItemIndexPath.section
		
		guard var
			sourceSection = sectionInfoForSectionAtIndex(sourceSectionIndex),
			var destinationSection = sectionInfoForSectionAtIndex(destinationSectionIndex) else {
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
		invalidateLayout(with: context)
	}
	
	open func endDragging() {
		guard let
			currentView = self.currentView,
			let fromIndexPath = self.sourceItemIndexPath,
			var toIndexPath = self.selectedItemIndexPath else {
				return
		}
		
		currentView.removeFromSuperview()
		
		let sourceSectionIndex = fromIndexPath.section
		let destinationSectionIndex = toIndexPath.section
		
		guard var
			sourceSection = sectionInfoForSectionAtIndex(sourceSectionIndex),
			var destinationSection = sectionInfoForSectionAtIndex(destinationSectionIndex) else {
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
				toIndexPath = IndexPath(item: toIndex, section: destinationSectionIndex)
			}
		}
		
		if needsUpdate {
			// TODO: Modify source and destination section items
			
			// Tell the data source, but don't animate because we've already updated everything in place
			UIView.performWithoutAnimation {
				guard let
					collectionView = self.collectionView,
					let dataSource = collectionView.dataSource as? CollectionDataSource else {
						return
				}
				
				dataSource.collectionView(collectionView, moveItemAt: fromIndexPath, to: toIndexPath)
			}
		}
		
		let context = CollectionViewLayoutInvalidationContext()
		// Layout source and destination sections
		layoutInfo.setSection(sourceSection, at: sourceSectionIndex)
		layoutInfo.setSection(destinationSection, at: destinationSectionIndex)
		invalidateLayout(with: context)
		
		selectedItemIndexPath = nil
	}
	
	fileprivate func invalidateScrollTimer() {
		guard let displayLink = self.displayLink else {
			return
		}
		
		if !displayLink.isPaused {
			displayLink.invalidate()
		}
		
		self.displayLink = nil
	}
	
	fileprivate func setupScrollTimer(in direction: AutoScrollDirection) {
		if let displayLink = self.displayLink, !displayLink.isPaused {
			if autoscrollDirection == direction {
				return
			}
		}
		
		invalidateScrollTimer()
		
		displayLink = CADisplayLink(target: self, selector: #selector(CollectionViewLayout.handleScroll(_:)))
		autoscrollDirection = direction
		
		displayLink?.add(to: .main, forMode: RunLoopMode.commonModes)
	}
	
	// Tight loop, allocate memory sparely, even if they are stack allocation
	open func handleScroll(_ displayLink: CADisplayLink) {
		guard let
			direction = autoscrollDirection,
			let collectionView = self.collectionView else {
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
	
	fileprivate func pointConstrainedToDragBounds(_ viewCenter: CGPoint) -> CGPoint {
		var viewCenter = viewCenter
		
		if scrollDirection == .vertical {
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
	
	
	open func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
		guard let collectionView = self.collectionView else {
			return
		}
		
		let contentOffset = collectionView.contentOffset
		
		switch gestureRecognizer.state {
		case .began:
			panTranslationInCollectionView = gestureRecognizer.translation(in: collectionView)
			let viewCenter = currentViewCenter + panTranslationInCollectionView
			
			currentView.center = pointConstrainedToDragBounds(viewCenter)
			
			makeSpaceForDraggedCell()
			
			let location = gestureRecognizer.location(in: collectionView)
			
			switch scrollDirection {
			case .vertical:
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
				
			case .horizontal:
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
			
		case .cancelled, .ended:
			invalidateScrollTimer()
			
		default:
			break
		}
	}
	
	fileprivate func makeSpaceForDraggedCell() {
		guard let
			collectionView = self.collectionView,
			let dataSource = collectionView.dataSource as? CollectionDataSource,
			let sourceItemIndexPath = self.sourceItemIndexPath,
			let previousIndexPath = selectedItemIndexPath,
			var newIndexPath = collectionView.indexPathForItem(at: currentView.center) else {
				return
		}
		
		let oldSectionIndex = previousIndexPath.section
		let newSectionIndex = newIndexPath.section
		
		guard var
			oldSection = sectionInfoForSectionAtIndex(oldSectionIndex),
			var newSection = sectionInfoForSectionAtIndex(newSectionIndex) else {
				return
		}
		
		 // If we've already made space for the cell, all indexes in that section need to be incremented by 1
		if oldSection.phantomCellIndex == previousIndexPath.item
			&& newSectionIndex == oldSectionIndex
			&& newIndexPath.item >= oldSection.phantomCellIndex ?? NSNotFound {
			newIndexPath = IndexPath(item: newIndexPath.item+1, section: newSectionIndex)
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
		
		invalidateLayout(with: context)
	}
	
	// MARK: - UICollectionViewLayout
	
	open override class var layoutAttributesClass : AnyClass {
		return CollectionViewLayoutAttributes.self
	}
	
	open override class var invalidationContextClass : AnyClass {
		return CollectionViewLayoutInvalidationContext.self
	}
	
	// This is necessarily called before `resetLayoutInfo` (from `loadView`)
	open override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
		defer {
			super.invalidateLayout(with: context)
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
				let resultStr = result.joined(separator: ", ")
				debugPrint("\(#function) \(kind) invalidated supplementary indexPaths: \(resultStr)")
			}
		}
	}
	
	open func invalidateMetricsForItem(at indexPath: IndexPath, in context: CollectionViewLayoutInvalidationContext) {
		guard let cell = collectionView?.cellForItem(at: indexPath) else {
			return
		}
		
		let attributes = layoutInfo.layoutAttributesForCell(at: indexPath)?.copy() as! CollectionViewLayoutAttributes
		attributes.shouldCalculateFittingSize = true
		
		let newAttributes = cell.preferredLayoutAttributesFitting(attributes)
		let newSize = newAttributes.frame.size
		
		guard newSize != attributes.frame.size else {
			return
		}
		
		layoutInfo.setSize(newSize, forItemAt: indexPath, invalidationContext: context)
	}
	
	fileprivate func invalidateMetricsForElement(ofKind kind: String, at indexPath: IndexPath, in context: CollectionViewLayoutInvalidationContext) {
		guard let view = collectionView?._supplementaryViewOfKind(kind, at: indexPath) else {
			return
		}
		
		let attributes = layoutInfo.layoutAttributesForSupplementaryElementOfKind(kind, at: indexPath)?.copy() as! CollectionViewLayoutAttributes
		attributes.shouldCalculateFittingSize = true
		
		let newAttributes = view.preferredLayoutAttributesFitting(attributes)
		let newSize = newAttributes.frame.size
		
		guard newSize != attributes.frame.size else {
			return
		}
		
		layoutInfo.setSize(newSize, forElementOfKind: kind, at: indexPath, invalidationContext: context)
	}
	
	open override func prepare() {
		layoutLog("\(#function) bounds=\(collectionView!.bounds)")
		if let bounds = collectionView?.bounds, !bounds.isEmpty {
			buildLayout()
		}
		super.prepare()
	}
	
	open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
		layoutLog("\(#function) rect=\(rect)")
		guard layoutInfo != nil, let collectionView = self.collectionView else {
			return nil
		}
		
		let contentOffset = targetContentOffset(forProposedContentOffset: collectionView.contentOffset)
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
	
	open override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
		let sectionIndex = indexPath.section
		
		guard sectionIndex >= 0 && sectionIndex < layoutInfo.numberOfSections else {
			return nil
		}
		
		let attributes: CollectionViewLayoutAttributes
		
		if let measuringAttributes = self.measuringAttributes, measuringAttributes.indexPath == indexPath {
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
	
	open override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
		let attributes: CollectionViewLayoutAttributes
		
		if let measuringAttributes = self.measuringAttributes, measuringAttributes.indexPath == indexPath
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
	
	open override func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
		return layoutInfo.layoutAttributesForDecorationViewOfKind(elementKind, at: indexPath)
	}
	
	fileprivate func finalizeConfiguration(of attributes: CollectionViewLayoutAttributes) {
		let indexPath = attributes.indexPath
		
		switch attributes.representedElementCategory {
		case .cell:
			attributes.isEditing = isEditing ? canEditItem(at: indexPath) : false
			attributes.isMovable = isEditing ? canMoveItem(at: indexPath) : false
		default:
			attributes.isEditing = isEditing
		}
	}
	
	open override func shouldInvalidateLayout(forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> Bool {
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
	
	open override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
		return true
	}
	
	open override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
		let context = super.invalidationContext(forBoundsChange: newBounds)
		
		guard layoutInfo != nil, let collectionView = self.collectionView else {
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
	
	open override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
		return proposedContentOffset
	}
	
	open override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
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
			let sectionInfo = sectionInfoForSectionAtIndex(firstInsertedIndex),
			let globalSection = sectionInfoForSectionAtIndex(globalSectionIndex), operationDirectionForSectionAtIndex(firstInsertedIndex) != nil {
			
			let minY = sectionInfo.frame.minY
			targetContentOffset = globalSection.targetContentOffsetForProposedContentOffset(targetContentOffset, firstInsertedSectionMinY: minY)
		}
		
		targetContentOffset.y -= insets.top
		
		layoutLog("\(#function) proposedContentOffset=\(proposedContentOffset) layoutSize=\(layoutSize) availableHeight=\(availableHeight) targetContentOffset=\(targetContentOffset)")
		return targetContentOffset
	}
	
	open override var collectionViewContentSize : CGSize {
		layoutLog("\(#function) \(layoutSize)")
		return layoutSize
	}
	
	open override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
		resetUpdates()
		updateRecorder.record(updateItems, sectionProvider: layoutInfo, oldSectionProvider: oldLayoutInfo)
		processGlobalSectionUpdate()
		adjustContentOffsetDelta()
		
		super.prepare(forCollectionViewUpdates: updateItems)
	}
	
	fileprivate func resetUpdates() {
		updateRecorder.reset()
	}
	
	/// Finds any global elements that disappeared during the update and records them for deletion.
	///
	/// This becomes necessary when the selected data source of a segmented data source contributes a kind of global element, and then a new data source is selected which does not contribute that kind of global element.
	fileprivate func processGlobalSectionUpdate() {
		guard let globalSection = layoutInfo.sectionAtIndex(globalSectionIndex),
			let oldLayoutInfo = self.oldLayoutInfo,
			let oldGlobalSection = oldLayoutInfo.sectionAtIndex(globalSectionIndex) else {
				return
		}
		
		processGlobalSectionDecorationUpdate(from: oldGlobalSection, to: globalSection)
		processGlobalSectionSupplementaryUpdate(from: oldGlobalSection, to: globalSection)
	}
	
	fileprivate func processGlobalSectionDecorationUpdate(from oldGlobalSection: LayoutSection, to globalSection: LayoutSection) {
		let decorationAttributes = globalSection.decorationAttributesByKind
		let oldDecorationAttributes = oldGlobalSection.decorationAttributesByKind
		let decorationDiff = decorationAttributes.countDiff(with: oldDecorationAttributes)
		for (kind, countDiff) in decorationDiff {
			let count = (decorationAttributes[kind] ?? []).count
			let oldCount = (oldDecorationAttributes[kind] ?? []).count
			if countDiff < 0 {
				let indexPaths = (count..<oldCount).map { IndexPath(index: $0) }
				updateRecorder.recordAdditionalDeletedIndexPaths(indexPaths, forElementOf: kind)
			}
			else if countDiff > 0 {
				let indexPaths = (oldCount..<count).map { IndexPath(index: $0) }
				updateRecorder.recordAdditionalInsertedIndexPaths(indexPaths, forElementOf: kind)
			}
		}
	}
	
	fileprivate func processGlobalSectionSupplementaryUpdate(from oldGlobalSection: LayoutSection, to globalSection: LayoutSection) {
		let supplementaryItems = globalSection.supplementaryItemsByKind
		let oldSupplementaryItems = oldGlobalSection.supplementaryItemsByKind
		let supplementaryDiff = supplementaryItems.countDiff(with: oldSupplementaryItems)
		for (kind, countDiff) in supplementaryDiff {
			let count = (supplementaryItems[kind] ?? []).count
			let oldCount = (oldSupplementaryItems[kind] ?? []).count
			if countDiff < 0 {
				let indexPaths = (count..<oldCount).map { IndexPath(index: $0) }
				updateRecorder.recordAdditionalDeletedIndexPaths(indexPaths, forElementOf: kind)
			}
			else if countDiff > 0 {
				let indexPaths = (oldCount..<count).map { IndexPath(index: $0) }
				updateRecorder.recordAdditionalInsertedIndexPaths(indexPaths, forElementOf: kind)
			}
		}
	}
	
	fileprivate func adjustContentOffsetDelta() {
		guard let collectionView = self.collectionView else {
			return
		}
		let contentOffset = collectionView.contentOffset
		let newContentOffset = targetContentOffset(forProposedContentOffset: contentOffset)
		contentOffsetDelta = CGPoint(x: newContentOffset.x - contentOffset.x, y: newContentOffset.y - contentOffset.y)
	}
	
	open override func finalizeCollectionViewUpdates() {
		super.finalizeCollectionViewUpdates()
		resetUpdates()
		updateSectionDirections.removeAll(keepingCapacity: true)
	}
	
	open override func indexPathsToDeleteForDecorationView(ofKind elementKind: String) -> [IndexPath] {
		var superValue = super.indexPathsToDeleteForDecorationView(ofKind: elementKind)
		if let additionalValues = additionalDeletedIndexPathsByKind[elementKind] {
			superValue += additionalValues
		}
		layoutLog("\(#function) kind=\(elementKind) value=\(superValue)")
		return superValue
	}
	
	open override func initialLayoutAttributesForAppearingDecorationElement(ofKind elementKind: String, at decorationIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
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
	
	open override func finalLayoutAttributesForDisappearingDecorationElement(ofKind elementKind: String, at decorationIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
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
	
	open override func initialLayoutAttributesForAppearingSupplementaryElement(ofKind elementKind: String, at elementIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
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
	
	open override func finalLayoutAttributesForDisappearingSupplementaryElement(ofKind elementKind: String, at elementIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
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
	
	open override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
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
	
	open override func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
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
	
	func operationDirectionForSectionAtIndex(_ sectionIndex: Int) -> SectionOperationDirection? {
		guard !UIAccessibilityIsReduceMotionEnabled() else {
			return nil
		}
		
		return updateSectionDirections[sectionIndex]
	}
	
	func sectionInfoForSectionAtIndex(_ sectionIndex: Int) -> LayoutSection? {
		return layoutInfo.sectionAtIndex(sectionIndex)
	}
	
	func snapshotMetrics() -> [Int: DataSourceSectionMetricsProviding]? {
		guard dataSourceHasSnapshotMetrics else {
			return nil
		}
		return (collectionView!.dataSource as! CollectionDataSourceMetrics).snapshotMetrics()
	}
	
	fileprivate func registerDecorations(from layoutMetrics: [Int: DataSourceSectionMetricsProviding]) {
		for sectionMetrics in layoutMetrics.values {
			registerDecorations(from: sectionMetrics.metrics)
		}
	}
	
	fileprivate func registerDecorations(from sectionMetrics: SectionMetrics) {
		for kind in sectionMetrics.decorationsByKind.keys {
			register(CollectionViewSeparatorView.self, forDecorationViewOfKind: kind)
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
		
		layoutSize = CGSize.zero
		
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
		
		var start = CGPoint.zero
		
		let layoutEngine = GridLayoutEngine(layoutInfo: layoutInfo)
		start = layoutEngine.layoutWithOrigin(start, layoutSizing: layoutInfo, invalidationContext: nil)
		
		var layoutHeight = start.y
		
		// The layoutHeight is the total height of the layout including any placeholders in their default size. Determine how much space is left to be shared out among the placeholders
		layoutInfo.heightAvailableForPlaceholders = max(0, height - layoutHeight)
		
		if let globalSection = sectionInfoForSectionAtIndex(globalSectionIndex) {
			layoutHeight = globalSection.targetLayoutHeightForProposedLayoutHeight(layoutHeight, layoutInfo: layoutInfo)
		}
		
		layoutSize = CGSize(width: width, height: layoutHeight)
		
		contentOffset = targetContentOffset(forProposedContentOffset: contentOffset)
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
		
		let numberOfSections = collectionView.numberOfSections
		
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
					placeholderInfo?.height = metrics.placeholderHeight
					placeholderInfo?.hasEstimatedHeight = metrics.placeholderHasEstimatedHeight
					placeholderInfo?.shouldFillAvailableHeight = metrics.placeholderShouldFillAvailableHeight
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
	open func populate(_ section: inout LayoutSection, from metrics: DataSourceSectionMetricsProviding) {
		guard let collectionView = self.collectionView,
			let gridMetrics = metrics.metrics as? GridSectionMetricsProviding,
			var gridSection = section as? GridLayoutSection else {
				return
		}
		
		let sectionIndex = gridSection.sectionIndex
		
		gridSection.reset()
		gridSection.applyValues(from: gridMetrics)
		gridSection.metrics.resolveMissingValuesFromTheme()
		
		func setupSupplementaryMetrics(_ supplementaryMetrics: SupplementaryItem) {
			// FIXME: Supplementary item kind shouldn't be decided here
			var supplementaryItem = GridLayoutSupplementaryItem(supplementaryItem: supplementaryMetrics)
			supplementaryItem.applyValues(from: gridSection.metrics)
			gridSection.add(supplementaryItem)
		}
		
		for supplementaryItem in metrics.supplementaryItemsByKind.contents {
			setupSupplementaryMetrics(supplementaryItem)
		}
		
		let isGlobalSection = sectionIndex == globalSectionIndex
		let numberOfItemsInSection = isGlobalSection ? 0 : collectionView.numberOfItems(inSection: sectionIndex)
		
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
	
	fileprivate func initialLayoutAttributesForAttributes(_ attributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
		attributes.frame.offsetInPlace(dx: -contentOffsetDelta.x, dy: -contentOffsetDelta.y)
		return attributes
	}
	
	fileprivate func finalLayoutAttributesForAttributes(_ attributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
		let deltaX = contentOffsetDelta.x
		let deltaY = contentOffsetDelta.y
		var frame = attributes.frame
		
		// TODO: Abstract away pinning logic
		if let attributes = attributes as? CollectionViewLayoutAttributes, attributes.isPinned {
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
	
	fileprivate func initialLayoutAttributesForAttributes(_ attributes: UICollectionViewLayoutAttributes, slidingInFrom direction: SectionOperationDirection) -> UICollectionViewLayoutAttributes {
		var frame = attributes.frame
		let cvBounds = collectionView?.bounds ?? CGRect.zero
		switch direction {
		case .Left:
			frame.origin.x -= cvBounds.size.width
		default:
			frame.origin.x += cvBounds.size.width
		}
		attributes.frame = frame
		return initialLayoutAttributesForAttributes(attributes)
	}
	
	fileprivate func finalLayoutAttributesForAttributes(_ attributes: UICollectionViewLayoutAttributes, slidingAwayFrom direction: SectionOperationDirection) -> UICollectionViewLayoutAttributes {
		var frame = attributes.frame
		let bounds = collectionView?.bounds ?? CGRect.zero
		
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
	
	open func dataSource(_ dataSource: CollectionDataSource, didInsertSections sections: IndexSet, direction: SectionOperationDirection?) {
		for sectionIndex in sections {
			updateSectionDirections[sectionIndex] = direction
		}
	}
	
	open func dataSource(_ dataSource: CollectionDataSource, didRemoveSections sections: IndexSet, direction: SectionOperationDirection?) {
		for sectionIndex in sections {
			updateSectionDirections[sectionIndex] = direction
		}
	}
	
	open func dataSource(_ dataSource: CollectionDataSource, didMoveSectionFrom oldSection: Int, to newSection: Int, direction: SectionOperationDirection?) {
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
