//
//  NTIHTMLWriter.h
//  NTIFoundation
//
//  Created by Christopher Utz on 10/7/11.
//  Copyright 2011 NextThought. All rights reserved.
//

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

@class NTIHTMLWriter;

@interface NSObject(NTIHTMLWriterExtensions)
-(void)htmlWriter: (NTIHTMLWriter*)writer exportHTMLToDataBuffer: (OFDataBuffer*)buffer 
		 withSize: (CGSize)size;
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
+(NSData*)htmlDataForAttributedString: (NSAttributedString*)attributedString
							wrappedIn: (NSString*)element;

@end

