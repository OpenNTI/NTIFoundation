//
//  NSNotification-NTIExtensions.h
//  NTIFoundation
//
//  Created by Christopher Utz on 9/18/13.
//  Copyright (c) 2013 NextThought. All rights reserved.
//

#import <OmniFoundation/OmniFoundation.h>

@interface NSNotification(NTIExtensions)

+(void)ntiPostNetworkActivityBegan: (id)sender;
+(void)ntiPostNetworkActivityEnded: (id)sender;

@end
