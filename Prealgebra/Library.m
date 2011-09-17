//
//  Library.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/06/28.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "Library.h"
#import "NTIAbstractDownloader.h"
#import "NTIAppPreferences.h"
#import "NTINavigationParser.h"
#import <OmniUnzip/OUUnzipArchive.h>
#import <OmniUnzip/OUUnzipEntry.h>
#import "OUUnzipArchive-NTIExtensions.h"
#import "OmniFoundation/NSDictionary-OFExtensions.h"
#import "TestAppDelegate.h"
#import <Foundation/Foundation.h>

#import "NTIOSCompat.h"
#import <libkern/OSAtomic.h>

@implementation LibraryEntry
@synthesize archive, href, icon, index, root, title, version;
@synthesize installable;

@synthesize entryUrl, archiveUrlString;

-(NSURL*)archiveUrl
{
	return [NSURL URLWithString: self.archiveUrlString];
}

-(id)objectForKey: (id)key
{
	//Make us compatible with the dictionary plist that we came from
	return [self valueForKey: key];
}

-(void)setValue: (id)value forUndefinedKey: (id)key
{
	//Tolerate unsupported keys, since we copy what we want
	//and the dataserver format could be changing
	return;
}

-(void)dealloc
{
	self.archive = nil;
	self.href = nil;
	self.index = nil;
	self.root = nil;
	self.title = nil;
	self.version = nil;
	self.entryUrl = nil;
	self.icon = nil;
	self.archiveUrlString = nil;
	[super dealloc];
}
@end

@interface Library()
-(BOOL)loadEntries;
-(void)addEntryAt: (NSURL*)fullUrl 
	  withDetails: (NSDictionary*)details
		 andIndex: (NSUInteger)childIndex
	   loadedFrom: (NSURL*)archive;
-(void)saveEntries;
-(NSString*)title;
-(NSString*)icon;
-(void)synchronizeNavigation;
/**
 * Creates an entry in the library having the given name 
 * and containing the results of fetching and unzipping the ZIP
 * file at the archive location.
 */
-(void)createEntryInLibraryNamed: (NSString*)name
					 fromArchive: (NSURL*)archive
					 withDetails: (NSDictionary*)details
						andIndex: (NSUInteger)childIndex;
@end

@implementation NSNotification(NTILibraryNotifications)

-(NSString*)title
{
	return [self.userInfo objectForKey: @"NTILibrarySyncTitle"];
}

-(BOOL)isSynchronizing
{
	return [self.userInfo boolForKey: @"NTILibrarySyncIsSync"];
}

-(BOOL)isDownloading
{
	return [self.userInfo boolForKey: @"NTILibraryIsDownloading"];
}

-(NSInteger)progressPercent
{
	return [self.userInfo integerForKey: @"NTILibrarySyncProgressPercent"];
}

+(NSNotification*)ntiLibraryNotificationForLibrary: (id)library
											 title: (NSString*)title
											isSync: (BOOL)sync
											isDown: (BOOL)down
										  progress: (NSInteger)progress
{
	return [NSNotification
			notificationWithName: @"NTILibraryProgressNotification" 
			object: library
			userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
					   title, @"NTILibrarySyncTitle",
					   [NSNumber numberWithBool: sync], @"NTILibrarySyncIsSync",
					   [NSNumber numberWithBool: down], @"NTILibrarySyncIsDownloading",
					   [NSNumber numberWithInteger: progress], @"NTILibrarySyncProgressPercent",
					   nil]];
}

+(void)ntiPostLibraryNotificationForLibrary: (id)library
									  title: (NSString*)title
									 isSync: (BOOL)sync
									 isDown: (BOOL)down
									 //Scale from 0 to 100.
								   progress: (NSInteger)progress
{
	[[NSNotificationCenter defaultCenter] 
	 postNotification: [self ntiLibraryNotificationForLibrary: library
														title: title 
													   isSync: sync
													   isDown: down
													 progress: progress]];
}
@end

