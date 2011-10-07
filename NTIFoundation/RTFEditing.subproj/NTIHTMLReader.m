//
//  NTIHTMLReader.m
//  NTIFoundation
//
//  Created by Christopher Utz on 10/7/11.
//  Copyright 2011 NextThought. All rights reserved.
//
#import "NTIHTMLReader.h"

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

static Class readerClass = nil;

@implementation NTIHTMLReader

+(void)registerReaderClass: (Class)c
{
	readerClass = [c retain];
}

+(Class)readerClass
{
	return readerClass;
}

static void commonInit( NTIHTMLReader* self )
{
	NTI_RELEASE( self->attrBuffer );
	NTI_RELEASE( self->nsattrStack );
	self->inError = NO;
	self->attrBuffer = [[NSMutableAttributedString alloc] init];
	self->nsattrStack = [[NSMutableArray alloc] initWithCapacity: 3];
}

-(id)initWithHTML: (NSString*)string
{
	self = [super init];
	commonInit( self );
	
	//Even though we're replacing &nbsp; with resolveEntity...
	//the parser still stops parsing when it sees it for unknown reasons.
	//These come in from the web app.
	string = [string stringByReplacingAllOccurrencesOfString: @"&nbsp;"
												  withString: @" "];
	
	NSXMLParser* parser = [[NSXMLParser alloc] initWithData: 
						   [string dataUsingEncoding: [string fastestEncoding]]];
	parser.delegate = self;
	[parser parse];
	[parser release];
	if( self->inError ) {
		//OK, we often get malformed XML fragments from the web app.
		//Is that the case here? If so, retry
		if( ![string hasPrefix: @"<html>"] ) {
			commonInit( self );
			string = [NSString stringWithFormat: @"<html>%@</html>", string];
			parser = [[NSXMLParser alloc] initWithData: 
					  [string dataUsingEncoding: [string fastestEncoding]]];
			parser.delegate = self;
			[parser parse];
			[parser release];
		}
	}
	
	if( self->inError ) {
		//Well nuts.
		[self release];
		self = nil;
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
	return [[self->attrBuffer copy] autorelease];
}

static NSString* stringFromStyle( NSString* styleAttribute, NSString* name )
{
	return [[[styleAttribute substringFromIndex: [name length] + 1]
			 stringByTrimmingCharactersInSet: 
			 [NSCharacterSet whitespaceAndNewlineCharacterSet]]
			stringByTrimmingCharactersInSet:
			[NSCharacterSet characterSetWithCharactersInString: @"'\""]];
}

#define HAS_VALUE(prefix) if( [styleAttribute hasPrefix: @prefix] ) { \
styleAttribute = stringFromStyle( styleAttribute, @prefix );
#define EHV }

static OAFontDescriptor* currentFontDescriptor( NSDictionary* dict )
{
	OAFontDescriptorPlatformFont newPlatformFont 
	= (OAFontDescriptorPlatformFont)[dict objectForKey: 
									 (NSString*)kCTFontAttributeName];
	OAFontDescriptor* newFontDescriptor;
	if( newPlatformFont == nil ) {
		newFontDescriptor = [[OAFontDescriptor alloc]
							 initWithFamily: @"Helvetica" size: 12.0f];
	}
	else {
		newFontDescriptor = [[OAFontDescriptor alloc] initWithFont: newPlatformFont];
	}
	return [newFontDescriptor autorelease];	
}
/**
 * @param desc A new descriptor, which will be released by this function.
 */
static void setCurrentFontDescriptor( NSMutableDictionary* dict, 
									 OAFontDescriptor* desc NS_CONSUMED )
{
	[dict setObject: (id)[desc font]
			 forKey: (id)kCTFontAttributeName];
	[desc release];
}

//Returns nil on unrecognized colors
static CGColorRef parseColor( NSString* attribute )
{
	CGColorRef color = nil;
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	if( [@"black" isEqual: attribute] ) {
		//TODO: Use OQColor constants
		CGFloat components[4] = {0, 0, 0, 1};
		color = CGColorCreate(colorSpace, components);
	}
	else if( [attribute hasPrefix: @"rgb("] ) {
		attribute = [attribute substringWithRange: NSMakeRange( 4, [attribute length] - 1 - 5)];
		NSArray* parts = [attribute componentsSeparatedByString: @","];
		CGFloat components[4] = {[[parts firstObject] floatValue] / 255.0f, 
			[[parts secondObject] floatValue] / 255.0f,
			[[parts lastObject] floatValue] / 255.0f, 1};
		color = CGColorCreate(colorSpace, components);
	}
	else if( [attribute hasPrefix: @"#"] && [attribute length] == 7 ) {
		//Hex encoding
		NSString* r = [attribute substringWithRange: NSMakeRange( 1, 2 )];
		NSString* g = [attribute substringWithRange: NSMakeRange( 3, 2 )];
		NSString* b = [attribute substringWithRange: NSMakeRange( 5, 2 )];
		
		CGFloat components[4] = {[r hexValue] / 255.0f, 
			[g hexValue] / 255.0f,
			[b hexValue] / 255.0f, 1};
		color = CGColorCreate(colorSpace, components);
	}
	
	CGColorSpaceRelease(colorSpace);
	return color;
}

static OAMutableParagraphStyle* currentParagraphStyle( NSDictionary* dict )
{
	CTParagraphStyleRef paraStyle 
	= (CTParagraphStyleRef)[dict objectForKey: (id)kCTParagraphStyleAttributeName];
	OAMutableParagraphStyle* result = nil;
	if( paraStyle ) {
		result = [[OAMutableParagraphStyle alloc] initWithParagraphStyle: 
				  [[[OAParagraphStyle alloc] 
					initWithCTParagraphStyle: paraStyle] autorelease]];
	}
	else {
		result = (id)[OAMutableParagraphStyle defaultParagraphStyle];	
	}
	return result;
}

static void setCurrentParagraphStyle( NSMutableDictionary* dict, OAMutableParagraphStyle* style )
{
	CTParagraphStyleRef ref = [style copyCTParagraphStyle];
	[dict setObject: (id)ref forKey: (id)kCTParagraphStyleAttributeName];
	CFRelease( ref );
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

-(NSDictionary*)coreTextAttrsForFontAttrs: (NSDictionary*)fontAttrs
{
	if( !fontAttrs || ![fontAttrs count] ) {
		return nil;
	}
	
	NSMutableDictionary* dict = [self mutableDictionaryWithCurrentStyle];
	
	for( id styleName in fontAttrs ) {
		id styleValue = [fontAttrs objectForKey: styleName];
		if( OFISEQUAL( styleName,  @"color") ) {
			[dict setObject: (id)parseColor( styleValue )
					 forKey: (id)kCTForegroundColorAttributeName];
		}
	}
	return dict;
}

-(NSDictionary*)coreTextAttrsForStyle: (NSString*)style
{
	NSArray* styleAttributes = [style componentsSeparatedByString: @";"];
	if( [NSArray isEmptyArray: styleAttributes] ) {
		return nil;
	}
	
	NSMutableDictionary* dict = [self mutableDictionaryWithCurrentStyle];
	
	for( id styleAttribute in styleAttributes ) {
		styleAttribute = [styleAttribute stringByTrimmingCharactersInSet:
						  [NSCharacterSet whitespaceAndNewlineCharacterSet]];	
		//TODO: Data driven.
		//Fonts 
		HAS_VALUE("font-family") {
			setCurrentFontDescriptor(
									 dict,
									 [currentFontDescriptor( dict ) 
									  newFontDescriptorWithFamily: styleAttribute] );
		} EHV
		else HAS_VALUE("font-size") {
			setCurrentFontDescriptor( 
									 dict,
									 [currentFontDescriptor( dict ) 
									  newFontDescriptorWithSize: [styleAttribute intValue]] );
			
		} EHV
		else HAS_VALUE("font-weight") {
			setCurrentFontDescriptor( 
									 dict,
									 [currentFontDescriptor( dict ) 
									  newFontDescriptorWithBold: [styleAttribute isEqual: @"bold"]] );
		} EHV
		else HAS_VALUE("font-style") {
			setCurrentFontDescriptor( 
									 dict,
									 [currentFontDescriptor( dict ) 
									  newFontDescriptorWithItalic: [styleAttribute isEqual: @"italic"]] );
			
		} EHV
		else HAS_VALUE("text-decoration") {
			NSUInteger value = kCTUnderlineStyleNone;
			if( [styleAttribute isEqual: @"underline"] ) {
				value = kCTUnderlineStyleSingle;
			}
			[dict setUnsignedIntValue: value
							   forKey: (id)kCTUnderlineStyleAttributeName];
		} EHV
		//Colors
		else HAS_VALUE("color") {
			[dict setObject: (id)parseColor( styleAttribute )
					 forKey: (id)kCTForegroundColorAttributeName];
		} EHV
		else HAS_VALUE("background-color") {
			[dict setObject: (id)parseColor( styleAttribute )
					 forKey: (id)OABackgroundColorAttributeName];
		} EHV
		//Paragraph style
		else HAS_VALUE("text-align") {
			OATextAlignment align = OANaturalTextAlignment;
			if( [styleAttribute isEqual: @"left"] ) {
				align = OALeftTextAlignment;
			}
			else if( [styleAttribute isEqual: @"right"] ) {
				align = OARightTextAlignment;
			}
			else if( [styleAttribute isEqual: @"justify"] ) {
				align = OAJustifiedTextAlignment;
			}
			else if( [styleAttribute isEqual: @"center"] ) {
				align = OACenterTextAlignment;	
			}
			OAMutableParagraphStyle* s = currentParagraphStyle( dict );
			[s setAlignment: align];
			setCurrentParagraphStyle( dict, s );
		} EHV
		//There may be some math on the margins that's not quite right.
		else HAS_VALUE("margin-left") {
			NSInteger leftpts = [styleAttribute intValue];
			OAMutableParagraphStyle* s = currentParagraphStyle( dict );
			[s setHeadIndent: leftpts];
			setCurrentParagraphStyle( dict, s );
		} EHV
		else HAS_VALUE("margin-right") {
			NSInteger rightpts = [styleAttribute intValue];
			//HTML uses inset from right, CoreText uses either left or right,
			//with negative meaning right
			rightpts = -rightpts;
			OAMutableParagraphStyle* s = currentParagraphStyle( dict );
			[s setTailIndent: rightpts];
			setCurrentParagraphStyle( dict, s );
		} EHV
		
	}
	return dict;
}

#undef HAS_VALUE
#undef EHV

-(CGImageRef)loadImage: (NSString*)url
{
	//Seriously cheating here
	NSString* dataPfx = @"data:image/png;base64,";
	NSData* imgData = nil;
	if( [url hasPrefix: dataPfx] ) {
		imgData = [NSData dataWithBase64String: [url substringFromIndex: dataPfx.length]];
	}
	else {
		imgData = [NSData dataWithContentsOfURL: [NSURL URLWithString: url]];
	}
	
	CGImageRef imageRef = nil;
	
	if( imgData ) {
		CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData( (CFDataRef)imgData );
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
	if( [@"a" isEqual: elementName] ) {
		NTI_RELEASE( self->currentHref );
		self->currentHref = [[attributeDict objectForKey: @"href"] copy];	
	}
	else if( [@"img" isEqual: elementName] ) {
		if(self->currentImage){
			CFRelease( self->currentImage );
		}
		NSString* src = [attributeDict objectForKey: @"src"];
		self->currentImage = [self loadImage: src];
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
								 [currentFontDescriptor( coreAttrs ) 
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
								 [currentFontDescriptor( coreAttrs ) 
								  newFontDescriptorWithBold: YES] );
		PUSH( coreAttrs );
	}
	else if( [@"tt" isEqual: elementName] || [@"code" isEqual: elementName] ) {
		//push type writer font	
		NSMutableDictionary* coreAttrs = [self mutableDictionaryWithCurrentStyle];
		setCurrentFontDescriptor( 
								 coreAttrs,
								 [currentFontDescriptor( coreAttrs ) 
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
	POPIF(@"strong")	
	POPIF(@"tt")	
	POPIF(@"code")		
#undef POPIF
	//Besides A, the only other tage we're expecting is IMG.
	//It won't have style on it, and neither will an enclosing HTML
	//or BODY, if present, so our stack stays in sync.
	else if(	[@"a" isEqual: elementName] 
	   		&&	self->currentHref
			&&	self->currentImage ) {
		[self handleAnchorTag: self->attrBuffer 
				  currentHref: self->currentHref		
				 currentImage: self->currentImage];
	}
	
}

-(void)handleAnchorTag: (NSMutableAttributedString*)attrBuffer
		   currentHref: (NSString*)currentHref 
		  currentImage: (CGImageRef) currentImage
{
	
}


- (void)dealloc
{
	if(self->currentImage){
		CFRelease( self->currentImage );
	}
	NTI_RELEASE( self->currentHref );
	NTI_RELEASE( self->nsattrStack );
	NTI_RELEASE( self->attrBuffer );
	[super dealloc];
}

@end
