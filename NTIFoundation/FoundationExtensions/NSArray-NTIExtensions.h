//
//  NSArray-NTIExtensions.h
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/15.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OmniFoundation/NSArray-OFExtensions.h>

@interface NSArray (NTIExtensions)

@property(nonatomic,readonly) id firstObject;
@property(nonatomic,readonly) id firstObjectOrNil;
@property(nonatomic,readonly) id secondObject;
/**
 * Returns the last object, or nil if this array is empty.
 */
@property(nonatomic,readonly) id lastObjectOrNil;

/**
 * Returns the last non-null object in this array, or nil if
 * the array is empty.
 */
@property (nonatomic,readonly) id lastNonNullObject;

+(BOOL)isEmptyArray: (id)a; //Not an instance method, because nil would return NO
+(BOOL)isNotEmptyArray: (id)a;

/// \c YES iff the receiver's \c count is equal to \c 0\n.
/// @note The result of this expression should \b not be tested by explicit comparison to \c BOOL values in cases where a \c nil result should be treated as \c NO\n.
@property (nonatomic, readonly) BOOL isEmpty;

@property (nonatomic,readonly) BOOL notEmpty; //Safe as an instance method, nil returns NO
@end
