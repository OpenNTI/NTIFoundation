//
//  TestAppDelegate.m
//  Test
//
//  Created by Jason Madden on 2011/05/19.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "TestAppDelegate.h"
#import "NTIApplicationViewController.h"
#import "NTIUrlScheme.h"

#import <OmniFoundation/NSData-OFEncoding.h>
#import "NTIAppPreferences.h"
#import "NTIAbstractDownloader.h"

#import "NTIAppUser.h"

NSString* const NTINotificationRemoteNotificationRecvName = @"NTINotificationRemoteNotificationRecvName";

@implementation TestAppDelegate

+ (TestAppDelegate*) sharedDelegate
{
	return [OUIAppController controller];
}

@synthesize window;


-(BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions: (NSDictionary*)launchOptions
{
	[self.window makeKeyAndVisible];
	UIViewController* rootCont = [[NTIApplicationViewController alloc] init];
	self.window.rootViewController = rootCont;
	[rootCont release];
	
	//Remote notifications
	[app registerForRemoteNotificationTypes: UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];
	
	
	//Clear the app badge
	app.applicationIconBadgeNumber = 0;

	//Wake the user up, start him loading data
	[NTIAppUser appUser];
	
	NSURL* url = [launchOptions objectForKey: UIApplicationLaunchOptionsURLKey];
	NSDictionary* remoteNotif = [launchOptions objectForKey: UIApplicationLaunchOptionsRemoteNotificationKey];
	//we get this if we were launched by an alert
	if( remoteNotif ) {
		NSLog( @"%@", remoteNotif );
		NSString* urlString = [[remoteNotif objectForKey: @"nti"] objectForKey: @"url"];
		if( urlString ) {
			url = [NSURL URLWithString: urlString];
			[self application: app openURL: url sourceApplication: nil annotation: nil];
		}
	}

    return url == nil || NTIUrlCanHandleScheme( url );
}


-(void)application: (UIApplication*)app didRegisterForRemoteNotificationsWithDeviceToken: (NSData*)devToken 
{
	[[NTIAppUser appUser] registerDeviceForRemoteNotification: devToken];
}

static NSInteger REMOTE_SIM = 3010;
static NSString* REMOTE_SIM_END_WARN = @"simulator";

-(void)application: (UIApplication*)app didFailToRegisterForRemoteNotificationsWithError: (NSError*)err 
{
	if(		err.code == REMOTE_SIM
	   &&	[[err.userInfo objectForKey: NSLocalizedDescriptionKey] hasSuffix: REMOTE_SIM_END_WARN] ) {
		NSLog( @"Ignoring notification error in simulator. %@", [err toPropertyList]);	
	}
	else {
	    NTI_PRESENT_ALERT( err );
	}
}

-(void)application: (UIApplication*)app didReceiveRemoteNotification: (NSDictionary*)userInfo
{
	NSNotification* localNotif
		= [NSNotification notificationWithName: NTINotificationRemoteNotificationRecvName
										object: self
									  userInfo: userInfo];
									  
	[[NSNotificationCenter defaultCenter] postNotification: localNotif];
}


-(BOOL)application: (UIApplication*)application
		   openURL: (NSURL*)url
 sourceApplication: (NSString*)sourceApplication
		annotation: (id)annotation
{
	if( !NTIUrlCanHandleScheme( url ) ) {
		return NO;
	}
	[[self topViewController] goToUrl: url];
	return YES;
}

+(void)presentContinuableError: (NSError*)error
						  file: (const char*)file
						  line: (NSInteger)line;
{
#ifdef DEBUG
	dispatch_async( dispatch_get_main_queue(), ^{
		[self presentError: error file: file line: line];
	});
#endif
}

#pragma mark OUIAppController subclass
-(NTIApplicationViewController*)topViewController
{
	return (id)self.window.rootViewController;
}

-(NTIApplicationViewController*)ntiAppViewController
{
	return [self topViewController];	
}


-(void) applicationDidEnterBackground:(UIApplication *)application
{
	/*
	 Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	 If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	 */
	[[NSUserDefaults standardUserDefaults] synchronize];
}

-(void) applicationWillTerminate:(UIApplication *)application
{
	[[NSUserDefaults standardUserDefaults] synchronize];
}

-(void) dealloc
{
	self.window = nil;
	[super dealloc];
}

@end

