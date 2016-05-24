//
//  NTIHTMLReader.m
//  NTIFoundation
//
//  Created by Christopher Utz on 10/7/11.
//  Copyright 2011 NextThought. All rights reserved.
//
#import "NTIHTMLReader.h"
#import "NTITextAttachment.h"
#import "NSMutableArray-NTIExtensions.h"


#import <OmniBase/OmniBase.h>
#import <OmniFoundation/NSMutableAttributedString-OFExtensions.h>

#import <QuartzCore/QuartzCore.h>
#import <OmniFoundation/OmniFoundation.h>
#import <OmniAppKit/OATextAttachment.h>
#import <OmniAppKit/OATextStorage.h>
#import <OmniAppKit/OATextAttributes.h>
#import <OmniAppKit/OAFontDescriptor.h>
#import <OmniAppKit/OAParagraphStyle.h>
#import <CoreText/CTParagraphStyle.h>
#import <CoreText/CTStringAttributes.h>
#import <ImageIO/CGImageSource.h>
#import <Foundation/NSXMLParser.h>

#import <OmniAppKit/OAColor.h>
#import "OAColor-NTIExtensions.h"

static Class readerClass = nil;

@implementation NTIHTMLReader

+(void)registerReaderClass: (Class)c
{
	readerClass = c;
}

+(Class)readerClass
{
	if(!readerClass){
		return [NTIHTMLReader class];
	}
	return readerClass;
}

+(NSString*)defaultFontFamily
{
	return @"Open Sans";
}

+(CGFloat)defaultFontSize
{
	return 14.0f;
}

static void commonInit( NTIHTMLReader* self )
{
	self->inError = NO;
	self->unparsableFormat = NO;
	self->attrBuffer = [[NSMutableAttributedString alloc] init];
	self->nsattrStack = [[NSMutableArray alloc] initWithCapacity: 3];
	self->linkStart = NSNotFound;
}

-(id)initWithHTML: (NSString*)string
{
	self = [super init];
	commonInit( self );
	
	//Even though we're replacing &nbsp; with resolveEntity...
	//the parser still stops parsing when it sees it for unknown reasons.
	//These come in from the web app.
	string = [string stringByReplacingOccurrencesOfString: @"&nbsp;"
												  withString: @" "];
	//Tidy up some horrible non-XML stuff the browser leaves in
	string = [string stringByReplacingOccurrencesOfString: @"<br>"
												  withString: @"<br/>"];
												  
	NSXMLParser* parser = [[NSXMLParser alloc] initWithData: 
						   [string dataUsingEncoding: [string fastestEncoding]]];
	parser.delegate = self;
	[parser parse];
	if( self->inError ) {
		//OK, we often get malformed XML fragments from the web app.n
		//Is that the case here? If so, retry
		if( ![string hasPrefix: @"<html>"] ) {
			commonInit( self );
			string = [NSString stringWithFormat: @"<html>%@</html>", string];
			parser = [[NSXMLParser alloc] initWithData: 
					  [string dataUsingEncoding: [string fastestEncoding]]];
			parser.delegate = self;
			[parser parse];
		}
	}
	
	if( self->inError ) {
		//Well nuts.
		self = nil;
		
	}
	
	//If we can't parse parts of the format we almost certainly can't guess
	//some defaults if there are other format parts that did parse.  It's all or nothing
	//for us.
	if( self && self->unparsableFormat ){
		//TODO we lose any attachments here.  This includes things like inlined images.
		//Maybe we should work harder to only strip the format related attrs?
		
		NSString* plainString = [self->attrBuffer string];
		
		NSLog(@"Encountered an error parsing formatting data from html \"%@\".  "
			  "Falling back to simple plain text \"%@\".", string, plainString);
		self->attrBuffer = [[NSMutableAttributedString alloc] initWithString: plainString];
	}
	
	return self;
}

