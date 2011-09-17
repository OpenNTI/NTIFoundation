
#import <UIKit/UIKit.h>


/**
 * The name of the notification emitted for tap-and-hold
 * events.
 */
extern NSString* const NTINotificationTapAndHoldName;

/**
 * This window catches tap-and-hold events and turns them
 * into notifications.
 */
@interface NTIWindow : UIWindow 
{
	CGPoint tapLocation;
	NSTimer* contextualMenuTimer;
	CGPoint fingerDownLocation, touchResetLocation;
}

+(CGPoint)windowPointFromNotification: (NSNotification*)notification;
+(void)addTapAndHoldObserver: (id)obs selector: (SEL)sel object: (id)obj;

+(CGFloat)distanceBetween: (CGPoint)newLocation and: (CGPoint)oldLocation;

/**
 * The location in the window coordinates.
 */
@property(nonatomic,readonly) CGPoint tapLocation;
@end

@interface NTISearchBar : UISearchBar {

}

@end
