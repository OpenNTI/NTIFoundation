//
//  NSAttributedString-NTIExtensionsTest.m
//  NTIFoundation
//
//  Created by Christopher Utz on 10/25/11.
//  Copyright (c) 2011 NextThought. All rights reserved.
//

#import "NSAttributedString-NTIExtensionsTest.h"
#import "NSAttributedString-NTIExtensions.h"
#import "NSAttributedString-HTMLReadingExtensions.h"
#import "NTITextAttachment.h"
#import <OmniAppKit/OATextStorage.h>
#import <OmniAppKit/OATextAttachmentCell.h>
#import "NSArray-NTIExtensions.h"

@interface HTMLAttachmentCell : OATextAttachmentCell {
@private
    NSString* htmlString;
}
-(id)initWithHtml: (NSString*)html;
@property (nonatomic, strong) NSString* htmlString;
@end

@implementation HTMLAttachmentCell
@synthesize  htmlString;
-(id)initWithHtml: (NSString*)obj
{
	self = [super init];
	self.htmlString = obj;
	return self;
}

-(id)attachmentRenderer
{
	return self;
}

@end

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

-(void)testHTMLAttributedString
{
	unichar attachmentCharacter = NSAttachmentCharacter;
	NSString* charString = [[NSString alloc] initWithCharacters: &attachmentCharacter length: 1];
	
	NSDictionary* attrs = [NSDictionary dictionaryWithObject: [[HTMLAttachmentCell alloc] initWithHtml: @"foobar"] 
													  forKey: NSAttachmentAttributeName];
	
	NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc] 
											 initWithString: charString 
											 attributes: attrs];
	
	NSArray* objects = [attrString objectsFromAttributedString];
	
	XCTAssertTrue(objects.count == 1);
	XCTAssertEqualObjects([objects firstObject], @"foobar");
}

-(void)testAttributedStringFromNilObjects
{
	XCTAssertEqualObjects([NSAttributedString attributedStringFromObject: nil],
						  [[NSAttributedString alloc] init]);
	
	XCTAssertEqualObjects([NSAttributedString attributedStringFromObjects: nil],
						 [[NSAttributedString alloc] init]);
	XCTAssertEqualObjects([NSAttributedString attributedStringFromObjects: [NSArray array]],
						 [[NSAttributedString alloc] init]);
}

-(void)testAttributeStringFromBasicObject
{
	NSAttributedString* objectString = [NSAttributedString attributedStringFromObject: 
										[[AttachableObject alloc] initWithObject: [NSNumber numberWithInt: 10]]];
	
	XCTAssertTrue([objectString length] == 1);
	XCTAssertEqual([objectString.string characterAtIndex: 0], (unichar)NSAttachmentCharacter);
	
	id attachment = [objectString attribute: NSAttachmentAttributeName atIndex: 0 effectiveRange: NULL];
	
	id attachmentCell = [attachment attachmentRenderer];
	
	XCTAssertEqualObjects([attachmentCell object], [NSNumber numberWithInt: 10]);
	
	NSAttributedString* helloWorldAttrString = [[NSAttributedString alloc] initWithString: @"Hello World"];
	
	XCTAssertEqualObjects([NSAttributedString attributedStringFromObject: @"Hello World"], helloWorldAttrString);
	
	XCTAssertEqualObjects([NSAttributedString attributedStringFromObject: helloWorldAttrString], helloWorldAttrString);
}

-(void)testAttributedStringFromArray
{
	NSArray* objects = [NSArray arrayWithObjects: [[AttachableObject alloc] initWithObject: [NSNumber numberWithInt: 1]],
						[[AttachableObject alloc] initWithObject: [NSNumber numberWithInt: 2]],
						[[AttachableObject alloc] initWithObject: [NSNumber numberWithInt: 3]], nil];
	
	NSArray* rawObjects = [objects arrayByPerformingBlock: ^(id object){
		return [object object];
	}];
	
	XCTAssertEqualObjects([[NSAttributedString attributedStringFromObjects: objects] objectsFromAttributedString], rawObjects);
	
	XCTAssertEqualObjects([[NSAttributedString attributedStringFromObjects: objects] objectsFromAttributedString], 
						 [[NSAttributedString attributedStringFromObject: objects] objectsFromAttributedString]);
}

-(void)testBasicObjectFromAttributedString
{
	id object = [NSNumber numberWithInt: 10];
	
	NSAttributedString* objectString = [NSAttributedString attributedStringFromObject: 
										[[AttachableObject alloc] initWithObject: object]];
	
	NSArray* parsedObjects = [objectString objectsFromAttributedString];
	
	XCTAssertTrue([parsedObjects count] == 1);
	XCTAssertEqualObjects([parsedObjects firstObject], object);
	
	
}