-(void)parser: (NSXMLParser*)parser parseErrorOccurred: (NSError*)error
{
	if( error.code == NSXMLParserUndeclaredEntityError ) {
		//Nothing
		NSLog( @"Ignoring undeclared entity error: %@", error );
	}
	else {
		NSLog( @"Parse error: %@", error );
		self->inError = YES;
	}
}

-(NSData*)parser: (NSXMLParser*)parser resolveExternalEntityName: (NSString*)name
		systemID: (NSString*)systemID
{
	NSString* str = @"";
	//Handle HTML entities that might show up
	if( OFISEQUAL( name, @"nbsp" ) ) {
		str = @" ";
	}
	
	return [str dataUsingEncoding: NSUTF8StringEncoding];
}

-(NSAttributedString*) attributedString
{
	return [self->attrBuffer copy];
}

static NSString* stringFromStyle( NSString* styleAttribute, NSString* name )
{
	return [[[styleAttribute substringFromIndex: [name length] + 1]
			 stringByTrimmingCharactersInSet: 
			 [NSCharacterSet whitespaceAndNewlineCharacterSet]]
			stringByTrimmingCharactersInSet:
			[NSCharacterSet characterSetWithCharactersInString: @"'\""]];
}

static OAFontDescriptor* newCurrentFontDescriptor( NSDictionary* dict, Class clazz )
{
	OAPlatformFontClass* newPlatformFont = [dict objectForKey:
									 (NSString*)kCTFontAttributeName];
	OAFontDescriptor* newFontDescriptor;
	if( newPlatformFont == nil ) {
		newFontDescriptor = [[OAFontDescriptor alloc]
							 initWithFamily: [clazz defaultFontFamily] size: [clazz defaultFontSize]];
	}
	else {
		newFontDescriptor = [[OAFontDescriptor alloc] initWithFont: newPlatformFont];
	}
	return newFontDescriptor;	
}
/**
 * @param desc A new descriptor, which will be released by this function.
 */
static void setCurrentFontDescriptor( NSMutableDictionary* dict, 
									 OAFontDescriptor* desc )
{
	[dict setObject: (id)[desc font]
			 forKey: (id)kCTFontAttributeName];
}

//Note things that call us stuff our result in a dictionary.  Make sure we don't return nil;
//Returns defaultColor on unrecognized colors.  
CGColorRef NTIHTMLReaderParseCreateColor(NSString* attribute, OAColor* defaultColor) NS_RETURNS_RETAINED;

NS_RETURNS_RETAINED CGColorRef NTIHTMLReaderParseCreateColor( NSString* attribute, OAColor* defaultColor )
{	
	OAColor* color = nil;
	if( [@"black" isEqual: attribute] ) {
		color = [OAColor blackColor];
	}
	else if( [attribute hasPrefix: @"rgb("] ) {
		//TODO could go in the QQColor-Extensions category
		//start after rgb( and end at before )
		attribute = [attribute substringWithRange: NSMakeRange( 4, [attribute length] - 4 - 1)];
		NSArray* parts = [attribute componentsSeparatedByString: @","];
		color = [OAColor colorWithRed: [[parts firstObject] floatValue] / 255.0f
								green: [[parts secondObject] floatValue] / 255.0f
								 blue: [[parts lastObject] floatValue] / 255.0f
								alpha: 1];
	}
	else if( [attribute hasPrefix: @"#"] && [attribute length] == 7 ) {
		//TODO could go in the QQColor-Extensions category
		//Hex encoding
		NSString* r = [attribute substringWithRange: NSMakeRange( 1, 2 )];
		NSString* g = [attribute substringWithRange: NSMakeRange( 3, 2 )];
		NSString* b = [attribute substringWithRange: NSMakeRange( 5, 2 )];
		color = [OAColor colorWithRed: [r hexValue] / 255.0f
								green: [g hexValue] / 255.0f
								 blue: [b hexValue] / 255.0f
								alpha: 1];
	}
	
	//If we got something we can't parse as a color return the default.
	if(!color){
		NSLog(@"Unable to parse color attribute \"%@\".  Returning default color %@", attribute, defaultColor);
		color = defaultColor;
	}
	
	return [color rgbaCGColorRef];
}

