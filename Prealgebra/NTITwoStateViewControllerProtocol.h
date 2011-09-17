//
//  NTITwoStateViewControllerProtocol.h
//  NextThoughtApp
//
//  Created by Jason Madden on 2011/08/09.
//  Copyright (c) 2011 NextThought. All rights reserved.
//

/**
 * Defines what we need from a controller that we can switch between the
 * master view and a mini view.
 */
@protocol NTITwoStateViewControllerProtocol <NSObject>
/**
 * The main view to use when scaled up.
 */
@property (nonatomic,readonly) UIView* view;
/**
 * If this property is non-nil, then its value will be used in the context
 * area. Otherwise, the main view will be scaled down.
 */
@property (nonatomic,readonly) UIView* miniView;

/**
 * If true, the view will be presented modally (according to
 * its modal presentation properties) instead of zooming.
 */
@property (nonatomic,readonly) BOOL presentsModalInsteadOfZooming;

/**
 * The title of the mini section.
 */
@property (nonatomic,readonly) NSString* miniViewTitle;

/**
 * If non-nil, this object will support creation of new items in the
 * mini view.
 */
@property (nonatomic,readonly) SEL miniCreationAction;

/**
 * If NO, then this object will only have the mini view.
 */
@property (nonatomic,readonly) BOOL supportsZooming;


@optional
/**
 * If YES, then this object will be hidden from the view entirely,
 * not featuring a title bar. Default is NO, meaning it does show.
 */
@property (nonatomic,readonly) BOOL miniViewHidden;

@property (nonatomic,readonly) BOOL miniViewCollapsed;

/**
 * If YES, then this section will have no header.
 */
@property (nonatomic,readonly) BOOL hidesSectionHeader;

/**
 * If implemented, called before zooming.
 */
-(void)willBeZoomedByController: (id)c;

/**
 * If implemented, then a zoomed object will be given a BarButtonItem
 * that can be used to return to its minimized state. Otherwise, it
 * should be a UINavigationController, and we will take over the rightBarButtonItem
 * of the top 
 */
-(void)zoomController: (id)c
willZoomWithBarButtonItem: (UIBarButtonItem*)item;

/**
 * If implemented, called before window shading.
 */
-(void)willWeWindowShadedByController: (id)c;

///**
// * If implemented, then rows will be inlined in a table.
// */
//-(NSInteger)numberOfRows;
//-(UITableViewCell*)tableView: (id)tv cellForRowAtIndexPath: (NSIndexPath*)indexPath;
//
-(CGFloat)miniViewHeight;

/**
 * If implemented, this is the view controller that will be maximized. Otherwise,
 * this object should be a view controller.
 */
-(UIViewController*)maximizedViewController;


/**
 * If implemented, called for long presses in the mini view header.
 */
-(void)longPressInMiniViewHeader: (id)sender;

@end
