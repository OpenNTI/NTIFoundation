//
//  NTIPreferences.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/02.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTIAppPreferences.h"
#import "NSArray-NTIJSON.h"
#import "TestAppDelegate.h"
#import "OQColor-NTIExtensions.h"

@interface NTIAppPreferences()
-(void)updateCSS;
-(void)registerCredentials;
@end

@implementation NTIAppPreferences

static NTIAppPreferences* sharedPrefs;

+(void) registerDefaults
{
	//Pink
	NSString* defaultHighlightColor = [OQColor colorWithRed: 1.0f
													  green: 192.0f/255.0f
													   blue: 203.0f/255.0f
													  alpha: 1.0f].rgbaString;
	NSString* userName = NSUserName();
	NSString* password = @"temp001";
	NSString* host = @"http://alpha.nextthought.com";
#ifdef DEBUG_jmadden
	userName = @"jason.madden@nextthought.com";
	password = @"jason.madden";
	host = @"http://curie.local:8080";
#endif
	NSDictionary* defaults = [NSDictionary dictionaryWithObjectsAndKeys:
							  //Note that it's not possible to (directly) store a URL
							  //in the registration domain!
							  host,
							  @"RootURL",
							  userName,
							  @"username",
							  password,
							  @"password",
							  @"Palatino",
							  @"mainWebViewFontFace",
							  @"100%",
							  @"mainWebViewFontSize",
							  @"YES",
							  @"notesEnabled",
							  @"YES",
							  @"highlightsEnabled",
							  @"NO",
							  @"mainWebViewUseMathFonts",
							  @"mobile",
							  @"sharedUserNames",
							  @"YES",
							  @"scrubBarDots",
							  defaultHighlightColor,
							  @"highlightColor",
							  nil];
	
	if( ! [[NSUserDefaults standardUserDefaults] stringForKey: @"username"] ) {
		[[NSUserDefaults standardUserDefaults] setObject: userName
												  forKey: @"username"];
	}
	[[NSUserDefaults standardUserDefaults] registerDefaults: defaults];
}

+(void)initialize
{
	OBINITIALIZE;
	sharedPrefs = [[NTIAppPreferences alloc] init];
	[self registerDefaults];
	[[NSNotificationCenter defaultCenter]
	 addObserver: sharedPrefs 
	 selector: @selector(defaultsChanged:) 
	 name: NSUserDefaultsDidChangeNotification
	 object: nil];

	[sharedPrefs registerCredentials];
}

+(NTIAppPreferences*) prefs
{
	return sharedPrefs;
}

-(id)retain
{
	return self;
}

-(oneway void)release
{
}

static NSUserDefaults* defs()
{
	return [NSUserDefaults standardUserDefaults];
}

-(void)defaultsChanged: (NSNotification*)note
{
	if(		![self->cachedUsername isEqual: [defs() stringForKey: @"username"]]
	   ||	![self->cachedPassword isEqual: [defs() stringForKey: @"password"]]
	   ||	![self->cachedRootURL isEqual: [NSURL URLWithString: [defs() stringForKey: @"RootURL"]]] ) {
		self->cachedRootURL = nil;
		self->cachedPassword = nil;
		self->cachedUsername = nil;
		[self registerCredentials];
	}
}

-(void)registerCredentials
{
	NSURL* rootURL = [self rootURL];
	NSURLProtectionSpace* space = [[NSURLProtectionSpace alloc] 
									initWithHost: rootURL.host
									port: [rootURL.port integerValue]
									protocol: rootURL.scheme
									realm: nil
									authenticationMethod: NSURLAuthenticationMethodDefault];
	NSURLCredential* cred = [NSURLCredential credentialWithUser: self.username
													   password: self.password
													persistence: NSURLCredentialPersistenceForSession];
	[[NSURLCredentialStorage sharedCredentialStorage] 
		setCredential: cred
		forProtectionSpace: space];
	[[NSURLCredentialStorage sharedCredentialStorage] 
	 setDefaultCredential: cred
	 forProtectionSpace: space];

	[space release];
}

-(NSURL*)rootURL
{
	if( !self->cachedRootURL ) {
		cachedRootURL = [[NSURL URLWithString: [defs() stringForKey: @"RootURL"]] retain];
	}
	return [[cachedRootURL retain] autorelease];
}

-(NSURL*)URLRelativeToRoot: (NSString*)path
{
	return [NSURL URLWithString: path relativeToURL: [self rootURL]];
}

-(NSURL*)dictionaryURL
{
	return [self URLRelativeToRoot: @"/dictionary/"];
}

-(NSURL*)dataserverURL
{
	return [self URLRelativeToRoot: @"/dataserver/"];
}