static NSMutableParagraphStyle* currentParagraphStyle( NSDictionary* dict )
{
	NSParagraphStyle* result = [dict objectForKey: (id)kCTParagraphStyleAttributeName];
	if( !result ) {
		result = [NSParagraphStyle defaultParagraphStyle];
	}
	return [result mutableCopy];
}

static void setCurrentParagraphStyle( NSMutableDictionary* dict, NSMutableParagraphStyle* style )
{
	[dict setObject: style forKey: NSParagraphStyleAttributeName];

}

-(NSMutableDictionary*)mutableDictionaryWithCurrentStyle
{
	NSMutableDictionary* dict = nil;
	NSDictionary* current = [self->nsattrStack lastNonNullObject];
	if( OFNOTNULL( current ) ) {
		dict = [NSMutableDictionary dictionaryWithDictionary: current];
	}
	else {
		dict = [NSMutableDictionary dictionaryWithCapacity: 1];
	}
	return dict;
}

//Sets the value in the dictionary using the specified key.  If val is nil the dictionary is not
//changed and the unparsableFormatFlag is set.
-(void)safelyParseAndSetColorAttrInAttrs: (NSMutableDictionary*)attrs attrKey: (id)key colorString: (NSString*)color
{
	CGColorRef colorObject = NTIHTMLReaderParseCreateColor(color, nil);
	if(colorObject == nil){
		self->unparsableFormat = YES;
	}
	else{
		[attrs setObject: [UIColor colorWithCGColor: colorObject] forKey: key];
	}
	CGColorRelease(colorObject);
}

-(NSDictionary*)coreTextAttrsForFontAttrs: (NSDictionary*)fontAttrs
{
	if( !fontAttrs || ![fontAttrs count] ) {
		return nil;
	}
	
	NSMutableDictionary* dict = [self mutableDictionaryWithCurrentStyle];
	
	for( id styleName in fontAttrs ) {
		id styleValue = [fontAttrs objectForKey: styleName];
		if( OFISEQUAL( styleName,  @"color") ) {
			[self safelyParseAndSetColorAttrInAttrs: dict
											attrKey: (id)NSForegroundColorAttributeName
										colorString: styleValue];
		}
	}
	return dict;
}

#define HAS_VALUE(prefix) if( [styleAttribute hasPrefix: @prefix] ) { \
styleAttribute = stringFromStyle( styleAttribute, @prefix );
#define EHV }

