//
//  NSAttributedString-NTIExtensions.m
//  NTIFoundation
//
//  Created by Christopher Utz on 10/25/11.
//  Copyright (c) 2011 NextThought. All rights reserved.
//

#import "NSAttributedString-NTIExtensions.h"
#import "NTIRTFDocument.h"
#import "NSAttributedString-HTMLWritingExtensions.h"
#import "NTITextAttachment.h"
#import <OmniAppKit/OmniAppKit.h>

@interface OATextAttachmentCell(NTIAttachmentCellWriterCoupling)
-(void)htmlWriter:(id)w exportHTMLToDataBuffer: (id)b withSize: (NSUInteger)s;
@end

/*
 * Provides methods for working with chunked attributed strings (usefull for multipart note/chat bodies).
 * An attributedString is chunked if it contains any one length ranges with the kNTIChunkSeparatorAttributeName.
 * The start of each chunk is signified by the presence of an attribute named kNTIChunkSeparatorAttributeName with
 * an undefined value.  Attributed strings with no chunk markers are treated as having one chunk that is the
 * entire string.
 */

@implementation NSAttributedString(NTIExtensions)

+(NSAttributedString*)attributedStringFromObject:(id)object
{
	if(!object){
		return [[NSAttributedString alloc] init];
	}
	
	if( [object isKindOfClass: [NSArray class]] ){
		return [NSAttributedString attributedStringFromObjects: object];
	}
	
	//If we return an attachment cell make it so, else are we 
	//a string or attributed string?  otherwise drop it
	id attrString = nil;
	
	if( [object isKindOfClass: [NSAttributedString class]] ){
		attrString = object;
	}
	else if( [object isKindOfClass: [NSString class] ] ){
		attrString = [NTIRTFDocument attributedStringWithString: object];
	}
	else if( [object respondsToSelector: @selector(attachmentCell)] ){
		OATextAttachmentCell* cell = [object attachmentCell];
		NTITextAttachment* attachment = [NTITextAttachment attachmentWithRenderer: cell];
		
		unichar attachmentCharacter = NSAttachmentCharacter;
		
		NSAttributedString* canvasAttrString = [[NSAttributedString alloc] 
												initWithString: 
												[NSString stringWithCharacters: &attachmentCharacter 
																		length:1] 
												attributeName: NSAttachmentAttributeName 
												attributeValue: attachment];
		attrString = canvasAttrString;
	}
	return attrString;
}

+(NSAttributedString*)attributedStringFromObjects: (NSArray*)objects
{	
	if(!objects || [objects count] == 0){
		return [[NSAttributedString alloc] init];
	}
	
	NSMutableArray* attrStrings = [[NSMutableArray alloc] initWithCapacity: [objects count]];
	
	for(id object in objects)
	{
		NSAttributedString* attrString = [NSAttributedString attributedStringFromObject: object];
		
		if(attrString){
			[attrStrings addObject: attrString];
		}
		else{
			NSLog(@"Waring: Unable to convert %@ to an attributed string", object);
		}
	}
	
	return [NSAttributedString attributedStringFromAttributedStrings: attrStrings];
}

+(NSAttributedString*)attributedStringFromAttributedStrings: (NSArray*)attrStrings
{
	NSAttributedString* attrString = [[NSAttributedString alloc] init];
	
	return [attrString attributedStringByAppendingChunks: attrStrings];
}

-(NSArray*)objectsFromAttributedString
{
	NSArray* attrStrings = [self attributedStringsFromParts];
	
	NSArray* externalParts = [attrStrings arrayByPerformingBlock:^id(id obj){
		NSAttributedString* part = obj;
		if(   part.length == 1 ){
		    id attachment = [part attribute: NSAttachmentAttributeName
									atIndex: 0
							 effectiveRange: NULL];
			
			if(  [attachment respondsToSelector: @selector(attachmentRenderer)] ){
				id attachmentCell = [attachment attachmentRenderer];
				if( [attachmentCell respondsToSelector: @selector(object)]  ){
					return [attachmentCell object];
				}
				else if( [attachmentCell respondsToSelector: @selector(htmlString)] ){
					return [attachmentCell htmlString];
				}
				
			}
			
			return [part htmlStringFromString];

		}
		//Else we assume its an html string like we always have
		return [part htmlStringFromString];
		
	}];
	
	return externalParts;
}

