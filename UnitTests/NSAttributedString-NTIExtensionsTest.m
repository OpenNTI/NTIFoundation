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
	
	STAssertTrue(objects.count == 1, nil);
	STAssertEqualObjects([objects firstObject], @"foobar", nil);
}

-(void)testAttributedStringFromNilObjects
{
	STAssertEqualObjects([NSAttributedString attributedStringFromObject: nil],
						  [[NSAttributedString alloc] init], nil);
	
	STAssertEqualObjects([NSAttributedString attributedStringFromObjects: nil],
						 [[NSAttributedString alloc] init], nil);
	STAssertEqualObjects([NSAttributedString attributedStringFromObjects: [NSArray array]],
						 [[NSAttributedString alloc] init], nil);
}

-(void)testAttributeStringFromBasicObject
{
	NSAttributedString* objectString = [NSAttributedString attributedStringFromObject: 
										[[AttachableObject alloc] initWithObject: [NSNumber numberWithInt: 10]]];
	
	STAssertTrue([objectString length] == 1, nil);
	STAssertEquals([objectString.string characterAtIndex: 0], (unichar)NSAttachmentCharacter, nil);
	
	id attachment = [objectString attribute: NSAttachmentAttributeName atIndex: 0 effectiveRange: NULL];
	
	id attachmentCell = [attachment attachmentRenderer];
	
	STAssertEqualObjects([attachmentCell object], [NSNumber numberWithInt: 10], nil);
	
	NSAttributedString* helloWorldAttrString = [[NSAttributedString alloc] initWithString: @"Hello World"];
	
	STAssertEqualObjects([NSAttributedString attributedStringFromObject: @"Hello World"], helloWorldAttrString, nil);
	
	STAssertEqualObjects([NSAttributedString attributedStringFromObject: helloWorldAttrString], helloWorldAttrString, nil);
}

