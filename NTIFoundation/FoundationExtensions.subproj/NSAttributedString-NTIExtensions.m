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
#import <OmniAppKit/OATextAttachment.h>
#import <OmniAppKit/OATextStorage.h>
#import <OmniAppKit/OATextAttachmentCell.h>

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
		OATextAttachment* attachment = [[OATextAttachment alloc]
										initWithFileWrapper: nil];
		OATextAttachmentCell* cell = [object attachmentCell];
		attachment.attachmentCell = cell;
		OBASSERT(cell.attachment == attachment); // sets the backpointer
		
		unichar attachmentCharacter = OAAttachmentCharacter;
		
		NSAttributedString* canvasAttrString = [[NSAttributedString alloc] 
												initWithString: 
												[NSString stringWithCharacters: &attachmentCharacter 
																		length:1] 
												attributeName: OAAttachmentAttributeName 
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
		    id attachment = [part attribute: OAAttachmentAttributeName
									atIndex: 0
							 effectiveRange: NULL];
			
			if(  [attachment respondsToSelector: @selector(attachmentCell)] ){
				id attachmentCell = [attachment attachmentCell];
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
	if([string.string characterAtIndex: index] != OAAttachmentCharacter){
		return NO;
	}
	OATextAttachment* textAttachment = [string attribute: OAAttachmentAttributeName 
												 atIndex: index
										  effectiveRange: NULL];
	
	return textAttachment
	&& ![(id)[textAttachment attachmentCell]
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
	unichar markerCharacter = OAAttachmentCharacter;
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
	NSMutableArray* result = [NSMutableArray arrayWithCapacity: 5];
	
	NSAttributedString* toSplit = correctMissingChunks(self);
	
	NSUInteger inspectingIdx = 1;
	NSUInteger partStart=0;
	while(inspectingIdx < toSplit.length){
		//We found a new start
		if( [toSplit attribute: kNTIChunkSeparatorAttributeName atIndex: inspectingIdx effectiveRange: NULL] ){
			NSRange partRange = NSMakeRange(partStart, inspectingIdx - partStart);
			[result addObject: [toSplit attributedSubstringFromRange: partRange]];
			partStart = inspectingIdx;
		}
		
		inspectingIdx++;
	}
	
	//Make sure to grab the last part
	[result addObject: [toSplit attributedSubstringFromRange: 
						NSMakeRange(partStart, toSplit.length - partStart)]];
	
	
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

@end
