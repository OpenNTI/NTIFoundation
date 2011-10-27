//
//  NSAttributedString-NTIExtensions.m
//  NTIFoundation
//
//  Created by Christopher Utz on 10/25/11.
//  Copyright (c) 2011 NextThought. All rights reserved.
//

#import "NSAttributedString-NTIExtensions.h"
#import <OmniAppKit/OATextAttachment.h>
#import <OmniAppKit/OATextStorage.h>

@implementation NSAttributedString(NTIExtensions)

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

-(NSAttributedString*)attributedStringByAppendingChunks: (NSArray*)chunks
{
	NSMutableAttributedString* mutableAttrString = [[NSMutableAttributedString alloc] 
													initWithAttributedString: self];
	
	//If the string isn't empty we need to insert 
	//a chunk attribute before adding our chunk
	if(mutableAttrString.length > 0){
		appendChunkSeparator(mutableAttrString);
	}
	
	for(NSUInteger i = 0 ; i < [chunks count]; i++){
		NSAttributedString* attrString = [chunks objectAtIndex: i];
		
		[mutableAttrString appendAttributedString: attrString];
		if(i < [chunks count] - 1){
			appendChunkSeparator(mutableAttrString);
		}
	}
	
	return [[NSAttributedString alloc] initWithAttributedString: mutableAttrString];
}

-(NSAttributedString*)attributedStringByAppendingChunk:(NSAttributedString *)chunk
{
	NSMutableAttributedString* mutableAttrString = [[NSMutableAttributedString alloc] 
													initWithAttributedString: self];
	//If the string isn't empty we need to insert 
	//a chunk attribute before adding our chunk
	if(mutableAttrString.length > 0){
		appendChunkSeparator(mutableAttrString);
	}
	
	[mutableAttrString appendAttributedString: chunk];
	
	return [[NSAttributedString alloc] initWithAttributedString: mutableAttrString];
}

//We walk through the string looking for our special attachment character
//If we don't find it we return an array with the attribute string provided to
//us.  If we do find it and it has our partnumber attribute then we extract it
//and look for the next part
-(NSArray*)attributedStringsFromParts;
{
	NSMutableArray* result = [NSMutableArray arrayWithCapacity: 5];
	
	
	
	unichar attachmentCharacter = OAAttachmentCharacter;
	NSString* separatorString = [NSString stringWithCharacters: &attachmentCharacter
													    length: 1];
	NSRange searchResult;
	NSUInteger partStartLocation = 0;
	NSRange searchRange = NSMakeRange(partStartLocation, self.length);
	do{
		searchResult = [self.string rangeOfString: separatorString options: 0 range:searchRange];
		
		//If its not found our part is from the search start to search end (end of string)
		NSRange partRange = NSMakeRange(NSNotFound, 0);
		if(searchResult.location == NSNotFound){
			partRange = NSMakeRange(partStartLocation, self.length - partStartLocation);
		}
		//We found a result.  Part range is from the search start to the searchresult location
		else{
			//There are two cases here.  We found our part separator or we found some other special
			//attachment marker.  The former case means we snag this part and stuff it in the array
			//In the latter case we have to keep looking
			if( [self attribute: kNTIChunkSeparatorAttributeName 
							  atIndex: searchResult.location 
					   effectiveRange: NULL] ){
				
				//Remember the result of rangeOfString is w.r.t the whole string not the range you search
				partRange = NSMakeRange(partStartLocation, searchResult.location - partStartLocation);
			}
			
			//Update search range so next go around we look further on in the string
			searchRange = NSMakeRange(NSMaxRange(searchResult), 
									  MAX(0UL, self.length - (searchResult.location+1)));
		}
		
		if(partRange.location != NSNotFound){
			NSAttributedString* part = [self attributedSubstringFromRange: partRange];
			partStartLocation += partRange.length + 1;
			if(part){
				[result addObject: part];
			}
		}
		
	}while (   searchResult.location != NSNotFound 
			&& NSMaxRange( searchRange ) <= self.length);	
	
	return [NSArray arrayWithArray: result];
}

@end