-(void)testAttributedStringFromArray
{
	NSArray* objects = [NSArray arrayWithObjects: [[AttachableObject alloc] initWithObject: [NSNumber numberWithInt: 1]],
						[[AttachableObject alloc] initWithObject: [NSNumber numberWithInt: 2]],
						[[AttachableObject alloc] initWithObject: [NSNumber numberWithInt: 3]], nil];
	
	NSArray* rawObjects = [objects arrayByPerformingBlock: ^(id object){
		return [object object];
	}];
	
	STAssertEqualObjects([[NSAttributedString attributedStringFromObjects: objects] objectsFromAttributedString], rawObjects, nil);
	
	STAssertEqualObjects([[NSAttributedString attributedStringFromObjects: objects] objectsFromAttributedString], 
						 [[NSAttributedString attributedStringFromObject: objects] objectsFromAttributedString], nil);
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

-(void)testObjectFollowedByTextNoSeparator
{
	AttachableObject* object = [[AttachableObject alloc] initWithObject: [NSNumber numberWithInt: 10]];
	
	NSMutableAttributedString* fullString = [[NSMutableAttributedString alloc] initWithAttributedString: [NSAttributedString attributedStringFromObject: object]];
	
	NSAttributedString* toAppend = [[NSAttributedString alloc] initWithString: @"Pizza" 
																attributeName: @"Kind" 
															   attributeValue: @"Meat"];
	[fullString appendAttributedString: toAppend];
	
	NSArray* parts = [fullString objectsFromAttributedString];
	
	STAssertEquals((int)[parts count], 2, nil);
	STAssertEqualObjects([parts firstObject], [NSNumber numberWithInt: 10], nil);
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
	
	STAssertEquals((int)[full length], 5, nil);
	STAssertNotNil([full attribute: kNTIChunkSeparatorAttributeName atIndex: 1 effectiveRange: NULL], nil);
	
	NSArray* splitParts = [full attributedStringsFromParts];
	
	STAssertEquals((int)[splitParts count], 2, nil);

	NSAttributedString* firstPart = [splitParts firstObject];
	STAssertEqualObjects(firstPart.string, @"I", nil);
	STAssertEqualObjects([firstPart attribute: @"Name" atIndex: 0 effectiveRange: NULL], @"Chris", nil);
	
	NSAttributedString* secondPart = [splitParts secondObject];
	STAssertEqualObjects(secondPart.string, @"Like", nil);
	STAssertEqualObjects([secondPart attribute: @"Amount" atIndex: 1 effectiveRange: NULL], 
						 [NSNumber numberWithInt: 11], nil);
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
	
	STAssertTrue(joined.string.length == 10, nil);
	STAssertEqualObjects(joined.string, @"ILikePizza", nil);
	
	NSArray* splitParts = [joined attributedStringsFromParts];
	
	STAssertEquals((int)[splitParts count], 3, nil);
	
	NSAttributedString* firstPart = [splitParts firstObject];
	STAssertEqualObjects(firstPart.string, @"I", nil);
	STAssertEqualObjects([firstPart attribute: @"Name" atIndex: 0 effectiveRange: NULL], @"Chris", nil);
	
	NSAttributedString* secondPart = [splitParts secondObject];
	STAssertEqualObjects(secondPart.string, @"Like", nil);
	STAssertEqualObjects([secondPart attribute: @"Amount" atIndex: 1 effectiveRange: NULL], 
						 [NSNumber numberWithInt: 11], nil);
	
	NSAttributedString* thirdPart = [splitParts lastObject];
	STAssertEqualObjects(thirdPart.string, @"Pizza", nil);
	STAssertEqualObjects([thirdPart attribute: @"Kind" atIndex: 1 effectiveRange: NULL], 
						 @"Meat", nil);
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
	STAssertEqualObjects(split1First.string, @"abc", nil);
	
	NSAttributedString* split2First = [split2 firstObject];
	STAssertEqualObjects(split2First.string, @"ab", nil);
	
	NSAttributedString* split2Last = [split2 lastObject];
	STAssertEqualObjects(split2Last.string, @"c", nil);
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
	
	STAssertEquals((int)[replaced length], 14, nil);
	STAssertEqualObjects(replaced.string, @"PepperoniPizza", nil);
	
	NSArray* parts = [replaced attributedStringsFromParts];
	
	STAssertEquals((int)[parts count], 2, nil);
	NSAttributedString* firstPart = [parts firstObject];
	STAssertEqualObjects(firstPart.string, @"Pepperoni", nil);
	
	NSAttributedString* secondPart = [parts secondObject];
	STAssertEqualObjects(secondPart.string, @"Pizza", nil);
	STAssertEqualObjects([secondPart attribute: @"Kind" atIndex: 1 effectiveRange: NULL], 
						 @"Meat", nil);

}

-(void)testReplacingAtTailOfSimpleAttributedString
{
	NSAttributedString* simpleString = simpleAttributedString();
	
	NSAttributedString* chunk = [[NSAttributedString alloc] initWithString: @"Dogs"];
	
	NSAttributedString* replaced = [simpleString attributedStringByReplacingRange: NSMakeRange(5, 5) 
																		withChunk: chunk];
	
	STAssertEquals((int)[replaced length], 9, nil);
	STAssertEqualObjects(replaced.string, @"ILikeDogs", nil);
	
	NSArray* splitParts = [replaced attributedStringsFromParts];
	
	NSAttributedString* firstPart = [splitParts firstObject];
	STAssertEqualObjects(firstPart.string, @"ILike", nil);
	STAssertEqualObjects([firstPart attribute: @"Name" atIndex: 0 effectiveRange: NULL], @"Chris", nil);
	STAssertEqualObjects([firstPart attribute: @"Amount" atIndex: 1 effectiveRange: NULL], 
						 [NSNumber numberWithInt: 11], nil);
	
	NSAttributedString* secondPart = [splitParts secondObject];
	STAssertEqualObjects(secondPart.string, @"Dogs", nil);
	STAssertNil([secondPart attribute: @"Kind" atIndex: 1 effectiveRange: NULL], nil);

}

-(void)testReplacingAtMidleOfSimpleAttributedString
{
	NSAttributedString* simpleString = simpleAttributedString();
	
	NSAttributedString* chunk = [[NSAttributedString alloc] initWithString: @"Hate"];
	
	NSAttributedString* replaced = [simpleString attributedStringByReplacingRange: NSMakeRange(1, 4) 
																		withChunk: chunk];
	
	STAssertTrue(replaced.string.length == 10, nil);
	STAssertEqualObjects(replaced.string, @"IHatePizza", nil);
	
	NSArray* splitParts = [replaced attributedStringsFromParts];
	
	STAssertEquals((int)[splitParts count], 3, nil);
	
	NSAttributedString* firstPart = [splitParts firstObject];
	STAssertEqualObjects(firstPart.string, @"I", nil);
	STAssertEqualObjects([firstPart attribute: @"Name" atIndex: 0 effectiveRange: NULL], @"Chris", nil);
	
	NSAttributedString* secondPart = [splitParts secondObject];
	STAssertEqualObjects(secondPart.string, @"Hate", nil);
	STAssertNil([secondPart attribute: @"Amount" atIndex: 1 effectiveRange: NULL], nil);
	
	NSAttributedString* thirdPart = [splitParts lastObject];
	STAssertEqualObjects(thirdPart.string, @"Pizza", nil);
	STAssertEqualObjects([thirdPart attribute: @"Kind" atIndex: 1 effectiveRange: NULL], 
						 @"Meat", nil);
	
}

@end
