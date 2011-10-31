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

static void appendChunkSeparator(NSMutableAttributedString* mAttrString)
{
	unichar attachmentCharacter = OAAttachmentCharacter;
	[mAttrString appendString: [NSString stringWithCharacters: &attachmentCharacter
												  length: 1] 
			  attributes: [NSDictionary dictionaryWithObject:  [[NSObject alloc] init]
													  forKey: kNTIChunkSeparatorAttributeName]];
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
			
			if(  [attachment respondsToSelector: @selector(attachmentCell)]
			   &&[[attachment attachmentCell] respondsToSelector: @selector(object)] ){
				id attachmentCell = [attachment attachmentCell];
				return [attachmentCell object];
			}
		}
		//Else we assume its an html string like we always have
		return [part htmlStringFromString];
		
	}];
	
	return externalParts;
}

-(NSAttributedString*)attributedStringAsChunkWithLeadingSeparator: (BOOL)leading 
											 andTrailingSeparator: (BOOL)trailing
{
	NSMutableAttributedString* mutableAttrString = [[NSMutableAttributedString alloc] init];
	
	//TODO Need to check that leading and trailing separators don't already exist?
	if(leading){
		appendChunkSeparator( mutableAttrString );
	}
	[mutableAttrString appendAttributedString: self];
	if(trailing){
		appendChunkSeparator( mutableAttrString );
	}
	
	return [[NSAttributedString alloc] initWithAttributedString: mutableAttrString];
}

-(NSAttributedString*)attributedStringByAppendingChunks: (NSArray*)chunks
{
	NSMutableAttributedString* mutableAttrString = [[NSMutableAttributedString alloc] 
													initWithAttributedString: self];
	
	//Do we need to start a new chunk?
	if( self.length > 0 && ![self attribute: kNTIChunkSeparatorAttributeName 
									atIndex: self.length - 1 
							 effectiveRange: NULL] ){
		appendChunkSeparator(mutableAttrString);
	}
	
	for(NSUInteger i = 0 ; i < [chunks count]; i++){
		NSAttributedString* attrString = [chunks objectAtIndex: i];
		
		[mutableAttrString appendAttributedString: attrString];
		if( i < [chunks count]-1 ){
			appendChunkSeparator(mutableAttrString);
		}
	}
	
	return [[NSAttributedString alloc] initWithAttributedString: mutableAttrString];
}

-(NSAttributedString*)attributedStringByAppendingChunk:(NSAttributedString *)chunk
{
	NSMutableAttributedString* mutableAttrString = [[NSMutableAttributedString alloc] 
													initWithAttributedString: self];
	
	//Do we need to start a new chunk?
	if( self.length > 0 && ![self attribute: kNTIChunkSeparatorAttributeName 
									atIndex: self.length - 1 
							 effectiveRange: NULL] ){
		appendChunkSeparator(mutableAttrString);
	}
	
	[mutableAttrString appendAttributedString: chunk];
	
	//appendChunkSeparator(mutableAttrString);
	
	return [[NSAttributedString alloc] initWithAttributedString: mutableAttrString];
}