-(NSDictionary*)coreTextAttrsForStyle: (NSString*)style
{
	NSArray* styleAttributes = [style componentsSeparatedByString: @";"];
	if( [NSArray isEmptyArray: styleAttributes] ) {
		return nil;
	}
	
	NSMutableDictionary* dict = [self mutableDictionaryWithCurrentStyle];
	
	for( __strong id styleAttribute in styleAttributes ) {
		styleAttribute = [styleAttribute stringByTrimmingCharactersInSet:
						  [NSCharacterSet whitespaceAndNewlineCharacterSet]];	
		//TODO: Data driven.
		//Fonts 
		HAS_VALUE("font-family") {
			setCurrentFontDescriptor(
									 dict,
									 [newCurrentFontDescriptor( dict , [self class])
									  newFontDescriptorWithFamily: @"Open Sans"] );
		} EHV
		else HAS_VALUE("font-size") {
			setCurrentFontDescriptor( 
									 dict,
									 [newCurrentFontDescriptor( dict , [self class])
									  newFontDescriptorWithSize: [styleAttribute intValue]] );
			
		} EHV
		else HAS_VALUE("font-weight") {
			setCurrentFontDescriptor( 
									 dict,
									 [newCurrentFontDescriptor( dict , [self class])
									  newFontDescriptorWithBold: [styleAttribute isEqual: @"bold"]] );
		} EHV
		else HAS_VALUE("font-style") {
			setCurrentFontDescriptor( 
									 dict,
									 [newCurrentFontDescriptor( dict , [self class])
									  newFontDescriptorWithItalic: [styleAttribute isEqual: @"italic"]] );
			
		} EHV
		else HAS_VALUE("text-decoration") {
			NSUnderlineStyle value = NSUnderlineStyleNone;
			if( [styleAttribute isEqual: @"underline"] ) {
				value = NSUnderlineStyleSingle;
			}
			[dict setUnsignedIntValue: value
							   forKey: (id)NSUnderlineStyleAttributeName];
		} EHV
		//Colors
		else HAS_VALUE("color") {
			//Theres not really a known safe default.  Imagine the case where this fails to parse so we
			//default it to white, but the background does parse to white.  If we can't parse
			//any format data all we can be sure about is dropping all of it.
			[self safelyParseAndSetColorAttrInAttrs: dict 
											attrKey: NSForegroundColorAttributeName
										colorString: styleAttribute];
		} EHV
		else HAS_VALUE("background-color") {
			//See comment above
			[self safelyParseAndSetColorAttrInAttrs: dict 
											attrKey: (id)NSBackgroundColorAttributeName 
										colorString: styleAttribute];
		} EHV
		//Paragraph style
		else HAS_VALUE("text-align") {
			NSTextAlignment align = NSTextAlignmentNatural;
			if( [styleAttribute isEqual: @"left"] ) {
				align = NSTextAlignmentLeft;
			}
			else if( [styleAttribute isEqual: @"right"] ) {
				align = NSTextAlignmentRight;
			}
			else if( [styleAttribute isEqual: @"justify"] ) {
				align = NSTextAlignmentJustified;
			}
			else if( [styleAttribute isEqual: @"center"] ) {
				align = NSTextAlignmentCenter;
			}
			NSMutableParagraphStyle* s = currentParagraphStyle( dict );
			[s setAlignment: align];
			setCurrentParagraphStyle( dict, s );
		} EHV
		//There may be some math on the margins that's not quite right.
		else HAS_VALUE("margin-left") {
			NSInteger leftpts = [styleAttribute intValue];
			NSMutableParagraphStyle* s = currentParagraphStyle( dict );
			[s setHeadIndent: leftpts];
			setCurrentParagraphStyle( dict, s );
		} EHV
		else HAS_VALUE("margin-right") {
			NSInteger rightpts = [styleAttribute intValue];
			//HTML uses inset from right, CoreText uses either left or right,
			//with negative meaning right
			rightpts = -rightpts;
			NSMutableParagraphStyle* s = currentParagraphStyle( dict );
			[s setTailIndent: rightpts];
			setCurrentParagraphStyle( dict, s );
		} EHV
		
	}
	return dict;
}

#undef HAS_VALUE
#undef EHV

-(CGImageRef)newImageFromURL: (NSString*)url
{
	//Seriously cheating here
	NSString* dataPfx1 = @"data:image/png;base64,";
	NSString *dataPfx2 = @"data:<;base64,";
	NSData* imgData = nil;
	if( [url hasPrefix: dataPfx1] ) {
		imgData = [NSData dataWithBase64String: [url substringFromIndex: dataPfx1.length]];
	}
	else if ([url hasPrefix: dataPfx2]) {
		imgData = [NSData dataWithBase64String: [url substringFromIndex:dataPfx2.length]];
	}
	else {
		//FIXME we are running on the main thread here.  THis may block
		OBASSERT(![NSThread isMainThread]);
		imgData = [NSData dataWithContentsOfURL: [NSURL URLWithString: url]];
	}
	
	CGImageRef imageRef = nil;
	
	if( imgData ) {
		CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData( (__bridge CFDataRef)imgData );
		if( !dataProvider ) {
			OBASSERT_NOT_REACHED("Unable to create the data provider");
			goto bad;
		}
		
		CGImageSourceRef imageSource = CGImageSourceCreateWithDataProvider(dataProvider,NULL);
		CFRelease(dataProvider);
		if( !imageSource ) {
			OBASSERT_NOT_REACHED("Unable to create the image source");
			goto bad;
		}
		
		size_t imageCount = CGImageSourceGetCount(imageSource);
		if( imageCount == 0 ) {
			CFRelease( imageSource );
			OBASSERT_NOT_REACHED("No images found");
			goto bad;
		}
		
		imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL );
		CFRelease(imageSource);
	}
