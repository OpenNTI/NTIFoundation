//
//  LibraryView.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/06/10.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "LibraryView.h"
#import <QuartzCore/QuartzCore.h>

#import "NTINavigationParser.h"

#define TAG_IMAGE 2

@interface LibraryEntryView (Actions)
-(void)tap:(id)sender;
@end

@implementation LibraryView

-(void)awakeFromNib
{
	[self setBackgroundColor: [UIColor colorWithPatternImage: [UIImage imageNamed: @"Default-Portrait.png"]]];
	self.itemLabelColor = [UIColor darkTextColor];
}

-(id)viewForModel: (id)navigationItem withFrame: (CGRect)frame
{	
	UINib* viewNib = [UINib nibWithNibName: @"LibraryEntryView" bundle: nil];
	LibraryEntryView* bookView = [viewNib instantiateWithOwner: self options: nil].firstObject;
	bookView.navData = navigationItem;
	bookView.frame = frame;
	
	return bookView;
}

-(NSString*)labelForModel: (id)model
{
	return [model name];	
}



@end

@implementation LibraryEntryView
@synthesize navData;

-(void)setNavData: (id)nav
{
	if( self->navData ) {
		[self->navData removeObserver: self forKeyPath: @"properties.userData"];	
	}
	id nav2 = [nav retain];
	[self->navData release];
	self->navData = nav2;
	[self->navData addObserver: self
					forKeyPath: @"properties.userData"
					   options: NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
					   context: nav];
}

-(void)observeValueForKeyPath: (NSString*)keyPath
					 ofObject: (id)object
					   change: (NSDictionary*)change 
					  context: (void*)context
{
	
	if( [@"properties.userData" isEqual: keyPath] ) {
		UIImage* img = [change objectForKey: NSKeyValueChangeNewKey];
		if( ![img isNull] ) {
			dispatch_async( dispatch_get_main_queue(), ^{
				[(UIImageView*)[self viewWithTag: TAG_IMAGE]
				 setImage: img];
				[self setNeedsDisplay];
			});
		}
	}
}


-(void)drawRect: (CGRect)rect
{
	[super drawRect: rect];
	UIRectFrame( self.bounds );
}

-(void)dealloc
{
	self.navData = nil;
	[super dealloc];
}

@end
