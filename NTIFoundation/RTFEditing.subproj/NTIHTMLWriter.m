//
//  NTIHTMLWriter.m
//  NTIFoundation
//
//  Created by Christopher Utz on 10/7/11.
//  Copyright 2011 NextThought. All rights reserved.
//
#import "NTIHTMLWriter.h"
#import <OmniFoundation/OFDataBuffer.h>
#import <OmniFoundation/OFStringScanner.h>
#import <OmniFoundation/NSDictionary-OFExtensions.h>
#import <OmniFoundation/NSAttributedString-OFExtensions.h>
#import <OmniAppKit/OAFontDescriptor.h>
#import <OmniAppKit/OATextAttributes.h>
#import <OmniAppKit/OATextStorage.h>
#import <OmniAppKit/OATextAttachmentCell.h>
#import <OmniAppKit/OATextAttachment.h>

#if defined(TARGET_OS_IPHONE) && TARGET_OS_IPHONE
#import <CoreText/CTParagraphStyle.h>
#import <CoreText/CTStringAttributes.h>
#endif

#import <OmniFoundation/NSData-OFEncoding.h>
#import "NSAttributedString-HTMLWritingExtensions.h"

#import "OmniQuartz/OQColor.h"
#import "OQColor-NTIExtensions.h"

#ifdef DEBUG_jmadden
#define DEBUG_RTF_WRITER
#endif

@interface NTIHTMLWriter ()

@property (readwrite, strong) NSAttributedString* attributedString;

-(void)writeHTMLData: (OFDataBuffer*)dataBuffer
			  before: (const char*)before
			   after: (const char*)after;
+(NSData*)htmlDataForAttributedString: (NSAttributedString*)attributedString
							   before: (NSString*)before
								after: (NSString*)after;
@end

@interface NTIHTMLColorTableEntry : OFObject<NSCopying>
{
@private
	int red, green, blue;
}

-(id)initWithColor: (CGColorRef)color;
-(void)writeToDataBuffer: (OFDataBuffer*)dataBuffer;

@end

@implementation NTIHTMLWriter

@synthesize attributedString;

static OFCharacterSet* ReservedSet;

+ (void)initialize;
{
	OBINITIALIZE;
	
	ReservedSet = [[OFCharacterSet alloc] init];
	[ReservedSet addAllCharacters];
	//Allow the ASCII range of non-control characters
	[ReservedSet removeCharactersInRange:NSMakeRange(32, 127 - 32)]; 
	//Reserve the few ASCII characters that HTML needs us to quote
	[ReservedSet addCharactersInString:@"&<>\"'"]; 
}

#ifdef DEBUG_RTF_WRITER

+(NSString*)debugStringForColor: (void*)color;
{
	if( color == NULL ) {
		return @"(null)";
	}
	
	const CGFloat* rgbComponents = CGColorGetComponents(color);
	OBASSERT(CGColorGetNumberOfComponents(color) == 4); // Otherwise the format statement below is wrong
	return [NSString stringWithFormat:@"%@ (components=%u, r=%3.2f g=%3.2f b=%3.2f a=%3.2f)", color,
			CGColorGetNumberOfComponents(color),
			rgbComponents[0],
			rgbComponents[1],
			rgbComponents[2],
			rgbComponents[3]];
}

#endif

static CFDataRef CFDataCreateFromOFDataBuffer( OFDataBuffer dataBuffer )
{
	CFDataRef data = NULL;
	OFDataBufferRelease(&dataBuffer, kCFAllocatorDefault, (CFDataRef*)&data);
	return data;
}
												

+(NSData*)htmlDataForAttributedString: (NSAttributedString*)attributedString
							   before: (NSString*)before
								after: (NSString*)after
{
	NTIHTMLWriter* rtfWriter = [[self alloc] init];
	rtfWriter.attributedString = attributedString;
		
	OFDataBuffer dataBuffer;
	OFDataBufferInit(&dataBuffer);
		
	[rtfWriter writeHTMLData: &dataBuffer
					  before: [before UTF8String]
					   after: [after UTF8String]];
	id result = (__bridge_transfer id)CFDataCreateFromOFDataBuffer( dataBuffer );
	
	return result;
}

+(NSData*)htmlDataForAttributedString: (NSAttributedString*)attributedString
{
	return [self htmlDataForAttributedString: attributedString
									  before: @"<html><body>"
									   after: @"</body></html>"];
}