static void appendChunkToMutableAttributedString(NSMutableAttributedString* mutableAttrString, NSAttributedString* chunk)
{
	if(!chunk || [chunk length] < 1){
		return;
	}
	
	NSMutableAttributedString* toAddAsChunk = [[NSMutableAttributedString alloc] 
											   initWithAttributedString: chunk];
	
	[toAddAsChunk addAttribute: kNTIChunkSeparatorAttributeName 
						 value: [NSNumber numberWithBool: YES] 
						 range: NSMakeRange(0, 1)];
	
	[mutableAttrString appendAttributedString: toAddAsChunk];
}

-(NSAttributedString*)attributedStringByAppendingChunks: (NSArray*)chunks
{
	NSMutableAttributedString* mutableAttrString = [[NSMutableAttributedString alloc] 
													initWithAttributedString: self];
	
	for(NSAttributedString* chunk in chunks){
		appendChunkToMutableAttributedString(mutableAttrString, chunk);
	}
	
	return [[NSAttributedString alloc] initWithAttributedString: mutableAttrString];
}

-(NSAttributedString*)attributedStringByAppendingChunk:(NSAttributedString *)chunk
{	
	NSMutableAttributedString* mutableAttrString = [[NSMutableAttributedString alloc] 
													initWithAttributedString: self];
	
	appendChunkToMutableAttributedString(mutableAttrString, chunk);
	
	return [[NSAttributedString alloc] initWithAttributedString: mutableAttrString];
}

//We make a large assumption here. Any text attachment cell that doesn't respond to
//htmlWriter:exportHTMLToDataBuffer:withSize: must be in it's own chunk.  
static BOOL characterAtIndexRequiresOwnChunk(NSAttributedString* string, NSUInteger index)
{
	if([string.string characterAtIndex: index] != NSAttachmentCharacter){
		return NO;
	}
	NTITextAttachment* textAttachment = [string attribute: NSAttachmentAttributeName
												 atIndex: index
										  effectiveRange: NULL];
	
	return textAttachment
	&& ![(id)[textAttachment attachmentRenderer]
		 respondsToSelector: @selector(htmlWriter:exportHTMLToDataBuffer:withSize:)];
}

static NSAttributedString* correctMissingChunks(NSAttributedString* toCorrect)
{
	NSMutableAttributedString* corrected = [[NSMutableAttributedString alloc] initWithAttributedString: toCorrect];
	
	//Search the string for each OATextAttachmentCharacter.  When we find one if it responds to 
	//htmlWriter:exportHTMLToDataBuffer:withSize: move on to the next one.  If it does not
	//make sure that it is marked as the start of a chunk and the character following 
	//it (if not another object attachment) is marked as a new chunk.
	
	NSUInteger searchStart = 0;
	NSRange searchResult;
	unichar markerCharacter = NSAttachmentCharacter;
	NSString* markerString = [NSString stringWithCharacters: &markerCharacter
													 length: 1];
	while(searchStart < corrected.length){
		searchResult = [corrected.string rangeOfString: markerString
											   options: 0
												 range: NSMakeRange(searchStart, corrected.length - searchStart)];
		if(searchResult.location == NSNotFound){
			break;
		}
		
		if(characterAtIndexRequiresOwnChunk(corrected, searchResult.location)){
			[corrected addAttribute: kNTIChunkSeparatorAttributeName 
							  value: [NSNumber numberWithBool: YES] 
							  range: searchResult];
			if(	  searchResult.location + 1 < corrected.length 
			   && !characterAtIndexRequiresOwnChunk(corrected, searchResult.location + 1)){
				[corrected addAttribute: kNTIChunkSeparatorAttributeName
								  value: [NSNumber numberWithBool: YES] 
								  range: NSMakeRange(searchResult.location + 1, 1)];
			}
		}
		else{
			//Just continue the search
		}
		searchStart = NSMaxRange(searchResult);
	}
	
	return corrected;
}

