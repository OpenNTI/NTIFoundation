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
static NSMutableArray* globalSliceRegistry;

+(NSMutableArray *)globalSliceRegistry 
{ 
	return globalSliceRegistry; 
}

+(void)addSliceToGlobalRegistry: (id)slice
{
	if ( !globalSliceRegistry ) {
		globalSliceRegistry = [[NSMutableArray alloc] init];
	}
	[globalSliceRegistry addObject: slice];
}
@end