+(NSData*)htmlDataForAttributedString: (NSAttributedString*)attributedString
							wrappedIn: (NSString*)element
{
	return [self htmlDataForAttributedString: attributedString
									  before: [NSString stringWithFormat: @"<%@>", element]
									   after: [NSString stringWithFormat: @"</%@>", element]];
}


-(void)clearState
{
	memset( self->state, 0, sizeof( state_t ) );
	self->state->fontSize = -1;
	self->state->fontIndex = -1;
	self->state->foregroundColorIndex = -1;
	self->state->backgroundColorIndex = 0;
	self->state->underline = kCTUnderlineStyleNone;	
}

-(void)pushCopyOfState
{
	state_t* newState = NSZoneCalloc( NSZoneFromPointer( (__bridge void *)(self) ), 1, sizeof(state_t) );
	NSCopyMemoryPages( self->state, newState, sizeof( state_t ) );
	state_t* prev = self->state;
	newState->prev = prev;
	self->state = newState;
}

-(void)popState
{
	state_t* curr = self->state;
	self->state = curr->prev;
	NSZoneFree( NSZoneFromPointer( curr ), curr );
}

-(id)init;
{
	if( !(self = [super init]) ) {
		return nil;
	}
	
	return self;
}

-(void)dealloc;
{
	OBPRECONDITION(self->dataBuffer == NULL); // Only set for the duration of -_writeRTFData:
	
	
}

static inline void writeCharacter(OFDataBuffer* dataBuffer, unichar aCharacter)
{
	if( !OFCharacterSetHasMember( ReservedSet, aCharacter ) ) {
		OBASSERT(aCharacter < 128); 
		//Or it should have been in the reserved set: it can't be
		//written in a single byte as we're about to do
		OFDataBufferAppendByte(dataBuffer, aCharacter);
	}
	else if( aCharacter == NSAttachmentCharacter ) {
		//An attachment. The only attachments we support are image attachments
		//which are part of a link, so this does nothing.
		do {} while(0);
	}
	else {
		//Write reserved  character
		OFDataBufferAppendCString( dataBuffer, "&#" );
		OFDataBufferAppendInteger(dataBuffer, aCharacter);
		OFDataBufferAppendCString( dataBuffer, ";" );
	}
}

static inline void writeString(OFDataBuffer* dataBuffer, NSString* string)
{
	NSUInteger characterCount = [string length];
	unichar* characters = malloc(characterCount*  sizeof(unichar));
	[string getCharacters:characters];
	for( NSUInteger characterIndex = 0; characterIndex < characterCount; characterIndex++ ) {
		writeCharacter(dataBuffer, characters[characterIndex]);
	}
	free(characters);
}

static const struct {
	const char* name;
	unsigned int ctValue;
} underlineStyleKeywords[] = {
	{ "uld", kCTUnderlineStyleSingle|kCTUnderlinePatternDot },
	{ "uldash", kCTUnderlineStyleSingle|kCTUnderlinePatternDash },
	{ "uldashd", kCTUnderlineStyleSingle|kCTUnderlinePatternDashDot },
	{ "uldashdd", kCTUnderlineStyleSingle|kCTUnderlinePatternDashDotDot },
	{ "uldb", kCTUnderlineStyleDouble },
	{ "ulth", kCTUnderlineStyleThick },
	{ "ulthd", kCTUnderlineStyleThick|kCTUnderlinePatternDot },
	{ "ulthdash", kCTUnderlineStyleThick|kCTUnderlinePatternDash },
	{ "ulthdashd", kCTUnderlineStyleThick|kCTUnderlinePatternDashDot },
	{ "ulthdashdd", kCTUnderlineStyleThick|kCTUnderlinePatternDashDotDot },
	{ NULL, 0 },
};

/**
 * If we open a tag, we leave the writing position inside the style attribute,
 * so it needs  a closing quote and angle bracket.
 */
