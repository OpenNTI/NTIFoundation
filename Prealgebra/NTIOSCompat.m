//
//  NTIOSCompat.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/22.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTIOSCompat.h"

#if __IPHONE_5_0 < __IPHONE_OS_VERSION_MAX_ALLOWED

#endif

id getClass_NSJSONSerialization(void)
{
	static BOOL checked = NO;
	static id jsonClass = nil;
	if( !checked ) {
		jsonClass = objc_getClass( "NSJSONSerialization");
		checked = YES;
	}
	return jsonClass;
}

id getClass_UIReferenceLibraryViewController(void)
{
	static BOOL checked = NO;
	static id class = nil;
	if( !checked ) {
		class = objc_getClass( "UIReferenceLibraryViewController");
		checked = YES;
	}
	return class;
}

//A workaround for crashing when UIActivityIndicators are in NIBs.
//https://devforums.apple.com/thread/116525?start=0&tstart=0

@interface UIImage(Extended)
-(id)_placeholder_initWithCoder: (NSCoder*)decoder;
@end


@implementation UIImage (Extended)
// NOTE: This is a TEMPORARY hack to work around a bug in Xcode 4.2 Beta 5.
- (id)_placeholder_initWithCoder:(NSCoder *)decoder 
{
	NSLog(@"%s", __FUNCTION__);
	
	return nil;
}
@end


static __attribute__((constructor)) void initialize() 
{
	OMNI_POOL_START
	// NOTE: only add -[UIImage initWithCoder:] on iOS < 5.0.
	if( [[[UIDevice currentDevice] systemVersion] hasPrefix: @"4"] ) {
		Class class = [UIImage class];
		IMP func = class_getMethodImplementation(class, @selector(_placeholder_initWithCoder:));
		struct objc_method_description desc = protocol_getMethodDescription(@protocol(NSCoding), @selector(initWithCoder:), YES, YES);
		BOOL status = class_addMethod(class, @selector(initWithCoder:), func, desc.types);
		NSLog(status == YES ? @"Successfully registered -[UIImage initWithCoder:]."
			  : @"Failed to register -[UIImage initWithCoder:].");

	}
	OMNI_POOL_END;	
}
