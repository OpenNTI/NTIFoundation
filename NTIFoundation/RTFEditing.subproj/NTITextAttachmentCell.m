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
	NSLog(@"Attaching editable frame %@ to cell %@", frame, self);
	[self->editableFrames addObject: frame];
}

-(BOOL)removeEditableFrame: (OUITextView*)frame
{
	NSLog(@"Detaching editable frame %@ to cell %@", frame, self);
	if([self->editableFrames containsObject: frame]){
		[self->editableFrames removeObject: frame];
		return YES;
	}
	
	//Simply calling self->editableFrames.count gets screwy depending on when the weak refs get removed from the set
	return [self->editableFrames allObjects].count == 0;
}

-(void)detachAllEditableFrames
{
	for(OUITextView* frame in [self->editableFrames copy]){
		[self removeEditableFrame: frame];
	}
}

//For testing
-(NSSet*)editableFrames
{
	return [self->editableFrames copy];
}

@end
