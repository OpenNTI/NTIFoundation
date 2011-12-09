//
//  NSString-NTIJSON.m
//  NextThoughtApp
//
//  Created by Jason Madden on 2011/07/25.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NSString-NTIJSON.h"
#import "NTIFoundationOSCompat.h"
#import <objc/objc.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>



@implementation NSString(NTIJSON)

-(id)jsonObjectValue
{
	NSError* error;
	id result = [NSJSONSerialization JSONObjectWithData: [self dataUsingEncoding: NSUTF8StringEncoding]
									  options: NSJSONReadingMutableContainers 
											| NSJSONReadingMutableLeaves
											| NSJSONReadingAllowFragments
										error: &error];
	if(!result && error){
		NSLog(@"An error occurred when derserializing %@. %@", self, error);
		return nil;
	}
	
	return result;
}

@end