-(BOOL)writeFontAttributes: (NSDictionary*)newAttributes;
{
	OAPlatformFontClass* newPlatformFont = [newAttributes objectForKey: (NSString*)kCTFontAttributeName];
	OAFontDescriptor* newFontDescriptor;
	if( newPlatformFont == nil ) {
		newFontDescriptor = [[OAFontDescriptor alloc] initWithFamily:@"Helvetica" size:12.0f];
	}
	else {
		newFontDescriptor = [[OAFontDescriptor alloc] initWithFont: newPlatformFont];
	}
	
	int newFontSize = (int)round([newFontDescriptor size]);
	NSNumber* newFontIndexValue = [self->registeredFonts objectForKey:[newFontDescriptor fontName]];
	OBASSERT(newFontIndexValue != nil);
	int newFontIndex = [newFontIndexValue intValue];
	BOOL newFontBold = [newFontDescriptor bold];
	BOOL newFontItalic = [newFontDescriptor italic];
	unsigned int newUnderline = [newAttributes unsignedIntForKey: (NSString*)kCTUnderlineStyleAttributeName 
													defaultValue: kCTUnderlineStyleNone];
	
	BOOL shouldWriteNewFontSize;
	BOOL shouldWriteNewFontInfo;
	BOOL shouldWriteNewFontBold;
	BOOL shouldWriteNewFontItalic;
	
	if( self->state->fontIndex == -1 ) {
		shouldWriteNewFontInfo = YES;
		shouldWriteNewFontSize = YES;
		shouldWriteNewFontBold = newFontBold;
		shouldWriteNewFontItalic = newFontItalic;
	}
	else {
		shouldWriteNewFontSize = newFontSize != self->state->fontSize;
		shouldWriteNewFontBold = newFontBold != self->state->flags.bold;
		shouldWriteNewFontItalic = newFontItalic != self->state->flags.italic;
		shouldWriteNewFontInfo = shouldWriteNewFontSize 
		|| shouldWriteNewFontBold
		|| shouldWriteNewFontItalic
		|| newUnderline != self->state->underline
		|| newFontIndex != self->state->fontIndex;
	}
	
	BOOL opened = shouldWriteNewFontInfo;
	if( shouldWriteNewFontInfo ) {
		self->state->fontIndex = newFontIndex;
		OFDataBufferAppendCString( self->dataBuffer, "<span style=\"");
		OFDataBufferAppendCString( self->dataBuffer,  "font-family: '");
		writeString( self->dataBuffer, [newFontDescriptor fontName]);
		OFDataBufferAppendCString( self->dataBuffer,  "'; " );
		if( shouldWriteNewFontSize ) {
			OFDataBufferAppendCString( self->dataBuffer, " font-size: ");
			OFDataBufferAppendInteger(self->dataBuffer, newFontSize);
			OFDataBufferAppendCString( self->dataBuffer,  "pt;" );
			self->state->fontSize = newFontSize;
		}
		
		if( shouldWriteNewFontBold ) {
			char* style = " font-weight: normal;";
			if( newFontBold ) {
				style = " font-weight: bold;";
			}
			OFDataBufferAppendCString( self->dataBuffer, style );
			self->state->flags.bold = newFontBold;
		}
		
		if( shouldWriteNewFontItalic ) {
			char* style = " font-style: normal;";
			if( newFontItalic ) {
				style = " font-style: italic;";
			}
			OFDataBufferAppendCString(self->dataBuffer, style );
			self->state->flags.italic = newFontItalic;
		}
		
		if( newUnderline != self->state->underline ) {
			//Core text supports a boatload of underline styles. HTML doesn't (?)
			if( (newUnderline & 0xFF) == kCTUnderlineStyleNone) {
				OFDataBufferAppendCString(self->dataBuffer, " text-decoration: none;" );
			} 
			else {
				OFDataBufferAppendCString(self->dataBuffer, " text-decoration: underline;" );
			}
			self->state->underline = newUnderline;
		}
	}
	return opened;
}

/**
 * @return Whether there is an open style element that needs closing.
 */
