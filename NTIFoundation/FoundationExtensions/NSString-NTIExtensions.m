//
//  NSString-NTIExtensions.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/21.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NSString-NTIExtensions.h"

@implementation NSString (NTIConversions)

-(BOOL)javascriptBoolValue
{
	return [@"true" isEqualToString: self];	
}

-(NSInteger)longValue 
{
	return [self integerValue]; 
}
@end

static NSDateFormatter* rfc3339DateFormatter()
{
	static NSDateFormatter* rfc3339DateFormatter = nil;
	if( !rfc3339DateFormatter ) {
		rfc3339DateFormatter = [[NSDateFormatter alloc] init];
		NSLocale* enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
	
		[rfc3339DateFormatter setLocale: enUSPOSIXLocale];
		[rfc3339DateFormatter setDateFormat: @"EEE, dd MMM yyyy HH:mm:ss 'GMT'"];
		[rfc3339DateFormatter setTimeZone: [NSTimeZone timeZoneForSecondsFromGMT: 0]];
	}
	return rfc3339DateFormatter;
}

@implementation NSString (NTIHTTPHeaderConversions)

-(NSDate*)httpHeaderDateValue
{
    NSDate* date = [rfc3339DateFormatter() dateFromString: self];
	return date;
}

@end

@implementation NSDate(NTIHTTPHeaderConversions)
-(NSString*)httpHeaderStringValue
{
	return [rfc3339DateFormatter() stringFromDate: self];	
}
@end


@implementation NSString (NTIExtensions)

+(NSString*)uuid
{
	CFUUIDRef theUUID = CFUUIDCreate(NULL);
	NSString* uuidString = (__bridge_transfer NSString*) CFUUIDCreateString(NULL, theUUID);
	CFRelease(theUUID);
	return uuidString;
}

- (BOOL)isEmpty
{
	return [NSString isEmptyString: self];
}

- (BOOL)notEmpty
{
	return !self.isEmpty;
}

-(NSArray*)piecesUsingRegex: (NSRegularExpression*)regex
{
	NSArray* results = [regex matchesInString: self options:0 range:NSMakeRange(0, [self length])];
	NSMutableArray* parts = [NSMutableArray arrayWithCapacity: regex.numberOfCaptureGroups];
	for (NSTextCheckingResult* result in results) {
		
		for(NSUInteger i = 1 ; i<=regex.numberOfCaptureGroups; i++ ){
			NSRange range = [result rangeAtIndex: i];
			if(range.location == NSNotFound){
				[parts addObject: @""];
			}else{
				[parts addObject: [self substringWithRange: range]];
			}
		}
		
		//Only take the first match
		break;
	}
	return parts;
}

-(NSArray*)piecesUsingRegexString: (NSString*)regexString
{
	NSError* error = nil;
	NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern: regexString 
																		   options: 0 
																			 error: &error];
	
	if (error) {
		NSLog(@"%@", [error description]);
		return nil;
	}
	
	return [self piecesUsingRegex: regex];
}

-(BOOL)isEqualToStringIgnoringCase:(NSString *)s
{
    return [self caseInsensitiveCompare: s] == NSOrderedSame;
}

- (NSString *)stringByRemovingHTML
{
	NSString *string = [self copy];
	NSRange range = [string rangeOfString: @"<[^>]+>"
								  options: NSRegularExpressionSearch];
	while ( range.location != NSNotFound ) {
		string = [string stringByReplacingCharactersInRange: range
												 withString: @""];
		range = [string rangeOfString: @"<[^>]+>"
							  options: NSRegularExpressionSearch];
	}
	return string;
}

- (NSString *)stringByReplacingAmpEscapes
{
	NSMutableString *string = [self mutableCopy];
	[string replaceOccurrencesOfString: @"&amp;"
							withString: @"&"
									 options: 1
								 range: NSMakeRange(0, string.length)];
	[string replaceOccurrencesOfString: @"&lt;"
							withString: @"<"
									 options: 1
								 range: NSMakeRange(0, string.length)];
	[string replaceOccurrencesOfString: @"&gt;"
							withString: @">"
									 options: 1
								 range: NSMakeRange(0, string.length)];
	[string replaceOccurrencesOfString: @"&lrm;"
							withString: @"\u200e"
									 options: 1
								 range: NSMakeRange(0, string.length)];
	[string replaceOccurrencesOfString: @"&rlm;"
							withString: @"\u200f"
									 options: 1
								 range: NSMakeRange(0, string.length)];
	[string replaceOccurrencesOfString: @"&nbsp;"
							withString: @"\u00a0"
									 options: 1
								 range: NSMakeRange(0, string.length)];
	return [string copy];
}

@end
