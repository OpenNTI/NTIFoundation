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
	NSMutableAttributedString* result = [[NSMutableAttributedString alloc] init];
	
	for(NSUInteger i = 0 ; i < [attrStrings count]; i++){
		NSAttributedString* attrString = [attrStrings objectAtIndex: i];
		
		[result appendAttributedString: attrString];
		if(i < [attrStrings count] - 1){
			unichar attachmentCharacter = OAAttachmentCharacter;
			[result appendString: [NSString stringWithCharacters: &attachmentCharacter
														  length: 1] 
					  attributes: [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: i] 
															  forKey: @"NTIPartNumberAttributeName"]];
		}
	}
	
	return [result autorelease];
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
	NSRange searchRange = NSMakeRange(partStartLocation, self.string.length);
	do{
		searchResult = [self.string rangeOfString: separatorString options: 0 range:searchRange];
		
		//If its not found our part is from the search start to search end (end of string)
		NSRange partRange = NSMakeRange(NSNotFound, 0);
		if(searchResult.location == NSNotFound){
			partRange = NSMakeRange(searchRange.location, searchRange.length);
		}
		//We found a result.  Part range is from the search start to the searchresult location
		else{
			//There are two cases here.  We found our part separator or we found some other special
			//attachment marker.  The former case means we snag this part and stuff it in the array
			//In the latter case we have to keep looking
			if( [self attribute: @"NTIPartNumberAttributeName" 
							  atIndex: searchResult.location 
					   effectiveRange: NULL] ){
				
				//Remember the result of rangeOfString is w.r.t the whole string not the range you search
				partRange = NSMakeRange(partStartLocation, searchResult.location - partStartLocation);
			}
			
			//Update search range so next go around we look further on in the string
			searchRange = NSMakeRange(searchResult.location+1, 
									  MAX(0UL, self.string.length - (searchResult.location+1)));
		}
		
		if(partRange.location != NSNotFound){
			NSAttributedString* part = [self attributedSubstringFromRange: partRange];
			partStartLocation += partRange.length + 1;
			if(part){
				[result addObject: part];
			}
		}
		
	}while (   searchResult.location != NSNotFound 
			&& NSMaxRange( searchRange ) <= self.string.length);	
	
	return [NSArray arrayWithArray: result];
}

@end