-(BOOL)writeColorAttributes: (NSDictionary*)newAttributes
		   tagAlreadyOpened: (BOOL)open
{
	id newColor = [newAttributes objectForKey: (NSString*)kCTForegroundColorAttributeName];
	NTIHTMLColorTableEntry* colorTableEntry = [[NTIHTMLColorTableEntry alloc] 
											   initWithColor: (__bridge CGColorRef)newColor];
	NSNumber* newColorIndexValue = [self->registeredColors objectForKey: colorTableEntry];
	
	OBASSERT(newColorIndexValue != nil);
	int newColorIndex = [newColorIndexValue intValue];
	
	if( newColorIndex != self->state->foregroundColorIndex ) {
		if( !open ) {
			OFDataBufferAppendCString( self->dataBuffer, "<span style=\"");
		}
		else {
			OFDataBufferAppendCString( self->dataBuffer,  " color: ");
		}
		open = YES;
		
		[colorTableEntry writeToDataBuffer: self->dataBuffer];
		OFDataBufferAppendCString( self->dataBuffer, ";" );
		self->state->foregroundColorIndex = newColorIndex;
	}
	
	newColor = [newAttributes objectForKey: NSBackgroundColorAttributeName];
	colorTableEntry = [[NTIHTMLColorTableEntry alloc] initWithColor: (__bridge CGColorRef)newColor];
	newColorIndexValue = [self->registeredColors objectForKey: colorTableEntry];
	OBASSERT(newColorIndexValue != nil);
	newColorIndex = [newColorIndexValue intValue];
	
	if( newColorIndex != self->state->backgroundColorIndex ) {
		if( !open ) {
			OFDataBufferAppendCString( self->dataBuffer, "<span style=\" ");
			open = YES;
		}
		
		
		OFDataBufferAppendCString(self->dataBuffer, " background-color: ");
		[colorTableEntry writeToDataBuffer: self->dataBuffer];
		self->state->backgroundColorIndex = newColorIndex;
	}
	
	return open;
}

-(void)writeParagraphAttributes: (NSDictionary*)newAttributes;
{
	CTParagraphStyleRef paragraphStyle = (__bridge CTParagraphStyleRef)[newAttributes objectForKey:
															   (id)kCTParagraphStyleAttributeName];
	CTTextAlignment alignment = kCTNaturalTextAlignment;
	CGFloat firstLineHeadIndent = 0.0f;
	CGFloat headIndent = 0.0f;
	CGFloat tailIndent = 0.0f;
	
	CTParagraphStyleGetValueForSpecifier(
										 paragraphStyle,
										 kCTParagraphStyleSpecifierAlignment, 
										 sizeof(alignment),
										 &alignment);
	CTParagraphStyleGetValueForSpecifier(
										 paragraphStyle,
										 kCTParagraphStyleSpecifierFirstLineHeadIndent,
										 sizeof(firstLineHeadIndent), 
										 &firstLineHeadIndent);
	CTParagraphStyleGetValueForSpecifier(
										 paragraphStyle,
										 kCTParagraphStyleSpecifierHeadIndent, 
										 sizeof(headIndent),
										 &headIndent);
	CTParagraphStyleGetValueForSpecifier(
										 paragraphStyle,
										 kCTParagraphStyleSpecifierTailIndent,
										 sizeof(tailIndent),
										 &tailIndent);
	
	OFDataBufferAppendCString( self->dataBuffer,  "<p style=\"");
	
	//These arrive as CoreText points. RTF wants twips (1/20 of a point).
	//In HTML, we can use points.
	int leftIndent = (int)headIndent;
	int firstLineIndent = ((int)(firstLineHeadIndent)) - leftIndent;
	//The tail indent can be relative to either margin.
	int rightIndent = 0;
	if( tailIndent < 0 ) {
		//Distance from trailing margin.
		rightIndent = -tailIndent;
	}
	else if( tailIndent > 0 ) {
		//Distance from leading margin.
		//FIXME: What? I guess we're compensating for the suspected width?
		rightIndent = 8640 - tailIndent;	
	}
	
	if( alignment != self->state->alignment) {
		char* textAlign = NULL;
		switch (alignment) {
			default:
			case kCTNaturalTextAlignment:
			case kCTLeftTextAlignment:
				textAlign = " text-align: left;";
				break;
			case kCTRightTextAlignment:
				textAlign = " text-align: right;";
				break;
			case kCTCenterTextAlignment:
				textAlign = " text-align: center;";
				break;
			case kCTJustifiedTextAlignment:
				textAlign = " text-align: justify;";
				break;
		}
		OFDataBufferAppendCString( self->dataBuffer, textAlign );
		self->state->alignment = alignment;
	}
	if( firstLineIndent != self->state->firstLineIndent) {
		//FIXME: How can we write the first-line pseudo selector?
		/*
		 OFDataBufferAppendCString(self->dataBuffer, "\\fi");
		 OFDataBufferAppendInteger(self->dataBuffer, firstLineIndent);
		 */
		self->state->firstLineIndent = firstLineIndent;
	}
	if( leftIndent != self->state->leftIndent ) {
		OFDataBufferAppendCString( self->dataBuffer, " margin-left: ");		
		OFDataBufferAppendInteger(self->dataBuffer, leftIndent);
		OFDataBufferAppendCString( self->dataBuffer,  "pt;" );
		self->state->leftIndent = leftIndent;
	}
	if( rightIndent != self->state->rightIndent ) {
		OFDataBufferAppendCString( self->dataBuffer, " margin-right: ");		
		OFDataBufferAppendInteger(self->dataBuffer, rightIndent);
		OFDataBufferAppendCString( self->dataBuffer,  "pt;" );
		self->state->rightIndent = rightIndent;
	}
	
	OFDataBufferAppendCString( self->dataBuffer,  "\" >");
	
}