//The idea for parsing is to look across the attributed string to identify characters that
//have an attribute of kNTIChunkSeparatorAttribute.  The presence of this attribute indicates
//the character starts a new chunk and the chunk continues untill the character before the next 
//separator or the end of the string.  A string with no separators is treated as one part.
//
//Unfortunately the above describes the perfect case in which all chunk markers are present
//however some things don't properly mark an html/string chunk that follows an object
//as a new chunk.  We attempt to detect this and fill in missing separators.  See comments
//on correctMissingChunks for details.
-(NSArray*)attributedStringsFromParts;
{
	__block NSMutableArray* result = [NSMutableArray arrayWithCapacity: 5];
	__block NSAttributedString* toSplit = correctMissingChunks(self);
	__block NSUInteger lastAddedIndex = NSNotFound;
	
	[toSplit enumerateAttributesInRange: NSMakeRange(0, toSplit.length)
								options: 0
							 usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
								 if([attrs objectForKey: kNTIChunkSeparatorAttributeName]){
									 [result addObject: [toSplit attributedSubstringFromRange: range]];
									 lastAddedIndex = result.count - 1;
								 }
								 else{
									 NSMutableAttributedString* lastAdded;
									 if(OFNOTEQUAL(@(lastAddedIndex), @(NSNotFound))){
										 lastAdded = [[NSMutableAttributedString alloc] initWithAttributedString:
													  [result objectAtIndex: lastAddedIndex]];
										 [lastAdded appendString: [toSplit attributedSubstringFromRange: range].string
													  attributes: attrs];
										 
										 [result replaceObjectAtIndex: lastAddedIndex
														   withObject: lastAdded];
									 }
									 else{
										 lastAdded = [[NSMutableAttributedString alloc] init];
										 [lastAdded appendString: [toSplit attributedSubstringFromRange: range].string
													  attributes: attrs];
										 
										 [result addObject: lastAdded];
										 lastAddedIndex = result.count - 1;
									 }
								 }
							 }];
	
	return [NSArray arrayWithArray: result];
}

-(NSAttributedString*)attributedStringByReplacingRange: (NSRange)range 
											 withChunk: (NSAttributedString *)chunk
{
	
	NSAttributedString* firstPart = [self attributedSubstringFromRange: NSMakeRange(0, range.location)];
	NSAttributedString* thirdPart = [self attributedSubstringFromRange:
									 NSMakeRange(NSMaxRange(range), self.length - (NSMaxRange(range)))];
	
	NSMutableAttributedString* result = [[NSMutableAttributedString alloc] initWithAttributedString: firstPart];
	appendChunkToMutableAttributedString(result, chunk);
	appendChunkToMutableAttributedString(result, thirdPart);
	
	return [[NSAttributedString alloc] initWithAttributedString: result];
}

static NSRegularExpression *attachmentRegex;

- (NSUInteger)indexofAttachment: (id)attachment
{
	NSUInteger index = NSNotFound;
	NSString *string = [self string];
	NSRange stringRange = NSMakeRange( 0, string.length );
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		// Matches the attachment character
		NSString *pattern = [NSString stringWithCharacter: NSAttachmentCharacter];
		attachmentRegex = [[NSRegularExpression alloc] initWithPattern: pattern
															   options: 0
																 error: nil];
	});
	// Find range of every attachment character index in |string|
	NSArray *matches = [attachmentRegex matchesInString: string
												options: 0
												  range: stringRange];
	// Check each attachment character index for |attachment|
	for (NSTextCheckingResult *result in matches) {
		NSRange matchRange = result.range;
		NSUInteger matchIndex = matchRange.location;
		id matchAttachment = [self attachmentAtCharacterIndex: matchIndex];
		if ( matchAttachment == attachment ) {
			index = matchIndex;
			break;
		}
	}
	return index;
}

-  (CGSize)sizeForWidth:(CGFloat)width multiLine:(BOOL)isMultiLine
{
	CGSize size = CGSizeMake(width, 0.0);
	NSStringDrawingOptions options = NSStringDrawingUsesFontLeading;
	if (isMultiLine) {
		options = options | NSStringDrawingUsesLineFragmentOrigin;
	}
	
	CGRect bounds = [self boundingRectWithSize:size
									   options:options
									   context:nil];
	return bounds.size;
}

@end
