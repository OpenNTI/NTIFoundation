//
//  NTITextAttachmentCell.m
//  NTIFoundation
//
//  Created by Christopher Utz on 9/19/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTITextAttachmentCell.h"
#import "OmniUI/OUITextView.h"

@interface NTITextAttachmentCell()
@end

@implementation NTITextAttachmentCell

-(id)init
{
	self = [super init];
	if(self){
		self->editableFrames = [NSHashTable weakObjectsHashTable];
	}
	return self;
}


-(void)setNeedsRedrawn
{
	for(OUITextView* ef in self->editableFrames){
		[ef setNeedsDisplay];
	}
}

-(void)attachEditableFrame: (OUITextView*)frame
{
	[self->editableFrames addObject: frame];
}

-(void)removeEditableFrame: (OUITextView*)frame
{
	[self->editableFrames removeObject: frame];
}

//For testing
-(NSSet*)editableFrames
{
	return [self->editableFrames copy];
}

@end
