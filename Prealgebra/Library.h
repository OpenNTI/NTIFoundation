//
//  Library.h
//  Prealgebra
//
//  Created by Jason Madden on 2011/06/28.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <OmniFoundation/OmniFoundation.h>

//The properties in the LibraryEntry match the fields
//in the Plist, plus a few
@interface LibraryEntry : OFObject {
}
//PList fields
@property (retain,nonatomic) NSString* archive, *href, *icon, *index, *root, *title, *version;
@property (nonatomic,assign) BOOL installable;


/**
 * The original URL we loaded this from.
 */
@property (retain,nonatomic) NSString* archiveUrlString;


//Extra things
/**
 * The absolute URL to the starting document of this entry.
 */
@property (retain,nonatomic) NSURL* entryUrl;

@property (readonly,nonatomic) NSURL* archiveUrl;
@end

@class NTINavigationItem;
@interface Library : OFObject {
@private
	NSMutableArray* libraryEntries;
	NSURL* libraryDir;
	NSURL* contentsDir;
	volatile NTINavigationItem* rootNavItem;
	dispatch_queue_t syncNavQueue, syncDownloadQueue;
}

+(Library*)sharedLibrary;

/**
 * Registers in the default notifacation center an observer that will 
 * receive progress notifications as the library performs synchronization
 * tasks. The notification will conform to the informal protocol NTILibraryNotifications
 * to provide information about the progress. The caller must deregister
 * the observer.
 */
+(void)registerSyncProgressObserver: (id)observer
						   selector: (SEL)selector;

/**
 * Returns an array of LibraryEntry objects representing
 * each object locally cached.
 */
@property (nonatomic,readonly) NSArray* entries;

/**
 * Returns the local entry for the given name, if present.
 * Otherwise returns nil.
 */
-(LibraryEntry*)entryNamed: (NSString*)name;



@property (nonatomic,readonly) NTINavigationItem* rootNavigationItem;

//-(void)loadNavigation;

@end


/**
 * An informal protocol that notifications sent during library operations
 * will conform to.
 */
@interface NSNotification(NTILibraryNotifications)
/**
 * If present, the title undergoing synchronization.
 */
-(NSString*)title;

/**
 * If YES, then synchronization is in progress. If NO, there is no
 * synchronization in progress.
 */
-(BOOL)isSynchronizing;

/**
 * If YES, then a lengthy data download is in progress. If NO, there is
 * no download in progress.
 */
-(BOOL)isDownloading;

/**
 * While synchronization is in progress, if this number is not 0, 
 * it is a number between 1 and 100 representing the percent of the task
 * that is finished.
 */
-(NSInteger)progressPercent;
@end


