//
//  NTIEditableFrame.m
//  NextThoughtApp
//
//  Created by Jason Madden on 2011/08/22.
//  Copyright (c) 2011 NextThought. All rights reserved.
//

#import "NTIEditableFrame.h"


@implementation NTIEditableFrame


@end


static UITextWritingDirection (*_original_baseWritingDirectionForPosition_inDirection)(id self, SEL _cmd, UITextPosition* position, UITextStorageDirection dir) = NULL;
static void (*_original_setBaseWritingDirection_forRange)(id self, SEL _cmd, UITextWritingDirection dir, UITextRange* range);

static UITextWritingDirection _baseWritingDirectionForPosition_inDirection( 
	id self, SEL _cmd,  UITextPosition* position,  UITextStorageDirection direction ) 
{
	return UITextWritingDirectionLeftToRight;
}

static void _setBaseWritingDirection_forRange( 
	id self, SEL _cmd, UITextWritingDirection writingDirection, UITextRange* range )
{
	if( writingDirection != UITextWritingDirectionLeftToRight ) {
		_original_setBaseWritingDirection_forRange( self, _cmd, writingDirection, range );
	}
}   


static void NTIEditableFramePerformPosing(void) __attribute__((constructor));
static void NTIEditableFramePerformPosing(void)
{
	OMNI_POOL_START
	if( [[[UIDevice currentDevice] systemVersion] hasPrefix: @"4"] ) {
		//Not needed on ios4
		return;
	}
	
    Class viewClass = NSClassFromString(@"OUIEditableFrame");
	_original_baseWritingDirectionForPosition_inDirection
		 = (typeof(_original_baseWritingDirectionForPosition_inDirection))
		 	OBReplaceMethodImplementation( 
				viewClass,
				@selector(baseWritingDirectionForPosition:inDirection:),
				(IMP)_baseWritingDirectionForPosition_inDirection);
				
	_original_setBaseWritingDirection_forRange
		= (typeof(_original_setBaseWritingDirection_forRange))
			OBReplaceMethodImplementation(
				viewClass,
				@selector(setBaseWritingDirection:forRange:),
				(IMP)_setBaseWritingDirection_forRange);
	OMNI_POOL_END;
}