-(void)testObjectFollowedByTextNoSeparator
{
	AttachableObject* object = [[AttachableObject alloc] initWithObject: [NSNumber numberWithInt: 10]];
	
	NSMutableAttributedString* fullString = [[NSMutableAttributedString alloc] initWithAttributedString: [NSAttributedString attributedStringFromObject: object]];
	
	NSAttributedString* toAppend = [[NSAttributedString alloc] initWithString: @"Pizza" 
																attributeName: @"Kind" 
															   attributeValue: @"Meat"];
	[fullString appendAttributedString: toAppend];
	
	NSArray* parts = [fullString objectsFromAttributedString];
	
	XCTAssertEqual((int)[parts count], 2);
	XCTAssertEqualObjects([parts firstObject], [NSNumber numberWithInt: 10]);
}

#pragma mark Chunking related tests
-(void)testAttributedStringByAppendingSingleChunk
{
	NSAttributedString* one = [[NSAttributedString alloc] initWithString: @"I" 
														   attributeName: @"Name" 
														  attributeValue: @"Chris"];
	
	NSAttributedString* two = [[NSAttributedString alloc] initWithString: @"Like" 
														   attributeName: @"Amount" 
														  attributeValue: [NSNumber numberWithInt: 11]];
	
	NSAttributedString* full = [one attributedStringByAppendingChunk: two];
	
	XCTAssertEqual((int)[full length], 5);
	XCTAssertNotNil([full attribute: kNTIChunkSeparatorAttributeName atIndex: 1 effectiveRange: NULL]);
	
	NSArray* splitParts = [full attributedStringsFromParts];
	
	XCTAssertEqual((int)[splitParts count], 2);

	NSAttributedString* firstPart = [splitParts firstObject];
	XCTAssertEqualObjects(firstPart.string, @"I");
	XCTAssertEqualObjects([firstPart attribute: @"Name" atIndex: 0 effectiveRange: NULL], @"Chris");
	
	NSAttributedString* secondPart = [splitParts secondObject];
	XCTAssertEqualObjects(secondPart.string, @"Like");
	XCTAssertEqualObjects([secondPart attribute: @"Amount" atIndex: 1 effectiveRange: NULL], 
						 [NSNumber numberWithInt: 11]);
}

-(void)testAttributedStringsByAppendingChunks
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
	
	XCTAssertTrue(joined.string.length == 10);
	XCTAssertEqualObjects(joined.string, @"ILikePizza");
	
	NSArray* splitParts = [joined attributedStringsFromParts];
	
	XCTAssertEqual((int)[splitParts count], 3);
	
	NSAttributedString* firstPart = [splitParts firstObject];
	XCTAssertEqualObjects(firstPart.string, @"I");
	XCTAssertEqualObjects([firstPart attribute: @"Name" atIndex: 0 effectiveRange: NULL], @"Chris");
	
	NSAttributedString* secondPart = [splitParts secondObject];
	XCTAssertEqualObjects(secondPart.string, @"Like");
	XCTAssertEqualObjects([secondPart attribute: @"Amount" atIndex: 1 effectiveRange: NULL], 
						 [NSNumber numberWithInt: 11]);
	
	NSAttributedString* thirdPart = [splitParts lastObject];
	XCTAssertEqualObjects(thirdPart.string, @"Pizza");
	XCTAssertEqualObjects([thirdPart attribute: @"Kind" atIndex: 1 effectiveRange: NULL], 
						 @"Meat");
}

-(void)testAttributedStringWithAmbiguousChunks
{
	NSAttributedString* one = [[NSAttributedString alloc] initWithString: @"abc"
															  attributes: @{kNTIChunkSeparatorAttributeName:@1}];
	
	NSAttributedString* twoA = [[NSAttributedString alloc] initWithString: @"a"
															attributeName: kNTIChunkSeparatorAttributeName
														   attributeValue: @1];
	NSAttributedString* twoB = [[NSAttributedString alloc] initWithString: @"b"
															attributeName: @"something"
														   attributeValue: @"here"];
	NSAttributedString* twoC = [[NSAttributedString alloc] initWithString: @"c"
															   attributes: @{kNTIChunkSeparatorAttributeName:@1}];
	
	NSMutableAttributedString* two = [[NSMutableAttributedString alloc] initWithAttributedString: twoA];
	[two appendAttributedString: twoB];
	[two appendAttributedString: twoC];
	
	NSArray* split1 = [one attributedStringsFromParts];
	NSArray* split2 = [two attributedStringsFromParts];
	
	NSAttributedString* split1First = [split1 firstObject];
	XCTAssertEqualObjects(split1First.string, @"abc");
	
	NSAttributedString* split2First = [split2 firstObject];
	XCTAssertEqualObjects(split2First.string, @"ab");
	
	NSAttributedString* split2Last = [split2 lastObject];
	XCTAssertEqualObjects(split2Last.string, @"c");
}

