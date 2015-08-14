//
//  NSMutableArray-NTIExtensions.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/15.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NSMutableArray-NTIExtensions.h"

@implementation NSMutableArray(NTIExtensions)

-(id)removeAndReturnLastObject
{
	id last = [self lastObject];
	[self removeLastObject]; //retain bc this releases
	return last;
}

-(id)pop
{
	return [self removeAndReturnLastObject];	
}

-(NSMutableArray*)push: (id)anObject
{
	[self addObject: anObject];
	return self;
}

@end;
