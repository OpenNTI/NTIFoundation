//
//  NTITextAttachmentCell.m
//  NTIFoundation
//
//  Created by Christopher Utz on 9/19/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTITextAttachmentCell.h"

@interface _ZeroingWeakWrapper : OFObject
-(id)initWithObject: (id)obj;
@property (nonatomic, weak) id wrapped;
@end

@implementation _ZeroingWeakWrapper
@synthesize wrapped;

-(id)initWithObject:(id)obj
{
	self = [super init];
	self.wrapped = obj;
	return self;
}

-(BOOL)isEqual: (id)object
{
	id other = object;
	if([other respondsToSelector: @selector(wrapped)]){
		other = [other wrapped];
	}
	
	return [self.wrapped isEqual: other];
}

-(NSUInteger)hash
{
	return [self.wrapped hash];
}

@end

@interface NTITextAttachmentCell()
-(void)clearZeroedWeakRefs;
@end

@implementation NTITextAttachmentCell

-(id)init
{
	self = [super init];
	if(self){
		self->editableFrames = [NSMutableSet set];
	}
	return self;
}

//Its not actually clear to me when we should call this
-(void)clearZeroedWeakRefs
{
	NSArray* removed = [self->editableFrames.allObjects filteredArrayUsingPredicate: [NSPredicate predicateWithBlock: ^BOOL(_ZeroingWeakWrapper* obj, NSDictionary *bindings){
		return obj.wrapped == nil;
	}]];
	if(removed.count > 0){
		[self->editableFrames removeObjectsFromArray: removed];
	}
	
}

-(void)setNeedsRedrawn
{
	[self clearZeroedWeakRefs];
	for(id view in self->editableFrames){
		if([view respondsToSelector: @selector(setNeedsDisplay)]){
			[view setNeedsDisplay];
		}
	}
}

-(void)attachEditableFrame: (OUIEditableFrame*)frame
{
	[self clearZeroedWeakRefs];
	id wrapped = [[_ZeroingWeakWrapper alloc] initWithObject: frame];
	if(wrapped){
		[self->editableFrames addObject: wrapped];
	}
}

-(void)removeEditableFrame: (OUIEditableFrame*)frame
{
	[self clearZeroedWeakRefs];
	[self->editableFrames removeObject: frame];
}

//For testing
-(NSSet*)editableFrames
{
	[self clearZeroedWeakRefs];
	return [self->editableFrames copy];
}

@end
