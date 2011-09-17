//
//  NTIGravatars.h
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/10.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <OmniFoundation/OmniFoundation.h>
#import <Foundation/Foundation.h>

@class UIImage;

typedef void(^NTIGravatarCallback)(UIImage*);

@interface NTIGravatars : OFObject {
	@private
	NSCache* cache;
	//We don't want to overwhelm gravatar with requests,
	//that's a good way to get us banned,
	//so we use a serial queue.
	dispatch_queue_t gravatar_q;
}

+(NTIGravatars*)gravatars;

-(void)fetchIconForEmail: (NSString*)email then: (NTIGravatarCallback)callback;
-(void)fetchIconForUser: (id)user then: (NTIGravatarCallback)callback;

@end