-(BOOL)writeLinkAttributes: (NSDictionary*)newAttributes
{
	id linkValue = [newAttributes objectForKey: NSLinkAttributeName];
	NSString* href = nil;
	if( [linkValue isKindOfClass: [NSString class]] ) {
		href = linkValue;
	}
	else if( [linkValue respondsToSelector: @selector(absoluteString)] ) {
		href = [linkValue absoluteString];
	}
	//We assume that we cannot nest links and therefore if we get 
	//an href while we're already in an href, it's the same.
	//We also assume that we cannot change the formatting of a link midway through
	if( !href || strncmp(self->state->closingTag, "</a>", 4) == 0) {
		return NO;
	}
	
	[self pushCopyOfState];
	self->state->inBlock = NO;
	self->state->closingTag = "</a>";
	OFDataBufferAppendCString( self->dataBuffer, "<a href=\"" );
	writeString( self->dataBuffer, href );
	OFDataBufferAppendCString( self->dataBuffer, "\">");
	
	//Is there an image attachment? If so, encode it here
	id attachment = [newAttributes objectForKey: NSAttachmentAttributeName];
	if(		[attachment respondsToSelector: @selector(attachmentCell)]
	   &&	[(id)[attachment attachmentCell] respondsToSelector: @selector(htmlWriter:exportHTMLToDataBuffer:withSize:)] ) {
		OATextAttachmentCell* cell = [attachment attachmentCell];
		[(id)cell htmlWriter: self exportHTMLToDataBuffer: self->dataBuffer withSize: cell.cellSize];
	}
	
	
	return YES;
}

-(void)writeAttributes: (NSDictionary*)newAttributes 
  beginningOfParagraph: (BOOL)beginningOfParagraph;
{
	@autoreleasepool {
		//Close the outstanding tags, if any, out to the block level
		//Only if we're a new paragraph do we close that too.
		while( self->state && self->state->prev ) {
			if( !self->state->inBlock ) {
				OFDataBufferAppendCString( self->dataBuffer, self->state->closingTag );
				[self popState];
			}
			else if( beginningOfParagraph ) {
				OFDataBufferAppendCString( self->dataBuffer, "</p>");
				[self popState];
				//We don't nest so we should be back to base state.
				OBASSERT( self->state->prev == NULL );
				break;
			}
			else if( self->state->inBlock ) {
				break;	
			}
		}
		if( beginningOfParagraph ) {
			[self pushCopyOfState];
			[self writeParagraphAttributes: newAttributes];
			self->state->inBlock = YES;
		}
		[self pushCopyOfState];
		BOOL openFontTag = [self writeFontAttributes: newAttributes];
		BOOL openColorTag = [self writeColorAttributes: newAttributes
									  tagAlreadyOpened: openFontTag];
		if( openColorTag || openFontTag ) {
			self->state->inBlock = NO;
			self->state->closingTag = "</span>";
			OFDataBufferAppendCString( self->dataBuffer, "\">");
		}
		else {
			//Nobody changed anything, we're stil in a block.
			[self popState];
		}
		
		//The link manages its own anchor tag
		[self writeLinkAttributes: newAttributes];
	}
}


