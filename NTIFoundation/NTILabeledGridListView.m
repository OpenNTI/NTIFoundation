//
//  NTIFriendsListsViewController.m
//  NextThoughtApp
//
//  Created by Jason Madden on 2011/08/09.
//  Copyright (c) 2011 NextThought. All rights reserved.
//

#import "NTILabeledGridListView.h"
#import "NTIUtilities.h"
#import "NSArray-NTIExtensions.h"
#import "NTIDraggingUtilities.h"
#import "NTIAppPreferences.h"
#import "TestAppDelegate.h"

#import "OmniUI/OUIOverlayView.h"

@implementation NTILabeledGridListView

@synthesize tapAction, tapTarget;
@synthesize  longTapAction, longTapTarget;
@synthesize keyPath, toObserve;

@synthesize itemSize, itemBorder, itemBottomBorder, itemPadding, maxAcross;
@synthesize itemLabelColor;

static void commonInit( NTILabeledGridListView* self )
{
	//In landscape, we have 704 horizontal pixels to work with. We have views
	//that are 112x112. If we plan to fit three across, that leaves 368
	//pixels for padding to be divided 4 ways: two borders, two inter
	//Use 30 px borders to leave 264/2 = 154 between
	self.itemSize = CGSizeMake( 112, 112 );
	self.itemBorder = 30;
	self.itemBottomBorder = 60; //The top border of 30 matches our toolbar height.
	self.itemPadding = 154;
	self.maxAcross = 3;
	self.itemLabelColor = [UIColor lightTextColor];
}

-(id)initWithFrame: (CGRect)frame
		 observing: (id)obj
		forKeyPath: (id)kp
{
	self = [super initWithFrame: frame];
	self.userInteractionEnabled = YES;
	self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self.autoresizesSubviews = YES;
	self.clipsToBounds = YES;
	self.toObserve = obj;
	self.keyPath = kp;
	
	self->gridItemViews = [[NSMutableArray alloc] init];
	
	commonInit( self );
	
	return self;
	//TODO: This should probably be tiled or something. 
}

-(id)initWithCoder: (NSCoder*)aDecoder
{
	self = [super initWithCoder: aDecoder];
	commonInit( self );
	return self;
}

-(void)setToObserve: (id)obs
{
	id nobs = [obs retain];
	if( self->observing ) {
		[self->toObserve removeObserver: self forKeyPath: self.keyPath];
	}
	NTI_RELEASE( self->toObserve );
	self->toObserve = nobs;
	self->observing = NO;
}

-(void)setKeyPath: (id)kp
{
	kp = [kp retain];
	NTI_RELEASE( self->keyPath );
	NTI_RELEASE( self->keyPathCount );

	self->keyPath = kp;
	self->keyPathCount = [[NSString alloc] initWithFormat: @"%@.@count", kp];
}

-(id)populateGrid
{
	if( !self->observing && self.toObserve ) {
		self->observing = YES;
		[self->toObserve addObserver: self
							   forKeyPath: self->keyPath
								  options: NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionOld
								  context: nil];	
	}	
	return self;
}

-(NTIGridItemView*)viewForModel: (id)model withFrame: (CGRect)frame
{
	OBRequestConcreteImplementation( self, _cmd );
	return nil;
}

-(NSString*)labelForModel: (id)model
{
	OBRequestConcreteImplementation( self, _cmd );
	return nil;
}

-(void)animateRemoveAtIndex: (NSUInteger)ix
{
	NSTimeInterval delay = 0.0;
	//Save the starting frames first
	NSUInteger count = self->gridItemViews.count;
	CGRect frames[count];
	CGRect labelFrames[count];
	for( NSUInteger i = 0; i < count; i++ ) {
		NTIGridItemView* view = [self->gridItemViews objectAtIndex: i];
		frames[i] = view.frame;
		labelFrames[i] = view->nr_labelView ? view->nr_labelView.frame : CGRectZero;
	}
	
	//Shring the removed one into oblivion
	NTIGridItemView* view = [self->gridItemViews objectAtIndex: ix];
	[UIView animateWithDuration: 0.7
					 animations: ^(void) {
						 //Shrink to a point
						 
						 CGRect frame = view.frame;
						 frame.size = CGSizeZero;
						 frame.origin = view.center;
						 view.frame = frame;
						 view->nr_labelView.frame = frame;
					 }
					 completion: nil];
	
	//Then shuffle things into position, closing the gap. Each one follows 
	//its neighbor when it notices the neighbor move (to a point, on a full
	//list that takes forever so the time to notice gets smaller and smaller
	delay = 0.3;
	CGFloat delayIncr = 0.3;
	for( NSUInteger i = ix + 1; i < count; i++ ) {
		NTIGridItemView* next = [self->gridItemViews objectAtIndex: i];
		//This could be better done. Imagine them bumping into each other and then 
		//moving.
		CGRect frame = frames[i - 1];
		CGRect labelFrame = labelFrames[i - 1];
		[UIView animateWithDuration: 0.6
							  delay: delay += delayIncr
							options: UIViewAnimationCurveEaseOut
						 animations: ^{
							 next.frame = frame;
							 next->nr_labelView.frame = labelFrame;
						 }
						 completion: nil];
		if( delayIncr > 0 ) {
			delayIncr -= (delayIncr / 3.0);
		}
	}
	
	NTIGridItemView* v = [self->gridItemViews objectAtIndex: ix];
	[v->nr_labelView removeFromSuperview];
	[v removeFromSuperview];
	[self->gridItemViews removeObjectAtIndex: ix];
}

