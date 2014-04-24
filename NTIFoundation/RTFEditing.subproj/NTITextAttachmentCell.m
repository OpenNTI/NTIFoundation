//
//  NTITextAttachmentCell.m
//  NTIFoundation
//
//  Created by Christopher Utz on 9/19/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTITextAttachmentCell.h"
#import "OmniUI/OUITextView.h"
#import <OmniAppKit/NSAttributedString-OAExtensions.h>

@interface NSAttributedString(NTIUtilities)
- (void)eachAttachmentWithLocation:(void (^)(OATextAttachment *, NSRange location, BOOL *stop))applier;
@end

@implementation NSAttributedString(NTIUtilities)

- (void)eachAttachmentWithLocation:(void (^)(OATextAttachment *, NSRange location, BOOL *stop))applier;
{
    NSString *string = [self string];
    NSString *attachmentString = [NSAttributedString attachmentString];
    
    NSUInteger location = 0, end = [self length];
    BOOL stop = NO;
    while (location < end && !stop) {
        NSRange attachmentRange = [string rangeOfString:attachmentString options:0 range:NSMakeRange(location,end-location)];
        if (attachmentRange.length == 0)
            break;
        
		NSRange effectiveRange;
        OATextAttachment *attachment = [self attribute:NSAttachmentAttributeName atIndex:attachmentRange.location effectiveRange: &effectiveRange];
        OBASSERT(attachment);
        applier(attachment, effectiveRange, &stop);
        
        location = NSMaxRange(attachmentRange);
    }
}


@end



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
		OATextAttachment* attachment = [self attachment];
		if(attachment){
			NSTextStorage* ts = ef.textStorage;
			[ts eachAttachmentWithLocation:^(OATextAttachment* attachmentToTest, NSRange location, BOOL *stop) {
				if(attachmentToTest == attachment){
					[ef.layoutManager invalidateDisplayForCharacterRange: location];
					*stop = YES;
				}
			}];
		}
		
		
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
