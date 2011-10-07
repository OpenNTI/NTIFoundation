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
struct _state;

typedef struct {
	struct {
		unsigned int bold: 1;
		unsigned int italic: 1;
	} flags;
	void* prev;	
	int fontSize;
	int fontIndex;
	int foregroundColorIndex;
	int backgroundColorIndex;
	unsigned int underline;
	OAFontDescriptor* fontDescriptor;
	int alignment;
	int firstLineIndent;
	int leftIndent;
	int rightIndent;
	const char* closingTag;
	BOOL inBlock;
} state_t;

@interface NSAttributedString(HTMLWritingExtensions)
-(NSData*)htmlDataFromString;
-(NSData*)htmlDataFromStringWrappedIn: (NSString*)element;
-(NSString*)htmlStringFromString;
-(NSString*)htmlStringFromStringWrappedIn: (NSString*)element;
@end

@interface NSObject(NTIHTMLWriterExtensions)
//TODO: This should be getting a sender argument.
-(void)exportHTMLToDataBuffer: (OFDataBuffer*)buffer withSize: (CGSize)size;
@end

@interface NTIHTMLWriter : OFObject
{
@private
	NSAttributedString* attributedString;
	NSMutableDictionary* registeredColors;
	NSMutableDictionary* registeredFonts;
	OFDataBuffer* dataBuffer;
	
	state_t* state;
}

+(NSData*)htmlDataForAttributedString: (NSAttributedString*)attributedString;

@end
