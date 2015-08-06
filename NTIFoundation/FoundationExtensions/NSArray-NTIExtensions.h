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
/// @note This property should be used only when you can be sure that the receiver is not \c nil\n. Otherwise, use \c +isEmptyArray or negate the result of \c notEmpty\n.
@property (nonatomic, readonly) BOOL isEmpty;

@property (nonatomic,readonly) BOOL notEmpty; //Safe as an instance method, nil returns NO
@end
