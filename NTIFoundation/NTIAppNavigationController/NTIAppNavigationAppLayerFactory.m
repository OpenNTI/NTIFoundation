//
//  NTIAppNavigationAppLayerFactory.m
//  NTIFoundation
//
//  Created by Christopher Utz on 1/25/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIAppNavigationAppLayerFactory.h"

@implementation NTIAppNavigationAppLayerFactory
@synthesize title;
-(id)initWithTitle: (NSString*)_title andFactory: (NTIApplicationLayerFactory)_factory
{
	self = [super init];
	self.title = _title;
	self->factoryBlock = _factory;
	return self;
}

-(UIViewController<NTIAppNavigationApplicationLayer>*)createApplicationLayer
{
	if( self->factoryBlock ){
		return self->factoryBlock();
	}
	return nil;
}

@end
