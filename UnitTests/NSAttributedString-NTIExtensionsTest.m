//
//  NSAttributedString-NTIExtensionsTest.m
//  NTIFoundation
//
//  Created by Christopher Utz on 10/25/11.
//  Copyright (c) 2011 NextThought. All rights reserved.
//

#import "NSAttributedString-NTIExtensionsTest.h"
#import "NSAttributedString-NTIExtensions.h"
#import <OmniAppKit/OATextStorage.h>
@implementation NSAttributedString_NTIExtensionsTest


-(void)testAttributedStringFromAttributedStrings
{
	NSAttributedString* one = [[NSAttributedString alloc] initWithString: @"I" 
														   attributeName: @"Name" 
														  attributeValue: @"Chris"];
	
	NSAttributedString* two = [[NSAttributedString alloc] initWithString: @"Like" 
														   attributeName: @"Amount" 
														  attributeValue: [NSNumber numberWithInt: 11]];
	
	NSAttributedString* three = [[NSAttributedString alloc] initWithString: @"Pizza" 
															 attributeName: @"Kind" 
															attributeValue: @"Meat"];
	
	NSArray* parts = [NSArray arrayWithObjects: one, two, three, nil];
	
	NSAttributedString* joined = [NSAttributedString attributedStringFromAttributedStrings: parts];
	
	STAssertTrue(joined.string.length == 13, nil);
	
	STAssertTrue([joined.string characterAtIndex: 1] == OAAttachmentCharacter , nil);
	STAssertTrue([joined.string characterAtIndex: 6] == OAAttachmentCharacter , nil);
	STAssertTrue([joined.string characterAtIndex: joined.string.length -1 ] == OAAttachmentCharacter , nil);
	
	//What kind of pizza
	NSString* kind = [joined attribute: @"Kind" atIndex: 9 effectiveRange: NULL];
	STAssertEqualObjects(kind, @"Meat", nil);
	
	//On a scale of 1-10?
	NSNumber* amount = [joined attribute: @"Amount" atIndex: 3 effectiveRange: NULL];
	STAssertTrue([amount intValue] == 11, nil);
	
	STAssertNil([joined attribute: @"Amount" atIndex: 0 effectiveRange: NULL], nil);
}

-(void)testAttributedStringsFromAttributedString
{
	NSAttributedString* one = [[NSAttributedString alloc] initWithString: @"I" 
														   attributeName: @"Name" 
														  attributeValue: @"Chris"];
	
	NSAttributedString* two = [[NSAttributedString alloc] initWithString: @"Like" 
														   attributeName: @"Amount" 
														  attributeValue: [NSNumber numberWithInt: 11]];
	
	NSAttributedString* three = [[NSAttributedString alloc] initWithString: @"Pizza" 
															 attributeName: @"Kind" 
															attributeValue: @"Meat"];
	
	NSArray* parts = [NSArray arrayWithObjects: one, two, three, nil];
	
	NSAttributedString* joined = [NSAttributedString attributedStringFromAttributedStrings: parts];
	
	NSArray* splitParts = [joined attributedStringsFromParts];
	
	STAssertTrue([splitParts count] == [parts count], nil);
	STAssertEqualObjects([[splitParts firstObject] string], @"I", nil);
	STAssertEqualObjects([[splitParts secondObject] string], @"Like", nil);
	STAssertEqualObjects([[splitParts lastObject] string], @"Pizza", nil);
	
	STAssertEqualObjects([splitParts firstObject], one, nil);
	STAssertEqualObjects([splitParts secondObject], two, nil);
	STAssertEqualObjects([splitParts lastObject], three, nil);

}

@end
