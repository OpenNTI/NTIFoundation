//
//  NSString-NTIExtensions.h
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/21.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (NTIConversions)

/**
 * Returns YES if this string is the string representing JavaScript's "true"
 * boolean.
 */
-(BOOL)javascriptBoolValue;

/**
 * This message is sent during KVC setting an NSInteger property when
 * the value in the dictionary is a string (as could be coming in
 * from external representation).
 */
-(NSInteger)longValue;

@end

@interface NSString (NTIHTTPHeaderConversions)

/**
 * Returns the value of parsing this string as an RFC339 HTTP header
 * value.
 */
-(NSDate*)httpHeaderDateValue;
@end

@interface NSDate(NTIHTTPHeaderConversions)
/**
 * Returns the value of formatting this object as an 
 * RFC3339 HTTP header string.
 */
-(NSString*)httpHeaderStringValue;

@end

@interface NSString (NTIExtensions)

+(NSString*)uuid;
-(NSArray*)piecesUsingRegex: (NSRegularExpression*)regex;
-(NSArray*)piecesUsingRegexString: (NSString*)regex;

@end