bad:
	return imageRef;
}

#define PUSH(coreAttrs) [self->nsattrStack push: OFNOTNULL( coreAttrs ) ? coreAttrs : [OFNull nullObject]]

- (void)parser: (NSXMLParser*)parser 
didStartElement: (NSString*)elementName 
  namespaceURI: (NSString*)namespaceURI
 qualifiedName: (NSString*)qName
	attributes: (NSDictionary*)attributeDict
{
	//Again with our assumptions. We never have any style applied just to a link.
	//Links only contain an image.
	elementName = [elementName lowercaseString];
	
	//We collect images to such than if an anchor contains an image,
	//we parse that as an image as a link. However, since img can by
	//definition have no children, anytime we hit a start tag we can stop
	//collecting/tracking the prior image.  This helps to ensure in the case
	//of horribly formed html we don't bleed images into later anchors.
	if(self->currentImage){
		CFRelease( self->currentImage );
		self->currentImage = nil;
	}
	
	if( [@"a" isEqual: elementName] ) {
		self->currentHref = [[attributeDict objectForKey: @"href"] copy];
		self->linkStart = self->attrBuffer.length;
	}
	else if( [@"img" isEqual: elementName] ) {
		NSString* src = [attributeDict objectForKey: @"src"];
		self->currentImage = [self newImageFromURL: src];
	}
	else if( [@"audio" isEqual: elementName] ){
		parsingAudio = YES;
		self->currentAudioURL = [attributeDict objectForKey: @"src"];
	}
	else if( [attributeDict objectForKey: @"style"] ) {
		//p or a span with style info
		NSDictionary* coreAttrs = [self coreTextAttrsForStyle: 
								   [attributeDict objectForKey: @"style"]];
		PUSH( coreAttrs );
	}
	else if( [@"span" isEqual: elementName] || [@"p" isEqual: elementName] ) {
		//p or span without style info
		NSMutableDictionary* coreAttrs = [self mutableDictionaryWithCurrentStyle];
		PUSH( coreAttrs );
	}
	else if( [@"i" isEqual: elementName] || [@"em" isEqual: elementName] ) {
		//push italic
		NSMutableDictionary* coreAttrs = [self mutableDictionaryWithCurrentStyle];
		setCurrentFontDescriptor( 
								 coreAttrs,
								 [newCurrentFontDescriptor( coreAttrs , [self class])
								  newFontDescriptorWithItalic: YES] );
		PUSH( coreAttrs );
	}
	else if( [@"font" isEqual: elementName] ) {
		//Yick. A nasty font tag. Thank you, web. We parse what we understand 
		//out of it and drop the rest. The main thing is to get the text.
		NSDictionary* coreAttrs = [self coreTextAttrsForFontAttrs: attributeDict];
		PUSH( coreAttrs );
	}
	else if( [@"b" isEqual: elementName] || [@"strong" isEqual: elementName] ) {
		//push bold
		NSMutableDictionary* coreAttrs = [self mutableDictionaryWithCurrentStyle];
		setCurrentFontDescriptor( 
								 coreAttrs,
								 [newCurrentFontDescriptor( coreAttrs , [self class])
								  newFontDescriptorWithBold: YES] );
		PUSH( coreAttrs );
	}
	else if( OFISEQUAL( @"u", elementName ) ) {
		//push underline
		NSMutableDictionary* coreAttrs = [self mutableDictionaryWithCurrentStyle];
		[coreAttrs setUnsignedIntValue: kCTUnderlineStyleSingle
								forKey: (id)kCTUnderlineStyleAttributeName];
		PUSH( coreAttrs );
	}
	else if( [@"tt" isEqual: elementName] || [@"code" isEqual: elementName] ) {
		//push type writer font	
		NSMutableDictionary* coreAttrs = [self mutableDictionaryWithCurrentStyle];
		setCurrentFontDescriptor( 
								 coreAttrs,
								 [newCurrentFontDescriptor( coreAttrs , [self class])
								  newFontDescriptorWithFamily: @"Courier"]);
		PUSH( coreAttrs );
	}
}
#undef PUSH