-(void)buildColorTable;
{
	self->registeredColors = [[NSMutableDictionary alloc] init];
	
	int colorIndex = 0;
	
	OQColor* blackColor = [OQColor blackColor];
	CGColorRef blackCGColor = [blackColor rgbaCGColorRef];
	NTIHTMLColorTableEntry* defaultColorEntry = [[NTIHTMLColorTableEntry alloc] 
												 initWithColor: blackCGColor];
	if(blackCGColor){
		CFRelease( blackCGColor );
	}
	[self->registeredColors setObject: [NSNumber numberWithInt: colorIndex++]
							   forKey: defaultColorEntry];
	
	NSUInteger stringLength = [self->attributedString length];
	NSSet* textColors = [self->attributedString 
						 valuesOfAttribute: (NSString*)kCTForegroundColorAttributeName
						 inRange: NSMakeRange( 0, stringLength )];
	textColors = [textColors setByAddingObjectsFromSet:
				  [self->attributedString valuesOfAttribute: NSBackgroundColorAttributeName
													inRange: NSMakeRange( 0, stringLength)]];
	for( id color in textColors ) {
		if( !color || [color isNull] ) {
			continue;
		}
		CGColorRef cgColor = (__bridge CGColorRef)color;
		NTIHTMLColorTableEntry* colorTableEntry = [[NTIHTMLColorTableEntry alloc] 
												   initWithColor: cgColor];
		if( OFNOTNULL(colorTableEntry) && ![self->registeredColors objectForKey: colorTableEntry] ) {
			[self->registeredColors setObject: [NSNumber numberWithInt: colorIndex++]
									   forKey: colorTableEntry];
		}
	}
}

/*
 -(void)_writeFontTableEntryWithIndex: (int)fontIndex name: (NSString*)name;
 {
 OFDataBufferAppendCString(self->dataBuffer, "\\f");
 OFDataBufferAppendInteger(self->dataBuffer, fontIndex);
 OFDataBufferAppendCString(self->dataBuffer, "\\fnil\\fcharset0 ");
 writeString(self->dataBuffer, name);
 OFDataBufferAppendByte(self->dataBuffer, ';');
 }
 */

-(void)buildFontTable;
{
	self->registeredFonts = [[NSMutableDictionary alloc] init];
	int fontIndex = 0;
	
	NSRange effectiveRange;
	NSUInteger stringLength = [self->attributedString length];
	for( NSUInteger textIndex = 0; textIndex < stringLength; textIndex = NSMaxRange(effectiveRange)) {
		OAPlatformFontClass* platformFont = [self->attributedString
										 attribute: (NSString*)kCTFontAttributeName
										 atIndex: textIndex
										 effectiveRange: &effectiveRange];
		NSString* fontName;
		if( platformFont != nil ) {
			OAFontDescriptor* fontDescriptor = [[OAFontDescriptor alloc] initWithFont: platformFont];
			fontName = [fontDescriptor fontName];
		} 
		else {
			fontName = @"Helvetica";
		}
		if( ![self->registeredFonts objectForKey: fontName] ) {
#ifdef DEBUG_RTF_WRITER
			NSLog(@"Registering font %d: %@", fontIndex, fontName);
#endif
			[self->registeredFonts setObject: [NSNumber numberWithInt:fontIndex++]
									  forKey: fontName];
		}
	}
}

-(void)writeHTMLData: (OFDataBuffer*)buffer
			  before: (const char*)before
			   after: (const char*)after
{
	OBPRECONDITION(self->dataBuffer == NULL);
	
	self->dataBuffer = buffer;
	self->state = NSZoneCalloc( NSZoneFromPointer( (__bridge void *)(self)), 1, sizeof(state_t) );
	[self clearState];
	OFDataBufferAppendCString(self->dataBuffer, before );
	
	[self buildFontTable];
	[self buildColorTable];
	
	NSString* string = [self->attributedString string];
	OFStringScanner* scanner = [[OFStringScanner alloc] initWithString:string];
	NSRange stringRange = NSMakeRange(0, [string length]);
	NSUInteger scanLocation = 0;
	NSRange currentAttributesRange = NSMakeRange(0, 0);
	NSDictionary* currentAttributes = nil;
	BOOL beginningOfParagraph = YES;
	while( scannerHasData(scanner) ) {
		// Optimization: we increment our scanLocation each time we skip peeked characters
		OBASSERT(scanLocation == scannerScanLocation(scanner)); 
		
		//FIXME: Attributes could change in the middle of a paragraph
		//but still be expected to persist into the next paragraph, so 
		//we need to be accumulating values and apply them all to the next
		//paragraph (right?)
		
		//A simplification is that nothing nests. Each run of text will 
		//get its own attributes, and then a reset of them for the
		//previous values.
		if( scanLocation >= NSMaxRange(currentAttributesRange) ) {
			NSRange newAttributesRange;
			currentAttributes = [self->attributedString 
								 attributesAtIndex: scanLocation
								 longestEffectiveRange: &newAttributesRange
								 inRange: stringRange];
			currentAttributesRange = newAttributesRange;
			[self writeAttributes: currentAttributes
			 beginningOfParagraph: beginningOfParagraph];
			
		}
		else if( beginningOfParagraph ) {
			//Attributes didn't change, but we still
			//need to start a new paragraph.
			[self writeAttributes: currentAttributes
			 beginningOfParagraph: beginningOfParagraph];
		}
		
		unichar nextCharacter = scannerPeekCharacter(scanner);
		beginningOfParagraph = (nextCharacter == '\n');
		if( !beginningOfParagraph ) {
			writeCharacter(self->dataBuffer, nextCharacter);
		}
		scannerSkipPeekedCharacter(scanner);
		scanLocation++;
	}
	
	//Close the outstanding tags, if any.
	while( self->state && self->state->prev ) {
		if( !self->state->inBlock ) {
			OFDataBufferAppendCString( self->dataBuffer, self->state->closingTag);
		}
		else {
			OFDataBufferAppendCString( self->dataBuffer, "</p>");
		}
		[self popState];
	}
	OFDataBufferAppendCString(self->dataBuffer, after );
	NSZoneFree( NSZoneFromPointer( self->state ),  self->state );
	self->state = NULL;
	self->dataBuffer = NULL;
}