@implementation Library

static Library* sharedLibrary = nil;

+(Library*)sharedLibrary
{
	if( sharedLibrary == nil ) {
		sharedLibrary = [[Library alloc] init];
		dispatch_async( sharedLibrary->syncNavQueue, ^{ [sharedLibrary synchronizeNavigation]; });
	}
	return sharedLibrary;
}

+(void)registerSyncProgressObserver: (id)observer
						   selector: (SEL)selector
{
	[[NSNotificationCenter defaultCenter]
	 addObserver: observer
	 selector: selector
	 name: @"NTILibraryProgressNotification"
	 object: [self sharedLibrary]];
}

-(id)init
{
	self = [super init];
	self->syncNavQueue = dispatch_queue_create( "com.nextthought.Library.NavSync", NULL );
	self->syncDownloadQueue = dispatch_get_global_queue( 0, 0 );
	self->libraryEntries = [[NSMutableArray alloc] initWithCapacity: 5];
	
	NSFileManager* fileMan = [NSFileManager defaultManager];
	NSURL* appSupDir = [fileMan URLForDirectory: NSApplicationSupportDirectory
									   inDomain: NSUserDomainMask
							  appropriateForURL: nil
										 create: YES error: NULL];
	self->libraryDir = [[appSupDir 
						 URLByAppendingPathComponent: [[NSBundle mainBundle] bundleIdentifier]
						 isDirectory: YES] 
						URLByAppendingPathComponent: @"Library"
						isDirectory: YES];
	self->contentsDir = [self->libraryDir URLByAppendingPathComponent: @"Contents" isDirectory: YES];
	self->rootNavItem = [[NTINavigationItem alloc]
						 initWithName: [self title]
						 href: @""
						 icon: [self icon]
						 ntiid: @"Library"
						 relativeSize: -1];
	
	BOOL success = [fileMan createDirectoryAtPath: pathFromUrl( self->contentsDir )
					  withIntermediateDirectories: YES
									   attributes: nil
											error: NULL];
	
	if( !success || ![self loadEntries]) {
		[self release];
		self = nil;
	}
	else {
		[self->libraryDir retain];
		[self->contentsDir retain];
	}
	
	return self;
	
}

-(void)dealloc
{
	if( self->syncNavQueue ) {
		dispatch_release( self->syncNavQueue );
		self->syncNavQueue  = NULL;
	}/*
	if( self->syncDownloadQueue ) {
		dispatch_release( self->syncDownloadQueue );
		self->syncDownloadQueue  = NULL;
	}*/
	[self->libraryDir release];
	[self->libraryEntries release];
	[self->contentsDir release];
	[self->rootNavItem release];
	[super dealloc];
}

-(BOOL)loadEntries
{
	BOOL corrupted = NO;
	NSArray* plist = [NSArray arrayWithContentsOfURL:
					  [self->libraryDir URLByAppendingPathComponent: @"contents.xml"]];
	for( NSDictionary* dict in plist ) {
		LibraryEntry* entry = [[[LibraryEntry alloc] init] autorelease];
		[entry setValuesForKeysWithDictionary: dict];
		entry.entryUrl = [NSURL URLWithString: entry.href];
		if(		[[NSFileManager defaultManager] isReadableFileAtPath: entry.entryUrl.path] 
		   &&	![self entryNamed: entry.title]) {
			[self->libraryEntries addObject: entry];
		}
		else {
			corrupted = YES;
			NSLog( @"Corrupted Library contents.xml: %@", plist );	
		}
	}
	
	if( corrupted ) {
		//TODO: Determine the actual cause of corruption. I think 
		//it may be adding multiple entries when switching among
		//different timestamp archives (different environments). We
		//need to keep just one by name.
		NSLog( @"Resaving library to clear corruption." );
		[self saveEntries];
	}
	
	return YES;
}