//The only attributes we apply to content we haven't seen yet is the 
//link attribute, which only has an IMG tag in it, never text content.
//So we don't have to buffer the text and save until we have more attributes.

-(void)parser: (NSXMLParser*)parser
foundCharacters: (NSString *)string
{
	if(parsingAudio){
		return;
	}
	[attrBuffer appendString: string attributes: self->nsattrStack.lastNonNullObject];	
}

-(void)parser: (NSXMLParser*)parser
didEndElement: (NSString*)elementName
 namespaceURI: (NSString*)namespaceURI
qualifiedName: (NSString*)qName
{	
	elementName = [elementName lowercaseString];
	if( [@"p" isEqual: elementName] ) {
		[attrBuffer appendString: @"\n" 
					  attributes: nil];
		[self->nsattrStack pop];
	}
#define POPIF(name) else if( [name isEqual: elementName] ) { [self->nsattrStack pop]; }
	POPIF(@"font")
	POPIF(@"span")
	POPIF(@"i")
	POPIF(@"em")
	POPIF(@"b")
	POPIF(@"u")
	POPIF(@"strong")	
	POPIF(@"tt")	
	POPIF(@"code")		
#undef POPIF
	else if( [@"br" isEqual: elementName] ) {
		[attrBuffer appendString: @"\n"
					  attributes: nil];
	}
	//Besides A, the only other tage we're expecting is IMG.
	//It won't have style on it, and neither will an enclosing HTML
	//or BODY, if present, so our stack stays in sync.
	else if(	[@"a" isEqual: elementName] 
	   		&&	self->currentHref ) {
		if(self->currentImage){
			[self handleAnchorTag: self->attrBuffer
					  currentHref: self->currentHref
					 currentImage: self->currentImage];
		}
		else{
			OBASSERT(self->linkStart != NSNotFound);
			NSRange r = NSMakeRange(self->linkStart, self->attrBuffer.length - self->linkStart);
			self->linkStart = NSNotFound;
			
			// Allow all legal characters until we find some we do want to escape
			NSCharacterSet *linkCharacterSet = [[NSCharacterSet illegalCharacterSet] invertedSet];
			
			NSURL* url = [NSURL URLWithString: [self->currentHref stringByAddingPercentEncodingWithAllowedCharacters: linkCharacterSet]];
			if(url){
				[self->attrBuffer addAttributes: @{NSLinkAttributeName: url} range: r];
			}
		}
	}
	else if ([@"img" isEqualToString: elementName]) {
		[self handleImageTag: self->attrBuffer
				currentImage: self->currentImage];
	}
	else if( [@"audio" isEqual: elementName] ){
		self->parsingAudio = NO;
		[self handleAudioTag: self->attrBuffer
				currentAudio: self->currentAudioURL];
		
	}
	
}

-(void)handleAnchorTag: (NSMutableAttributedString*)attrBuffer
		   currentHref: (NSString*)currentHref 
		  currentImage: (CGImageRef) currentImage
{
	
}

- (void)handleImageTag: (NSMutableAttributedString *)attrBuffer
		  currentImage: (CGImageRef)image
{
	
}

-(void)handleAudioTag: (NSMutableAttributedString*)attrBuffer
		 currentAudio: (NSString*)currentHref
{
	
}

- (void)dealloc
{
	if(self->currentImage){
		CFRelease( self->currentImage );
	}
}

@end
