//
//  NTIExtensions+NSData.h
//  NTIFoundation
//
//  Created by Christopher Utz on 4/14/14.
//  Copyright (c) 2014 NextThought. All rights reserved.
//



@interface NSData (NTIExtensions)
-(BOOL)isPrefixedByByte:(const uint8_t *)ptr;
-(BOOL)isPlistData;

-(NSDictionary*)dictionaryValue;
-(NSString*)stringValue;
-(NSArray*)arrayValue;
-(id)objectValue;
@end
