//
//  NTITextAttachment.m
//  NTIFoundation
//
//  Created by Christopher Utz on 10/17/13.
//  Copyright (c) 2013 NextThought. All rights reserved.
//

#import "NTITextAttachment.h"
#import <OmniAppKit/OATextAttachmentCell.h>

@implementation NTITextAttachment
@synthesize attachmentRenderer;

+(instancetype)attachmentWithRenderer: (OATextAttachmentCell*)renderer
{
	NTITextAttachment* attachment = [[NTITextAttachment alloc] init];
	attachment.attachmentRenderer = renderer;
	OBASSERT((id)renderer.attachment == attachment); // sets the backpointer
	return attachment;
}

-(id)init
{
	self = [super initWithData: nil ofType: nil];
	if(self){
		
	}
	return self;
}

-(void)setAttachmentRenderer:(id<OATextAttachmentCell>)renderer
{
	if(self.attachmentRenderer == renderer){
		return;
	}
	
	self->attachmentRenderer = renderer;
	self.attachmentRenderer.attachment = (id)self;
}

-(CGRect)attachmentBoundsForTextContainer: (NSTextContainer *)textContainer proposedLineFragment: (CGRect)lineFrag glyphPosition: (CGPoint)position characterIndex: (NSUInteger)charIndex
{
	if([self.attachmentRenderer respondsToSelector: @selector(attachmentBoundsForTextContainer:proposedLineFragment:glyphPosition:characterIndex:)]){
		return [(id)self.attachmentRenderer attachmentBoundsForTextContainer: textContainer proposedLineFragment: lineFrag glyphPosition: position characterIndex: charIndex];
	}
	
	CGSize s = [self.attachmentRenderer cellSize];
	return CGRectMake(0, 0, s.width, s.height);
}

-(UIImage*)imageForBounds: (CGRect)imageBounds textContainer: (NSTextContainer *)textContainer characterIndex: (NSUInteger)charIndex
{
	if([self.attachmentRenderer respondsToSelector: @selector(imageForBounds:textContainer:characterIndex:)]){
		return [(id)self.attachmentRenderer imageForBounds: imageBounds textContainer: textContainer characterIndex: charIndex];
	}
	
	UIGraphicsBeginImageContextWithOptions(imageBounds.size, NO, 0.0);
	[self.attachmentRenderer drawWithFrame: CGRectMake(0, 0, imageBounds.size.width, imageBounds.size.height)
									inView: nil
							characterIndex: charIndex
							 layoutManager: textContainer.layoutManager];
	UIImage* i = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return i;
}

@end