-(NSString*)lastViewedNTIID
{
	return [defs() stringForKey: @"lastViewedNTIID"];
}

-(NSString*)username
{
	if( !cachedUsername ) {
		cachedUsername = [defs() stringForKey: @"username"];
	}
	return [[cachedUsername retain] autorelease];
}

-(NSString*)password
{
	if( !cachedPassword ) {
		cachedPassword = [defs() stringForKey: @"password"];
	}
	return [[cachedPassword retain] autorelease];
}

-(void)setPassword: (NSString*)password
{
	[defs() setObject: password forKey: @"password"];
}

-(void)setLastViewedNTIID: (NSString*)ntiid
{
	if( ntiid ) {
		[defs() setObject: ntiid forKey: @"lastViewedNTIID"];
	}
	else {
		[defs() removeObjectForKey: @"lastViewedNTIID"];
	}
}

#define SIMPLEVALUE(rt, type, name) \
-(rt) name { return [defs() type ## ForKey: NSStringFromSelector(_cmd)]; } \

SIMPLEVALUE(BOOL,bool,highlightsEnabled)
SIMPLEVALUE(BOOL,bool,notesEnabled)
SIMPLEVALUE(BOOL,bool,scrubBarDots)
#undef SIMPLEVALUE

#define BOOLSETTER(name,key)\
-(void) set##name: (BOOL)v { [defs() setBool: v forKey: key]; [self updateCSS]; }
	 
BOOLSETTER(NotesEnabled, @"notesEnabled")
BOOLSETTER(HighlightsEnabled, @"highlightsEnabled")
#undef BOOLSETTER


-(NSArray*)friends
{
	NSArray* result;
	NSString* friendString = 
	[[defs() stringForKey: @"sharedUserNames"] 
	 stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if( !friendString || [friendString length] == 0 ) {
		result = [NSArray array];
	}
	else {
		//We allow separation with spaces and with commas
		result = [NSMutableArray arrayWithArray:
				  [friendString componentsSeparatedByCharactersInSet:
				   [NSCharacterSet characterSetWithCharactersInString: @", "]]];
		[(NSMutableArray*)result removeObject: @""];
	}
	return result;
}

-(NSString*)friendsInJSON
{
	return [[self friends] stringWithJsonRepresentation];
}

-(NSString*)fontFace
{
	return [defs() stringForKey: @"mainWebViewFontFace"];
}

-(void)setFontFace: (NSString*)value
{
	[defs() setObject: value forKey: @"mainWebViewFontFace"];
	[self updateCSS];
}

-(NSString*)fontSize
{
	return [defs() stringForKey: @"mainWebViewFontSize"];
}

-(void)setFontSize: (NSString*)value
{
	[defs() setObject: value forKey: @"mainWebViewFontSize"];
	[self updateCSS];
}

-(OQColor*)highlightColor
{
	return [OQColor colorFromRGBAString: [defs() stringForKey: @"highlightColor"]];
}

-(void)setHighlightColor: (OQColor*)value
{
	[defs() setObject: value.rgbaString forKey: @"highlightColor"];
	[self updateCSS];
}

-(NSURL*)URLOfPreferencesCSS
{
	NSFileManager* fileMan = [NSFileManager defaultManager];
	NSURL* appSupDir = [fileMan URLForDirectory: NSApplicationSupportDirectory
									   inDomain: NSUserDomainMask
							  appropriateForURL: nil
										 create: YES error: NULL];
	NSURL* appCSS = [appSupDir URLByAppendingPathComponent: @"application.css"];
	return appCSS;
}

-(void)updateCSS
{
	NSURL* appCSS = [self URLOfPreferencesCSS];
	
	NSString* CSS = [NSString stringWithFormat: 
					 @"\n\n#NTIContent {\n\tfont-family: '%@';\n\tfont-size: %@;\n}\n",
					 [self fontFace], [self fontSize]];
	
	if( ![self notesEnabled] ) {
		CSS = [CSS stringByAppendingString: @"\n#NTIContent .inlinenote {\n\tdisplay: none;\n}\n"];
	}
	
	if( [self highlightColor] ) {
		//This must match NTIJSInjection
		NSString* color = self.highlightColor.cssString; 
		CSS = [CSS stringByAppendingFormat: @"\n#NTIContent .highlight {\n\tbackground-image: -webkit-gradient(linear, left top, left bottom, from(white), to(%@));\n}\n",
			   color];
	}
	
	NSError* error = nil;
	BOOL wrote = [CSS writeToURL: appCSS
					  atomically: YES
						encoding: NSUTF8StringEncoding
						   error: &error];
	if( !wrote ) {
		NTI_PRESENT_ERROR( error );
	}
}

@end
