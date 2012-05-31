//
//  NSURL-NTIExtensions.m
//  NTIFoundation
//
//  Created by  on 5/31/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NSURL-NTIExtensions.h"

@implementation NSURL(NTIFragmentExtensions)
-(NSURL *)urlWithFragment:(NSString *)frag
{
	if (!frag) {
		return self;
	}
	NSString* urlString = self.absoluteString;
	//Strip off a fragment, if we currently have one.
	NSRange fragmentSeparator = [urlString rangeOfString: @"#" options: NSBackwardsSearch];
	if(fragmentSeparator.location != NSNotFound){
		urlString = [urlString substringToIndex: fragmentSeparator.location];
	}
	urlString = [urlString stringByAppendingFormat:@"#%@", frag];
	return [NSURL URLWithString: urlString];
}
@end