@end

@implementation NTIHTMLColorTableEntry

-(id)initWithColor: (CGColorRef)cgColor;
{
	if( !(self = [super init]) ) {
		return nil;
	}
	
	if( !cgColor ) {
		return self;
	}
	
	//OBASSERT(CFGetTypeID(cgColor) == CGColorGetTypeID());
	if(CFGetTypeID(cgColor) != CGColorGetTypeID()){
		return nil;
	}
	
	CGColorSpaceRef colorSpace = CGColorGetColorSpace(cgColor);
	const CGFloat* components = CGColorGetComponents(cgColor);
	switch (CGColorSpaceGetModel(colorSpace)) {
		case kCGColorSpaceModelMonochrome: {
			OBASSERT(CGColorSpaceGetNumberOfComponents(colorSpace) == 1);
			OBASSERT(CGColorGetNumberOfComponents(cgColor) == 2);
			red = green = blue = (int)round(components[0] *  255.0f);
			break;
		}
		case kCGColorSpaceModelRGB: {
			OBASSERT(CGColorSpaceGetNumberOfComponents(colorSpace) == 3);
			OBASSERT(CGColorGetNumberOfComponents(cgColor) == 4);
			red = (int)round(components[0] *  255.0f);
			green = (int)round(components[1] *  255.0);
			blue = (int)round(components[2] *  255.0);
			break;
		}
		default: {
			NSLog(@"Unsupported color space colorSpace %@", colorSpace);
			OBFinishPorting;
		}
	}
	return self;
}

-(void)writeToDataBuffer: (OFDataBuffer*)dataBuffer;
{
	if( self->red != 0 || green != 0 || blue != 0 ) {
		OFDataBufferAppendCString(dataBuffer, "rgb(");
		OFDataBufferAppendInteger(dataBuffer, red);
		OFDataBufferAppendCString(dataBuffer, ", ");
		OFDataBufferAppendInteger(dataBuffer, green);
		OFDataBufferAppendCString(dataBuffer, ", ");
		OFDataBufferAppendInteger(dataBuffer, blue);
		OFDataBufferAppendCString(dataBuffer, ")");
	}
	else {
		//If all the components were zero, then we're black
		//At least in RGB and monochrome spaces...
		OFDataBufferAppendCString( dataBuffer, "black" );
	}
}

#pragma mark -
#pragma mark NSObject protocol

-(BOOL)isEqual: (id)object;
{
	NTIHTMLColorTableEntry* otherEntry = object;
	if( object_getClass(otherEntry) != object_getClass(self) ) {
		return NO;
	}
	return otherEntry->red == self->red
	&& otherEntry->green == self->green
	&& otherEntry->blue == self->blue;
}

-(NSUInteger)hash;
{
	return (red << 16) | (green << 8) | blue;
}

-(id)copyWithZone: (NSZone*)zone;
{
	// We are immutable!
	return self;
}

@end
