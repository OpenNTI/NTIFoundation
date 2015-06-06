//
//  NSURL-NTIExtensionsTest.m
//  NTIFoundation
//
//  Created by  on 5/31/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NSURL-NTIExtensionsTest.h"
#import "NSURL-NTIExtensions.h"

#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>

@implementation NSURL_NTIExtensionsTest

-(void)testsettingFragmentOnUrl
{
	NSURL* url = [NSURL URLWithString:@"http://example.com/dataserver/user/pages/tag:nextthought.com,2011:AOPS-HTML-Prealgebra.0."];
	NSString* fragment = @"hint1";
	NSURL* newUrl = [url urlWithFragment: fragment];
	
	assertThat([url fragment], nilValue());	//No fragment initially;
	assertThat([newUrl fragment], is(fragment));
	NSString* expectedString = [NSString stringWithFormat:@"%@#%@", url.absoluteString, fragment];
	assertThat([newUrl absoluteString], is(expectedString));
}

-(void)testReplacingExistingUrlFragment
{
	NSURL* url = [NSURL URLWithString:@"http://example.com/dataserver/user/pages/tag:nextthought.com,2011:AOPS-HTML-Prealgebra.0.#Challenge1"];
	NSString* fragment = @"hint1";
	NSURL* newUrl = [url urlWithFragment: fragment];
	
	assertThat([url fragment], is(@"Challenge1"));	//No fragment initially;
	assertThat([newUrl fragment], is(fragment));
	NSString* expectedString =@"http://example.com/dataserver/user/pages/tag:nextthought.com,2011:AOPS-HTML-Prealgebra.0.#hint1";
	assertThat([newUrl absoluteString], is(expectedString));
}

@end
