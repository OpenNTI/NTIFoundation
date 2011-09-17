//
//  NTIFriendsListsViewController.h
//  NextThoughtApp
//
//  Created by Jason Madden on 2011/08/09.
//  Copyright (c) 2011 NextThought. All rights reserved.
//


@class NTIGridItemView;
@interface NTILabeledGridListView : UIView {
@package
	BOOL observing;
	id keyPathCount;
	id observedValue;
	NSMutableArray* gridItemViews;
}

-(id)initWithFrame: (CGRect)frame
		 observing: (id)obj
		forKeyPath: (id)keyPath;

@property (nonatomic,retain) id keyPath, toObserve;
@property (nonatomic,assign) SEL longTapAction, tapAction;
@property (nonatomic,assign) id longTapTarget, tapTarget;
@property (nonatomic,assign) CGSize itemSize;
@property (nonatomic,assign) CGFloat itemBorder, itemBottomBorder, itemPadding;
@property (nonatomic,assign) NSUInteger maxAcross;
@property (nonatomic,retain) UIColor* itemLabelColor;


/**
 * Causes this object to begin observing the object given to the constructor
 * and create all the item views.
 */
-(id)populateGrid;
-(void)redrawAll;
-(void)drawAtIndex: (NSUInteger)ix
		   animate: (BOOL)animate;
		   
//Subclasses must implement
-(NTIGridItemView*)viewForModel: (id)model withFrame: (CGRect)frame;
-(NSString*)labelForModel: (id)model;

@end


@interface NTIGridItemView : UIView {
	@package
	id nr_model;
	UILabel* nr_labelView;
}
@end
