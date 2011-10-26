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


static BOOL stringMayBeFloat( NSString* trimmed )
{
	static NSCharacterSet* period = nil;
	if( !period ) {
		period = [NSCharacterSet characterSetWithCharactersInString: @"."];
	}
	return [trimmed rangeOfCharacterFromSet: period].location != NSNotFound;
}

@implementation NSString(NTIJSON)

-(NSString*)stringWithJsonRepresentation
{
	//use ios5 if possible.
	NTI_RETURN_SELF_TO_JSON();
	
	NSString* escaped = [self stringByReplacingAllOccurrencesOfString: @"\n" withString: @"\\n"];
	
	return [NSString stringWithFormat: @"\"%@\"", escaped];
}

//For inclusion in a collection, must make nil into NSNull
static id wrap( id o )
{
	return o ? o : [NSNull null];
}

-(NSMutableArray*)jsonObjectArrayStartingAt: (NSUInteger*)ix
								  
{
	NSUInteger x = 1;
	if( ix == NULL ) {
		ix = &x;
	}
	OBPRECONDITION( [self characterAtIndex: *ix] == '[' );
	//TODO: Not robust against badly formed input. Throws exception?
	NSMutableArray* parts = [NSMutableArray arrayWithCapacity: 3];
	NSMutableString* buf = [NSMutableString stringWithCapacity: 10];

	while( *ix < self.length ) {
		unichar theChar = [self characterAtIndex: *ix];
		if( theChar == ']' ) {
			if( [buf length] > 0){
				id part = [buf jsonObjectValue];
				[parts addObject: wrap(part)];
			}
			[buf setString: @""];
			break;
		}
		
		if( theChar == '[' ) {
			(*ix)++;
			[parts addObject: wrap([self jsonObjectArrayStartingAt: ix])];
			[buf setString: @""];
		}
		else if( theChar == ',' ) {
			if( [buf length] > 0 ){
				id part = [buf jsonObjectValue];
				[parts addObject: wrap(part)];
			}
			[buf setString: @""];
		}
		else {
			[buf appendFormat: @"%c", theChar];
		}
		(*ix)++;
	}
	
	return parts;
}

-(id)jsonObjectValue
{
	
	//If the iOS 5 class is available, use it happily.
	id jsonClass = getClass_NSJSONSerialization();
	if( jsonClass ) {
		id result = [jsonClass JSONObjectWithData: [self dataUsingEncoding: NSUTF8StringEncoding]
							  options: NSJSONReadingMutableContainers 
										| NSJSONReadingMutableLeaves
										| NSJSONReadingAllowFragments
								error: nil];
		return result;
	}
	
	id result = nil;
	NSString* trimmed = [self stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if( [NSString isEmptyString: trimmed] ) {
		result = nil;
	}
	else if( [trimmed hasPrefix: @"["] && [trimmed hasSuffix: @"]"] ) {
		if( [trimmed isEqual: @"[]"] ) {
			//empty is common, optimize for it.
			result = [NSArray array];
		}
		else {
			result = [trimmed jsonObjectArrayStartingAt: NULL];
		}
	}
	else if( [trimmed hasPrefix: @"\""] && [trimmed hasSuffix: @"\""] ) {
		trimmed = [trimmed substringWithRange: NSMakeRange( 1,  trimmed.length - 2 )];
		//Unescaping. Really incomplete.
		result = [trimmed stringByReplacingAllOccurrencesOfString: @"\\\""
													   withString: @"\""];
	}
	else if( [@"null" isEqual: trimmed] ) {
		result = nil;
	}
	//The last thing we'll deal with is numbers.
	else if( stringMayBeFloat( trimmed ) ) {
		//Omni's NSString -numberValue only deals with ints right now.
		result = [NSDecimalNumber decimalNumberWithString: trimmed];
	}
	else {
		result = [self numberValue];
	}
	
	
	return result;
}
@end

@implementation NSObject(NTIJSON)

-(id)jsonObjectUnwrap
{
	return [self isNull] ? nil : self;	
}

@end
