//
//  NSData-NTIJSON.m
//  NTIFoundation
//
//  Created by Christopher Utz on 3/15/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NSData-NTIJSON.h"

@implementation NSData(NTIJSON)

-(id)jsonObjectValue
{
	NSError* error;
	id result = [NSJSONSerialization JSONObjectWithData: self
												options: NSJSONReadingMutableContainers 
				 | NSJSONReadingMutableLeaves
				 | NSJSONReadingAllowFragments
												  error: &error];
	if(!result && error){
		//NSLog(@"An error occurred when derserializing data of length %lu bytes. %@", (unsigned long)[self length], error);
		return nil;
	}
	
	return result;
}


@end
