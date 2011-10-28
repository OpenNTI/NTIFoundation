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
+(NSAttributedString*)attributedStringFromAttributedStrings: (NSArray*)attrStrings;
-(NSAttributedString*)attributedStringAsChunkWithLeadingSeparator: (BOOL)leading 
											 andTrailingSeparator: (BOOL)trailing;
-(NSArray*)attributedStringsFromParts;
-(NSAttributedString*)attributedStringByAppendingChunk: (NSAttributedString*)chunk;
-(NSAttributedString*)attributedStringByAppendingChunks: (NSArray*)chunks;
@end
