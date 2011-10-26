//
//  NSAttributedString-NTIExtensions.h
//  NTIFoundation
//
//  Created by Christopher Utz on 10/25/11.
//  Copyright (c) 2011 NextThought. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSAttributedString(NTIExtensions)
+(NSAttributedString*)attributedStringFromAttributedStrings: (NSArray*)attrStrings;
-(NSArray*)attributedStringsFromParts;
@end
