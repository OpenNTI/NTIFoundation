//
//  NTIExtensions+NSData.m
//  NTIFoundation
//
//  Created by Christopher Utz on 4/14/14.
//  Copyright (c) 2014 NextThought. All rights reserved.
//

#import "NSData+NTIExtensions.h"

#import "NSData-NTIJSON.h"

@implementation NSData (NTIExtensions)

- (BOOL)isPrefixedByByte:(const uint8_t *)ptr;
{
	if ([self length] == 0) {
		return NO;
	}
	const uint8_t *selfPtr;
    selfPtr = [self bytes];
	
	//We only care about the first byte.
	if (*ptr != *selfPtr) {
		return NO;
	}
    return YES;
}

-(BOOL)isPlistData
{
	//NOTE: We expect to have either json data or plist data both encoded in UTF-8 format.
	//		We detect if it's plist data or not, by checking the first character,
	//		for plist, it is '<' or 0x3C in UTF-8 encoding.
	uint8_t	firstChar[1] = {0x3C};
#if 0
	NSString* dataString = [NSString stringWithData: self encoding: NSUTF8StringEncoding];
	NSLog(@"%@", dataString);
	NSData* fData = [NSData dataWithBytes: firstChar length: 1];
	NSLog(@"%@", [NSString stringWithData: fData encoding: NSUTF8StringEncoding]);
#endif
	BOOL stype = [self isPrefixedByByte: firstChar];
	
	if (stype) {
		return YES;
	}
	else {
		return NO;
	}
}

#define returnValueOfType(clazz)\
id result = nil;\
id o = [self objectValue];\
if( [o isKindOfClass: clazz] ) {\
	result = o;\
}\
return result\

-(NSDictionary*)dictionaryValue
{
	returnValueOfType([NSDictionary class]);
}

-(NSString*)stringValue
{
	return [NSString stringWithData: self encoding: NSUTF8StringEncoding];
}

-(NSArray*)arrayValue
{
	returnValueOfType([NSArray class]);
}

-(id)objectValue
{
	return [self jsonObjectValue];
}

@end
