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
#import <OmniAppKit/OATextAttachment.h>
#import <OmniAppKit/OATextAttachmentCell.h>

@interface ObjectAttachmentCell : OATextAttachmentCell {
@private
    id object;
}
-(id)initWithObject: (id)obj;
@property (nonatomic, strong) id object;
@end

@implementation ObjectAttachmentCell
@synthesize  object;
-(id)initWithObject: (id)obj
{
	self = [super init];
	self.object = obj;
	return self;
}

@end

@interface AttachableObject : OFObject{
	@private
	id object;
}
-(id)initWithObject: (id)obj;
@property (nonatomic, strong) id object;
@end

@implementation AttachableObject
@synthesize object;
-(id)initWithObject: (id)obj
{
	self = [super init];
	self.object = obj;
	return self;
}

-(id)attachmentCell
{
	return [[ObjectAttachmentCell alloc] initWithObject: self.object];
}

@end

@implementation NSAttributedString_NTIExtensionsTest

-(void)testAttributeStringFromBasicObject
{
	NSAttributedString* objectString = [NSAttributedString attributedStringFromObject: 
										[[AttachableObject alloc] initWithObject: [NSNumber numberWithInt: 10]]];
	
	STAssertTrue([objectString length] == 1, nil);
	STAssertEquals([objectString.string characterAtIndex: 0], (unichar)OAAttachmentCharacter, nil);
	
	id attachment = [objectString attribute: OAAttachmentAttributeName atIndex: 0 effectiveRange: NULL];
	
	id attachmentCell = [attachment attachmentCell];
	
	STAssertEqualObjects([attachmentCell object], [NSNumber numberWithInt: 10], nil);
}

-(void)testBasicObjectFromAttributedString
{
	id object = [NSNumber numberWithInt: 10];
	
	NSAttributedString* objectString = [NSAttributedString attributedStringFromObject: 
										[[AttachableObject alloc] initWithObject: object]];
	
	NSArray* parsedObjects = [objectString objectsFromAttributedString];
	
	STAssertTrue([parsedObjects count] == 1, nil);
	STAssertEqualObjects([parsedObjects firstObject], object, nil);
	
	
}

-(void)testObjectThenTextWithNoSeparator
{
	id object = [NSNumber numberWithInt: 10];
	
	NSAttributedString* objectString = [NSAttributedString attributedStringFromObject: 
										[[AttachableObject alloc] initWithObject: object]];
	
	NSMutableAttributedString* fullString = [[NSMutableAttributedString alloc] initWithAttributedString: objectString];
	[fullString appendAttributedString: [[NSAttributedString alloc] initWithString: @"text"]];
	
	NSArray* objects = [fullString objectsFromAttributedString];
	
	STAssertTrue([objects count] == 2, nil);
	STAssertEqualObjects([objects firstObject], object, nil);
	STAssertEqualObjects([objects secondObject], @"text", nil);
	
}

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
	
	STAssertTrue(joined.string.length == 12, nil);
	
	STAssertTrue([joined.string characterAtIndex: 1] == OAAttachmentCharacter , nil);
	STAssertTrue([joined.string characterAtIndex: 6] == OAAttachmentCharacter , nil);
	STAssertTrue([joined.string characterAtIndex: joined.string.length -1 ] != OAAttachmentCharacter , nil);
	
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
