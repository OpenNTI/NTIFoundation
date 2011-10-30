//
//  NSAttributedString-NTIExtensions.h
//  NTIFoundation
//
//  Created by Christopher Utz on 10/25/11.
//  Copyright (c) 2011 NextThought. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kNTIChunkSeparatorAttributeName @"NTIChunkSeparatorAttributeName"

@interface NSAttributedString(NTIExtensions)
+(NSAttributedString*)attributedStringFromObject: (id)object;
+(NSAttributedString*)attributedStringFromObjects: (NSArray*)objects;
+(NSAttributedString*)attributedStringFromAttributedStrings: (NSArray*)attrStrings;

-(NSArray*)objectsFromAttributedString;
-(NSAttributedString*)attributedStringAsChunkWithLeadingSeparator: (BOOL)leading 
											 andTrailingSeparator: (BOOL)trailing;
-(NSArray*)attributedStringsFromParts;
-(NSAttributedString*)attributedStringByAppendingChunk: (NSAttributedString*)chunk;
-(NSAttributedString*)attributedStringByAppendingChunks: (NSArray*)chunks;

@end
