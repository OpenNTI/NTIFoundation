//
//  NTIPreferences.h
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/02.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "OmniFoundation/OmniFoundation.h"
@class OQColor;
/**
 * A wrapper around a preference facility (NSUserDefaults) giving us
 * named preferences and management facilities. It is also responsible for
 * updating the on-disk CSS representation of the relevant prefs.
 */
@interface NTIAppPreferences : OFObject {
	@private
	id cachedRootURL, cachedUsername, cachedPassword;
}

+(NTIAppPreferences*) prefs;

@property (nonatomic,readonly) NSURL *rootURL, *dictionaryURL, *dataserverURL;
@property (nonatomic,readonly) NSString* username;
@property (nonatomic,assign) NSString* password;

@property (nonatomic,assign) NSString *fontFace, *fontSize;
@property (nonatomic,assign) OQColor* highlightColor;
//@property (nonatomic,assign) NSURL* lastViewedURL;
@property (nonatomic,assign) NSString* lastViewedNTIID;

@property (nonatomic,readonly) BOOL highlightsEnabled, notesEnabled, scrubBarDots;

/**
 * NSArray of NSString. Has retain count of 0.
 */
@property (nonatomic,readonly) NSArray *friends;

/**
 * The friends as a JSON string representing an array.
 */
@property (nonatomic,readonly) NSString* friendsInJSON;

-(NSURL*)URLRelativeToRoot: (NSString*)path;

/**
 * Returns a local file URL containing the complete path to 
 * the on-disk CSS containing prefernce settings.
 */
-(NSURL*)URLOfPreferencesCSS;

@end