-(void)observeValueForKeyPath: (NSString*)keyPath
					 ofObject: (id)object
					   change: (NSDictionary*)change 
					  context: (void*)context
{
	//TODO: We could keep our model in sync instead of copying
	NTI_RELEASE( self->observedValue );
	self->observedValue = [[self->toObserve valueForKeyPath: self->keyPath] retain];
	
	NSNumber* changeKindNumber = [change objectForKey: NSKeyValueChangeKindKey];
	if( changeKindNumber.integerValue == NSKeyValueChangeInsertion ) {
		//We have one to add. Right now, we know that additions only happen
		//at the end
		[self drawAtIndex: [[toObserve valueForKeyPath: self->keyPathCount] unsignedIntegerValue] - 1
				  animate: YES];
	}
	else if( changeKindNumber.integerValue == NSKeyValueChangeRemoval ) {
		//One to remove, could be anywhere
		id removed = [[change objectForKey: NSKeyValueChangeOldKey] firstObject];
		for( NTIGridItemView* v in self->gridItemViews ) {
			if( [removed isEqual: v->nr_model] ) {
				NSUInteger ix = [self->gridItemViews indexOfObject: v];
				[self animateRemoveAtIndex: ix];
				break;
			}
			
		}
	}
	else {
		//For anything else, we start from scratch.
		[self redrawAll];
	}
}

-(void)drawAtIndex: (NSUInteger)ix
		   animate: (BOOL)animate
{
	id model = [self->observedValue objectAtIndex: ix];
	
	CGRect frame;
	NSUInteger x = 0; 
	int y = 0;
#define NEXT_X(x) (self.itemBorder + (self.itemSize.width * (x)) + (self.itemPadding * (x)))	
	for( NSUInteger i = 0; i <= ix; i++ ) {
		frame.size.height = frame.size.width = self.itemSize.width;
		frame.origin.x = NEXT_X(x);
		frame.origin.y = self.itemBorder + (self.itemSize.width * y) + (self.itemBottomBorder * y);
		
		
		if( NEXT_X(x+1) + frame.size.width > self.frame.size.width ) {
			//wrap
			x = 0;
			y++;
		}
		else {
			x++;
		}
	}
#undef NEXT_X
	
	NTIGridItemView* view = [self viewForModel: model withFrame: frame];
	view->nr_model = model;
	//Add a nice shadow
	view.layer.shadowOpacity = 0.3;
	view.layer.shadowOffset = CGSizeMake( 3, 4 );

	[self addSubview: view];
	[self->gridItemViews addObject: view];
	view.autoresizesSubviews = YES;
	
	if( self.longTapAction && self.longTapTarget ) {
		UILongPressGestureRecognizer* longPress = [[[UILongPressGestureRecognizer alloc]
													//Sadly gesture recognizers don't
													//use the responder chain.
													initWithTarget: self.longTapTarget
													action: self.longTapAction]
												   autorelease];
		
		[view addGestureRecognizer: longPress];
	}
	if( self.tapAction && self.tapTarget ) {
		id longPress = [[[UITapGestureRecognizer alloc]
						 initWithTarget: self.tapTarget
						 action: self.tapAction]
						autorelease];
		
		[view addGestureRecognizer: longPress];
	}
	
	NSString* labelText = [self labelForModel: model];
	if( ![NSString isEmptyString: labelText] ) {
		CGRect labelFrame;
		labelFrame.origin.x = frame.origin.x - 15;
		labelFrame.origin.y = frame.origin.y + frame.size.height + 5;
		labelFrame.size.width = frame.size.width + 30;
		labelFrame.size.height = self.itemBottomBorder - 10;
		UILabel* label = [[[UILabel alloc] initWithFrame: labelFrame] autorelease];
		label.text = labelText;
		label.numberOfLines = 3;
		label.font = [UIFont boldSystemFontOfSize: 14];
		label.minimumFontSize = 6;	
		label.adjustsFontSizeToFitWidth = YES;
		label.textAlignment = UITextAlignmentCenter;
		label.backgroundColor = [UIColor clearColor];
		label.textColor = self.itemLabelColor;
		view->nr_labelView = label;
		[self addSubview: label];	
	}
	
	if( animate ) {
		view.alpha = 0;
		[UIView animateWithDuration: 0.6
						 animations: ^(void) {
							 view.alpha = 1;
						 }];
	}
}

-(void)redrawAll
{
	//TODO: It would be nice to do this with animation when we're 
	//called because of rotation.
	for( UIView* subview in self.subviews ) {
		[subview removeFromSuperview];	
	}
	
	NSUInteger count = [[self->toObserve valueForKeyPath: self->keyPathCount] unsignedIntegerValue];
	for( NSUInteger i = 0; i < count; i++ ) {
		[self drawAtIndex: i animate: NO];
	}
	
}

-(void)dealloc
{
	self.toObserve = nil;
	self.keyPath = nil;
	self.longTapAction = nil;
	self.tapAction = nil;
	self.longTapTarget = nil;
	self.tapTarget = nil;
	self.itemLabelColor = nil;
	NTI_RELEASE( self->gridItemViews );
	NTI_RELEASE( self->keyPathCount );
	NTI_RELEASE( self->observedValue );
	[super dealloc];
}

@end


@implementation NTIGridItemView
@end