//Properties used for navigation
//FIXME: This doesn't belong here.
-(NSString*)icon
{
	return @"/prealgebra/icons/chapters/Chalkboard.tif";
}

-(NSString*)title
{
	return @"Library";
}

-(NSArray*)entries
{
	return [[self->libraryEntries copy] autorelease];
}

-(LibraryEntry*)entryNamed: (NSString*)name
{
	LibraryEntry* result = nil;
	NSUInteger index = [self->libraryEntries indexOfObjectPassingTest:
						^(id obj, NSUInteger _, BOOL* __ ){
							return [name isEqual: [obj title]];
						}];
	if( index != NSNotFound ) {
		result = [self->libraryEntries objectAtIndex: index];
	}
	return result;
}

-(void)createEntryInLibraryNamed: (NSString*)name
					 fromArchive: (NSURL*)archive
					 withDetails: (NSDictionary*)details
						andIndex: (NSUInteger)childIndex
{
	NSURL* entryDir = [self->contentsDir URLByAppendingPathComponent: name isDirectory: YES];
	if( [[NSFileManager defaultManager] fileExistsAtPath: pathFromUrl( entryDir )] ) {
		NSLog( @"Overwriting existing entry!" );
	}
	[NSNotification ntiPostLibraryNotificationForLibrary: self
												   title: name
												  isSync: YES 
												  isDown: YES
												progress: 0];
	NSURL* archiveFile = nil;
	{
	NSString* tempDirPath = NSTemporaryDirectory();
	NSString* template = [tempDirPath stringByAppendingString: @"archive.zip.XXXXXX"];
	//We would use mkstemp for security purposes, but we're on a 
	//single-user operating system. 
	//Note that mktemp modifies its argument
	const char* utfString = [template UTF8String];
	char cp[strlen(utfString) + 1]; //On the stack
	char* filled = strcpy(cp, utfString);
	filled = mktemp( filled );
	archiveFile = [NSURL fileURLWithPath: [NSString stringWithUTF8String: filled]];
	}
	
	NSOutputStream* stream = [[[NSOutputStream alloc] initWithURL: archiveFile append: NO] autorelease];
	if( !stream ) {
		NSLog( @"Unable to open stream to save archive %@", archive );
		return;
	}
	//Thread handling is sort of tricky here. The NSURLConnection requires
	//a working run loop. It doesn't guarantee that it will unschedule itself when
	//it finishes. We could use the main run loop, but we want to keep everything
	//going on our private queue so that we can guarantee when we're done. So,
	//we pump a run loop until the connection finishes or errors. Because
	//the callback functions are called synchronously, we can safely manipulate
	//the state variable without any race conditions. The one possible drawback
	//is tieing our queue up for awhile (until we can use a concurrent queue)
	volatile __block BOOL runTheRunLoop = YES;
	NTIStreamDownloader* downloader = [NTIStreamDownloader alloc];

	downloader = [downloader 
				  initWithUsername: [NTIAppPreferences prefs].username
				  password: [NTIAppPreferences prefs].password
				  outputStream: stream
				  onFinish: 
				  ^{
					  runTheRunLoop = NO;
					  dispatch_async( self->syncDownloadQueue, 
					^{
						NSError* error = nil;
						NSURL* fullPath 
						= [OUUnzipArchive extract: archiveFile
											   to: name
										   within: self->contentsDir
										 progress: ^(NSInteger worked, NSUInteger count)
						   {
								NSInteger progress = (double)worked/(double)count * 100.0;
								[NSNotification ntiPostLibraryNotificationForLibrary: self
																			   title: name
																			  isSync: YES 
																			  isDown: NO
																			progress: progress];
						   }
											error: &error];
						[[NSFileManager defaultManager]
						 removeItemAtURL: archiveFile
						 error: NULL];
						[downloader release];
						[archiveFile release];
						if( fullPath ) {
							[self addEntryAt: fullPath 
								 withDetails: details
									andIndex: childIndex
								  loadedFrom: archive];
						}
						else if( error ) {
							NTI_PRESENT_ERROR( error );
						}
						[NSNotification ntiPostLibraryNotificationForLibrary: self
																	   title: name
																	  isSync: NO 
																	  isDown: NO
																	progress: 100];
						
					} );
				  }
				  onError:
				  ^{
					  runTheRunLoop = NO;
					  [[NSFileManager defaultManager] removeItemAtURL: archiveFile
																error: NULL];
					  [downloader release];
					  [archiveFile release];
				  }];
	
	NSURLRequest* request = [NSURLRequest requestWithURL: archive];
	dispatch_async( self->syncDownloadQueue, ^{
		NSURLConnection* conn = [[NSURLConnection alloc] initWithRequest: request 
																delegate: downloader
														startImmediately: NO];
		if( !conn ) {
			[downloader release];
			[archiveFile release];
		}
		else {
			[conn start];
			do {
				[[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode
										 beforeDate: [NSDate distantFuture]];
			} while( runTheRunLoop );
			[conn release];
		}
		[NSNotification ntiPostLibraryNotificationForLibrary: self
													   title: name
													  isSync: YES 
													  isDown: NO
													progress: 100];
	});
}

static void fixupPrefix( NTINavigationItem* kid )
{
	if( [kid.href characterAtIndex: 0] == '/' ) {
		NSArray* pathComps = [kid.href pathComponents];
		NSString* string = [NSString pathWithComponents:
							[pathComps subarrayWithRange: NSMakeRange( 2, pathComps.count - 2 )]];

		[kid setValue: string forKey: @"href"];
	}
	if( [kid.icon characterAtIndex: 0] == '/' ) {
		NSArray* pathComps = [kid.icon pathComponents];
		NSString* string = [NSString pathWithComponents:
							[pathComps subarrayWithRange: NSMakeRange( 2, pathComps.count - 2 )]];
		[kid setValue: string forKey: @"icon"];
	}
	for( id kid2 in kid.children ) {
		fixupPrefix( kid2 );
	}
}

-(void)addEntryAt: (NSURL*)url 
	  withDetails: (NSDictionary*)details
		 andIndex: (NSUInteger)index
	   loadedFrom: (NSURL*)archiveUrl
{
	LibraryEntry* entry = [[[LibraryEntry alloc] init] autorelease];
	[entry setValuesForKeysWithDictionary: details];
	NSUInteger rootLen = [entry.root length];
	//Take the root off of each other entry and replace
	//it with our full url
	entry.href = [[url URLByAppendingPathComponent: [entry.href substringFromIndex: rootLen]]
				  absoluteString];
	entry.entryUrl = [NSURL URLWithString: entry.href];
	entry.index = [[url URLByAppendingPathComponent: [entry.index substringFromIndex: rootLen]]
				   absoluteString];
	entry.icon = [[url URLByAppendingPathComponent: [entry.icon substringFromIndex: rootLen]]
				  absoluteString];
	entry.archiveUrlString = [archiveUrl absoluteString];
	[self->libraryEntries addObject: entry];
	
	//If the entry shipped with an application.css file, link it
	//to ours so it picks up our preferences
	NSFileManager* fileMan = [NSFileManager defaultManager];
	NSString* entryCSS = [[url URLByAppendingPathComponent: @"styles/application.css"] path];
	if( [fileMan fileExistsAtPath: entryCSS] ) {
	do {
		NSError* error = nil;
		BOOL success = [fileMan removeItemAtPath: entryCSS
										   error: &error];
		if( !success ) {
			NTI_PRESENT_ERROR( error );
			break;
		}
		NSString* prefCSS = [[[[NTIAppPreferences prefs] URLOfPreferencesCSS] absoluteURL] path];
		success = [fileMan createSymbolicLinkAtPath: entryCSS
								withDestinationPath: prefCSS
											  error: &error];
		if( !success ) {
			NTI_PRESENT_ERROR( error );
			break;
		}
		
	}while(0);
	}
	
	[self saveEntries];
	
	//Now, update the navigation item on that queue
	dispatch_async( self->syncNavQueue, ^{
		NTINavigationItem* newChild = [[self->rootNavItem children] objectAtIndex: index];
		[newChild setObject: @"" forKey: kNTINavigationPropertyRoot];
		//FIXME: This setting of properties is duplicated in the 
		//main loading method
		[newChild setObject: entry.entryUrl
					 forKey: kNTINavigationPropertyOverrideRoot
				  recursive: YES];
		
		[newChild setObject: [archiveUrl URLByDeletingLastPathComponent]
					 forKey: @"archiveUrl"
				  recursive: YES];
		[newChild setValue: entry.href forKey: @"href"];
		[newChild setValue: entry.icon forKey: @"icon"];
		//TODO: TEMPORARY: FIXME
		//The items we get back will have the URL prefix added
		//from the original parsing. We want to remove that. Rather than
		//reparsing, we mutate in place.
		for( id kid in newChild.children ) {
			fixupPrefix( kid );
		}

		[NTINavigationParserLoader prepareForNavigation: newChild
												rootURL: entry.entryUrl ];
		[self->rootNavItem adoptChild: newChild replacingIndex: index];
	});
}

-(void)saveEntries
{
	@synchronized(self) {
		id dicts = [NSMutableArray arrayWithCapacity: [self->libraryEntries count]];
		NSArray* keys = [NSArray arrayWithObjects: 
						 @"archive", @"href", @"icon", @"archiveUrlString",
						 @"index", @"root", @"title", @"version", @"installable", nil];
		//entryUrl is a URL and that cannot go in property lists
		for( LibraryEntry* ent in self->libraryEntries ) {
			[dicts addObject: [ent dictionaryWithValuesForKeys: keys]];
		}
		
		NSURL* contentPath = [libraryDir URLByAppendingPathComponent: @"contents.xml"];
		BOOL didWrite = [dicts writeToURL: contentPath
							   atomically: YES];
		if( !didWrite ) {
			NSLog( @"Failed to write to %@", contentPath );
		}
	}
}

#pragma mark Navigation

-(NTINavigationItem*) rootNavigationItem
{
	//This is optimized to use the current thread if there's nothing actually
	//waiting in the queue.
	dispatch_barrier_sync(
		self->syncNavQueue, 
		^{} );
	//Ensure that we get the final published version.
	OSMemoryBarrier();
	return (id)[[self->rootNavItem retain] autorelease];
}

static NSDate* dateForEntry( LibraryEntry* ent )
{
	//This is the URL to the index.html file
	NSURL* url = ent.entryUrl;
	//which has the timestamp from within the archive. We want the TS
	//of the containing directary, which has the TS we extracted at
	url = [url URLByDeletingLastPathComponent];
	
	NSDate* date = [[[NSFileManager defaultManager] 
					 attributesOfItemAtPath: pathFromUrl( url ) error: NULL]
					fileModificationDate];
	return date;
}

-(void)synchronizeNavigation
{
	//This should be called in the background, not the main thread.
	[NSNotification ntiPostLibraryNotificationForLibrary: self
												   title: nil
												  isSync: YES 
												  isDown: NO
												progress: 0];
	NSURL* libraryURL = [[NTIAppPreferences prefs] URLRelativeToRoot: @"/library/library.plist"];
	NSData* libraryData = [NSData dataWithContentsOfURL: libraryURL];
	NSDictionary* remoteLibrary = nil;
	id theLibraryEntries = nil;
	if( !libraryData ) {
		//TODO: Shouldn't do this here, we're a model!
		UIAlertView* alert = [[[UIAlertView alloc] initWithTitle: @"Error"
														 message: [NSString stringWithFormat: @"Unable to load library from %@", libraryURL]
														delegate: nil
											   cancelButtonTitle: @"OK"
											   otherButtonTitles: nil ] autorelease];
		[alert show];
		theLibraryEntries = [self entries];
	}
	else {
		remoteLibrary = [NSPropertyListSerialization 
						 propertyListWithData: libraryData
						 options: NSPropertyListMutableContainersAndLeaves
						 format: nil
						 error: NULL];
		//Since we have a remote library, install everything
		//locally that we can. Also merge in local stuff.
		//TODO: Removing local entries not in remote?
		//FIXME: Something seems to not be working here
		theLibraryEntries = [remoteLibrary objectForKey: @"titles"];
		for( NSUInteger i = 0; i < [theLibraryEntries count]; i++ ) {
			NSDictionary* dict = [theLibraryEntries objectAtIndex: i];
			NSString* title = [dict objectForKey: @"title"];
			NSInteger archiveTime = [[dict objectForKey: @"Archive Last Modified"] integerValue];
			if(		[[dict objectForKey: @"installable"] boolValue]
			   &&	(	![self entryNamed: title]
				 ||		[dateForEntry([self entryNamed: title]) timeIntervalSince1970]
					 < archiveTime ) ) {
				[self
				 createEntryInLibraryNamed: title
				 fromArchive: [[NTIAppPreferences prefs] 
							   URLRelativeToRoot: [dict objectForKey: @"archive"]]
				 withDetails: dict
				 andIndex: i];
			}
			if( [self entryNamed: title] ) {
				[theLibraryEntries replaceObjectAtIndex: i 
										  withObject: [self entryNamed: title]];
			}
		}
	}
	for( NSUInteger idx = 0, count = [theLibraryEntries count]; idx < count; idx++ ) {
		id child = [theLibraryEntries objectAtIndex: idx];
		NTINavigationItem* childItem = [[[NTINavigationItem alloc]
										 initWithName: [child objectForKey: @"title"]
										 href: [child objectForKey: @"href"]
										 icon: [child objectForKey: @"icon"]
										 ntiid: [child objectForKey: @"href"]
										 relativeSize: -1] autorelease];
		[self->rootNavItem adoptChild: childItem];
		if( ![child objectForKey: @"index"] ) {
			[NTINavigationParserLoader prepareForNavigation: childItem
													rootURL: [[NTIAppPreferences prefs] rootURL]];
			break;
		}
		//TEMPORARY
		NSString* index = [child objectForKey: @"index"];
		NSURL* rootUrl = [[NTIAppPreferences prefs] rootURL];
		NSString* childRoot = [child objectForKey: @"root"];
		if( [child isKindOfClass: [LibraryEntry class]] ) {
			rootUrl = [child entryUrl];
			childRoot = @"";
		}
		[NTINavigationParserLoader 
		 loadFromString: index
		 relativeToURL: rootUrl
		 hrefPrefix: childRoot
		 callback: ^(NTINavigationParser* p) 
		 {
			 id newChild = [p root];
			 if( newChild ) {
				 [newChild setObject: childRoot forKey: kNTINavigationPropertyRoot];
				 if( rootUrl != [[NTIAppPreferences prefs] rootURL] ) {
					 [newChild setObject: rootUrl 
								  forKey: kNTINavigationPropertyOverrideRoot
							   recursive: YES];
				 }
				 if( [child isKindOfClass: [LibraryEntry class]] ) {
					 [newChild setObject: [[child archiveUrl] URLByDeletingLastPathComponent]
								  forKey: @"remoteRootUrl"
							   recursive: YES];
				 }
				 [rootNavItem adoptChild: newChild replacingIndex: idx];
			 }
		 }
		 queue: self->syncNavQueue];
	}
	dispatch_barrier_async( self->syncNavQueue, ^{
		//Force this to be published.
		OSMemoryBarrier();
		[NSNotification ntiPostLibraryNotificationForLibrary: self
													   title: nil
													  isSync: NO
													  isDown: NO
													progress: 100];
	});
}


@end
