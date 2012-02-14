//
//  NTIGlobalInspector.m
//  NTIFoundation
//
//  Created by Christopher Utz on 1/27/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIGlobalInspector.h"
#import "OmniUI/OUIAppController.h"
#import "NTIInspectableController.h"

@implementation NTIGlobalInspector
@synthesize shownFromFirstResponder;
static NSArray* globalSliceRegistry;

+(NSArray *)globalSliceRegistry 
{ 
	return [globalSliceRegistry copy]; 
}

+(void)addSliceToGlobalRegistry: (id)slice
{
	if ( !globalSliceRegistry ) {
		globalSliceRegistry = [[NSMutableArray alloc] init];
	}
	globalSliceRegistry = [globalSliceRegistry arrayByAddingObject: slice];
}
@end
