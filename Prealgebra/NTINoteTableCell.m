//
//  NTINoteTableCell.m
//  NextThoughtApp
//
//  Created by Christopher Utz on 8/29/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTIUtilities.h"
#import "NTINoteTableCell.h"

@implementation NTINoteTableCell
@synthesize sharingImage;
@synthesize avatarImage;
@synthesize textContainer;
@synthesize creatorLabel;
@synthesize lastModifiedLabel;

- (id)initWithStyle: (UITableViewCellStyle)style 
	reuseIdentifier: (NSString*)reuseIdentifier
{
	self = [super initWithStyle: style reuseIdentifier: reuseIdentifier];
	return self;
}

-(void)setSelected: (BOOL)selected animated: (BOOL)animated
{
    [super setSelected: selected animated: animated];
}

-(void)layoutSubviews
{
    [super layoutSubviews];
	
    float indentPoints = self.indentationLevel * self.indentationWidth;
	
    self.contentView.frame = CGRectMake(indentPoints,
										self.contentView.frame.origin.y,
										self.contentView.frame.size.width - indentPoints, 
										self.contentView.frame.size.height);
}

-(void)dealloc 
{
	self.textContainer = nil;
	self.creatorLabel = nil;
	self.lastModifiedLabel = nil;
	self.avatarImage = nil;
    [sharingImage release];
	[super dealloc];
}
@end

@implementation NTINoteActionTableCell
@synthesize toolBar;

-(id)initWithStyle: (UITableViewCellStyle)style reuseIdentifier: (NSString *)reuseIdentifier
{
    self = [super initWithStyle: style reuseIdentifier: reuseIdentifier];
    if (self) {
        self->toolBar = [[UIToolbar alloc] init];		
		toolBar.frame = self.frame;
		[self addSubview: toolBar];
    }
    return self;
}

-(UIBarButtonItem*)spacer
{
	return [[[UIBarButtonItem alloc] 
			 initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace
			 target: nil
			 action: NULL] autorelease];
}

-(void)setActionItems: (NSArray *)uibarbuttons
{
//	NSMutableArray* buttonsWithSpacers = [NSMutableArray arrayWithObject: [self spacer]];
//	
//	for( id item in uibarbuttons )
//	{
//		[buttonsWithSpacers addObject: item];
//		[buttonsWithSpacers addObject: [self spacer]];
//	}
	
	[self->toolBar setItems: uibarbuttons];
	
}


- (void)setSelected: (BOOL)selected animated: (BOOL)animated
{
    [super setSelected: selected animated: animated];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
	
    float indentPoints = self.indentationLevel * self.indentationWidth;
	
    self.contentView.frame = CGRectMake(indentPoints,
										self.contentView.frame.origin.y,
										self.contentView.frame.size.width - indentPoints, 
										self.contentView.frame.size.height);
}

- (void)dealloc {

    [self->toolBar release];
	[super dealloc];
}

@end
