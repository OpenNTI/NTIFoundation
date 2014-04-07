//Originally based on code:
// Copyright 2010-2011 The Omni Group.	All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "NTIHTMLWriter.h"

@implementation NSAttributedString(HTMLWritingExtensions)
-(NSData*)newHTMLDataFromString
{
	return [[NTIHTMLWriter writerClass] htmlDataForAttributedString: self];
}

-(NSData*)newHTMLDataFromStringWrappedIn: (NSString*)element
{
	return [[NTIHTMLWriter writerClass] htmlDataForAttributedString: self
											wrappedIn: element];
}

-(NSString*)htmlStringFromString
{
	return [[NSString alloc] initWithData: [self newHTMLDataFromString]
								  encoding: NSUTF8StringEncoding];	
}

-(NSString*)htmlStringFromStringWrappedIn: (NSString*)element
{
	return [[NSString alloc] initWithData: [self newHTMLDataFromStringWrappedIn: element]
								  encoding: NSUTF8StringEncoding];	
}

@end
