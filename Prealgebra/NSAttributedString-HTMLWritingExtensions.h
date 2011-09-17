//Originally based on code:
// Copyright 2010-2011 The Omni Group. All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Id$

#import <OmniFoundation/OFObject.h>

@class NSAttributedString;
@class OAFontDescriptor;

#import <OmniFoundation/OFDataBuffer.h>


@interface NSAttributedString(HTMLWritingExtensions)
-(NSData*)htmlDataFromString;
-(NSData*)htmlDataFromStringWrappedIn: (NSString*)element;
-(NSString*)htmlStringFromString;
-(NSString*)htmlStringFromStringWrappedIn: (NSString*)element;
@end
