//
//  NTIUserCache.h
//  NextThoughtApp
//
//  Created by Jason Madden on 2011/09/06.
//  Copyright (c) 2011 NextThought. All rights reserved.
//

#import "OmniFoundation/OmniFoundation.h"
#import "NTIUserData.h"

/**
 * Manages a cache of NTIUser objects, keyed off of their username. Use this
 * anytime you need to get a gravar or prefered display name.
 */
@interface NTIUserCache : OFObject {
	@private
	NSCache* cache;
}

+(NTIUserCache*)cache;

/**
 * Given something that has a username property (which includes strings)
 * resolve it to a user, if possible. Call the callback when this is done,
 * passing in the user, or nil.
 */
-(void)resolveUser: (id)user
			  then: (NTIObjectProcBlock)callback;

@end