//In the perfect case parts are separated by an attachment charater that
//has our special chunking attribute.  However, it is possible that this character
//ends up deleted leaving two different types of objects in what appears to be 
//the same part.  We identify this change in object type be checking if the
//attachment cell responds to exportHTMLToDataBuffer.  If it does it can be lumped
//in with the text part..
-(NSArray*)attributedStringsFromParts;
{
	NSMutableArray* result = [NSMutableArray arrayWithCapacity: 5];
	unichar attachmentCharacter = OAAttachmentCharacter;
	NSString* potentialSeparatorString = [NSString stringWithCharacters: &attachmentCharacter
																 length: 1];
	
	//Starting at the beginning of the attrString find the first potential part split (OAAttachmentCharacter)
	NSRange searchResult;
	NSUInteger partStartLocation = 0;
	NSRange searchRange = NSMakeRange(partStartLocation, self.length);
	do{	
		searchResult = [self.string rangeOfString: potentialSeparatorString options: 0 range:searchRange];
		
		//The easy case is that there is no potential separator left.  When this happens
		//We collect from the partStart to the end of the string
		if(searchResult.location == NSNotFound){
			NSRange partRange = NSMakeRange(partStartLocation, self.length - partStartLocation);
			NSAttributedString* part = [self attributedSubstringFromRange: partRange];
			if(part && part.length > 0){
				[result addObject: part];
			}
			partStartLocation = NSMaxRange(partRange) + 1;
			NSUInteger searchLength = partStartLocation < self.length ? self.length - partStartLocation : 0;
			searchRange = NSMakeRange(partStartLocation, searchLength);
		}
		//We found a potential split
		else{
			//There are three posibilities here
			//1. potential split is a split triggered by a separator
			//2. potential split is a split triggered by an attachment that can't be
			//	 written as html
			//3. not a split
			//TODO Need test cases for 2 and 3
			
			OATextAttachment* textAttachment = [self attribute: OAAttachmentAttributeName 
													   atIndex: searchResult.location 
												effectiveRange: NULL];
			
			//Case 1.  we are a split b/c of a separator
			if( [self attribute: kNTIChunkSeparatorAttributeName 
						atIndex: searchResult.location 
				 effectiveRange: NULL] ){
				//The part is everything from the partStart to the separator exclusive
				NSRange partRange = NSMakeRange(partStartLocation, searchResult.location - partStartLocation);
				NSAttributedString* part = [self attributedSubstringFromRange: partRange];
				if(part && part.length > 0){
					[result addObject: part];
				}
				
				//Now we need to look for the next part
				//starting at the character past the separator
				partStartLocation = NSMaxRange(partRange) + 1;
				NSUInteger searchLength = partStartLocation <= self.length ? self.length - partStartLocation : 0;
				searchRange = NSMakeRange(partStartLocation, searchLength);
			}
			//Case 2. we are a split b/c of an attachment cell that cant be written as html
			else if(    textAttachment
					&& ![(id)[textAttachment attachmentCell] respondsToSelector: @selector(htmlWriter:exportHTMLToDataBuffer:withSize:)]){
				//The part is everything from the partStart to the separator exclusive
				NSRange partRange = NSMakeRange(partStartLocation,searchResult.location - partStartLocation);
				NSAttributedString* part = [self attributedSubstringFromRange: partRange];
				if(part && part.length > 0){
					[result addObject: part];
				}
				//Next partStart is the character that was our separator
				partStartLocation = searchResult.location;
				NSUInteger searchLength = partStartLocation + 1 <= self.length ? self.length - (partStartLocation + 1) : 0;
				searchRange = NSMakeRange(partStartLocation + 1, searchLength);
				
			}
			//Case 3 we aren't a split
			else{
				//We need to continue our search after the potential split
				//character we just checked
				
				//Do we have anymore characters to check
				if(searchResult.location < self.length - 1 ){
					NSUInteger nextSearchStart = NSMaxRange(searchResult);
					NSUInteger searchLength = nextSearchStart <= self.length ? self.length - nextSearchStart : 0;
					searchRange = NSMakeRange(nextSearchStart, searchLength);
				}
				//No more searching to do... we are in the last part
				//gather it up and finish
				else{
					NSRange partRange = NSMakeRange(partStartLocation, self.length - partStartLocation);
					NSAttributedString* part = [self attributedSubstringFromRange: partRange];
					if(part && part.length > 0){
						[result addObject: part];
					}
					partStartLocation = NSMaxRange(partRange) + 1;
					NSUInteger searchLength = partStartLocation <= self.length ? self.length - partStartLocation : 0;
					searchRange = NSMakeRange(partStartLocation, searchLength);
				}
			}
			
		}
		
	}while (   searchResult.location != NSNotFound 
			&& NSMaxRange(searchRange) <= self.length );	
	
	return [NSArray arrayWithArray: result];
}

@end
