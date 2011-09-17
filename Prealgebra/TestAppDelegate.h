//
//  TestAppDelegate.h
//  Test
//
//  Created by Jason Madden on 2011/05/19.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <UIKit/UIApplication.h>
#import "OmniUI/OUIAppController.h"
@class NTIApplicationViewController;

//The name of the notification we emit when a remote notification 
//arrives. The userinfo portion of the notification
//is the same as that received from the remote notification.
extern NSString* const NTINotificationRemoteNotificationRecvName;


@interface TestAppDelegate : OUIAppController <UIApplicationDelegate> {
}
+ (TestAppDelegate*) sharedDelegate;

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic,readonly) NTIApplicationViewController* ntiAppViewController;

-(NTIApplicationViewController*)topViewController;

/**
 * Callable from any thread. Presents the error to the user in
 * an appropriate way, which may vary in debug and release builds.
 */
+(void)presentContinuableError: (NSError*)error
						  file: (const char*)file
						  line: (NSInteger)line;



@end

#define NTI_PRESENT_ERROR(error) [[[TestAppDelegate sharedDelegate] class] presentContinuableError:(error) file:__FILE__ line:__LINE__]

#define NTI_PRESENT_ALERT(error) [[[TestAppDelegate sharedDelegate] class] presentAlert:(error) file:__FILE__ line:__LINE__]


#ifdef DEBUG
@interface UIView(Debug)
-(id)recursiveDescription;
@end
#endif

