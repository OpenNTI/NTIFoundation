//
//  NTICoverageFix.m
//  NTIFoundation
//
//  Created by Christopher Utz on 7/24/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTITestFixes.h"
#import <objc/runtime.h>

void MethodSwizzle(NSString* origClassName, SEL origSel, NSString* newClassName, SEL newSel);
void MethodSwizzle(NSString* origClassName, SEL origSel, NSString* newClassName, SEL newSel) {
	
	Class origClass = objc_getClass([origClassName cStringUsingEncoding: NSUTF8StringEncoding]);
	Class newClass = objc_getClass([newClassName cStringUsingEncoding: NSUTF8StringEncoding]);
	
	Method origMethod = nil;
	Method newMethod = nil;
	
	// First, look for the methods
	origMethod = class_getClassMethod(origClass, origSel);
	newMethod = class_getClassMethod(newClass, newSel);
	
	// If both are found, swizzle them
	if ((origMethod != nil) && (newMethod != nil))
	{
		IMP temp;
		temp = method_getImplementation(origMethod);
		method_setImplementation(origMethod, method_getImplementation(newMethod));
		method_setImplementation(newMethod, temp);
	}
}


@implementation NTITestFixes

static __attribute__((constructor)) void initialize()
{
	//OUIDocumentPickerItemNameAndDataView's initialize method tries to create UIFont
	//objects.  We can't have that during logic tests so we swizzle out the implementation
	//to do nothing.  Expect problems trying to use this or related classes.
	MethodSwizzle(@"OUIDocumentPickerItemNameAndDateView", @selector(initialize),
				  @"NTITestFixes", @selector(swizzledInitialize));
}

+(void)swizzledInitialize
{
	NSLog(@"Swizzled method called");
}


FILE* fopen$UNIX2003(const char* filename, const char* mode) {
    return fopen(filename, mode);
}

size_t fwrite$UNIX2003(const void* ptr, size_t size, size_t nitems, FILE* stream) {
    return fwrite(ptr, size, nitems, stream);
}

@end