static NSAttributedString* simpleAttributedString(){
	NSAttributedString* one = [[NSAttributedString alloc] initWithString: @"I" 
														   attributeName: @"Name" 
														  attributeValue: @"Chris"];
	
	NSAttributedString* two = [[NSAttributedString alloc] initWithString: @"Like" 
														   attributeName: @"Amount" 
														  attributeValue: [NSNumber numberWithInt: 11]];
	
	NSAttributedString* three = [[NSAttributedString alloc] initWithString: @"Pizza" 
															 attributeName: @"Kind" 
															attributeValue: @"Meat"];
	NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc] initWithAttributedString: one];
	[attrString appendAttributedString: two];
	[attrString appendAttributedString: three];
	return attrString;
}

-(void)testReplacingAtHeadOfSimpleAttributedString
{
	NSAttributedString* simpleString = simpleAttributedString();
	
	NSAttributedString* chunk = [[NSAttributedString alloc] initWithString: @"Pepperoni"];
	
	NSAttributedString* replaced = [simpleString attributedStringByReplacingRange: NSMakeRange(0, 5) 
																		withChunk: chunk];
	
	XCTAssertEqual((int)[replaced length], 14);
	XCTAssertEqualObjects(replaced.string, @"PepperoniPizza");
	
	NSArray* parts = [replaced attributedStringsFromParts];
	
	XCTAssertEqual((int)[parts count], 2);
	NSAttributedString* firstPart = [parts firstObject];
	XCTAssertEqualObjects(firstPart.string, @"Pepperoni");
	
	NSAttributedString* secondPart = [parts secondObject];
	XCTAssertEqualObjects(secondPart.string, @"Pizza");
	XCTAssertEqualObjects([secondPart attribute: @"Kind" atIndex: 1 effectiveRange: NULL], 
						 @"Meat");

}

-(void)testReplacingAtTailOfSimpleAttributedString
{
	NSAttributedString* simpleString = simpleAttributedString();
	
	NSAttributedString* chunk = [[NSAttributedString alloc] initWithString: @"Dogs"];
	
	NSAttributedString* replaced = [simpleString attributedStringByReplacingRange: NSMakeRange(5, 5) 
																		withChunk: chunk];
	
	XCTAssertEqual((int)[replaced length], 9);
	XCTAssertEqualObjects(replaced.string, @"ILikeDogs");
	
	NSArray* splitParts = [replaced attributedStringsFromParts];
	
	NSAttributedString* firstPart = [splitParts firstObject];
	XCTAssertEqualObjects(firstPart.string, @"ILike");
	XCTAssertEqualObjects([firstPart attribute: @"Name" atIndex: 0 effectiveRange: NULL], @"Chris");
	XCTAssertEqualObjects([firstPart attribute: @"Amount" atIndex: 1 effectiveRange: NULL], 
						 [NSNumber numberWithInt: 11]);
	
	NSAttributedString* secondPart = [splitParts secondObject];
	XCTAssertEqualObjects(secondPart.string, @"Dogs");
	XCTAssertNil([secondPart attribute: @"Kind" atIndex: 1 effectiveRange: NULL]);

}

-(void)testReplacingAtMidleOfSimpleAttributedString
{
	NSAttributedString* simpleString = simpleAttributedString();
	
	NSAttributedString* chunk = [[NSAttributedString alloc] initWithString: @"Hate"];
	
	NSAttributedString* replaced = [simpleString attributedStringByReplacingRange: NSMakeRange(1, 4) 
																		withChunk: chunk];
	
	XCTAssertTrue(replaced.string.length == 10);
	XCTAssertEqualObjects(replaced.string, @"IHatePizza");
	
	NSArray* splitParts = [replaced attributedStringsFromParts];
	
	XCTAssertEqual((int)[splitParts count], 3);
	
	NSAttributedString* firstPart = [splitParts firstObject];
	XCTAssertEqualObjects(firstPart.string, @"I");
	XCTAssertEqualObjects([firstPart attribute: @"Name" atIndex: 0 effectiveRange: NULL], @"Chris");
	
	NSAttributedString* secondPart = [splitParts secondObject];
	XCTAssertEqualObjects(secondPart.string, @"Hate");
	XCTAssertNil([secondPart attribute: @"Amount" atIndex: 1 effectiveRange: NULL]);
	
	NSAttributedString* thirdPart = [splitParts lastObject];
	XCTAssertEqualObjects(thirdPart.string, @"Pizza");
	XCTAssertEqualObjects([thirdPart attribute: @"Kind" atIndex: 1 effectiveRange: NULL], 
						 @"Meat");
	
}

@end
