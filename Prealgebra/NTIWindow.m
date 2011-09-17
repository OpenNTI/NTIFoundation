

#import "NTIWindow.h"

//0.8 is clearly too long
#define LONG_TAP_TIME 0.7f
#define SHORT_TAP_TIME 0.4f

#define VERY_CLOSE 5.0f
#define MEDIUM_CLOSE 30.0f

NSString* const NTINotificationTapAndHoldName = @"NTITapAndHoldNotification";

@interface NTIWindow()
-(void)tapAndHoldAction:(NSTimer*)sender;
@end

@implementation NTIWindow

@synthesize tapLocation = tapLocation;

+(CGPoint)windowPointFromNotification: (NSNotification*)notification
{
	CGPoint pt;
	NSDictionary* coord = notification.userInfo;
	pt.x = [[coord objectForKey: @"x"] floatValue];
	pt.y = [[coord objectForKey: @"y"] floatValue];
	return pt;
}

+(void)addTapAndHoldObserver: (id)obs selector: (SEL)sel object: (id)obj
{
	[[NSNotificationCenter defaultCenter] 
	 addObserver: obs
	 selector: sel
	 name: NTINotificationTapAndHoldName
	 object: nil];
}

-(void)installTimer: (CGFloat)time
{
	[contextualMenuTimer invalidate];
	contextualMenuTimer = [NSTimer scheduledTimerWithTimeInterval: time
														   target: self 
														 selector: @selector(tapAndHoldAction:)
														 userInfo: nil repeats: NO];	
}

+(CGFloat)distanceBetween: (CGPoint)newLocation and: (CGPoint)oldLocation
{
	CGFloat x = newLocation.x - oldLocation.x;
	CGFloat y = newLocation.y - oldLocation.y;
	
	return sqrtf( x*x + y*y );
}

static BOOL isCloseWithin( CGPoint newLocation, CGPoint oldLocation, CGFloat threshold )
{
	CGFloat distance = [NTIWindow distanceBetween: newLocation and: oldLocation];
	return distance <= threshold;
}

- (void)tapAndHoldAction:(NSTimer*)timer
{
	if( touchResetLocation.x >= 0 && touchResetLocation.y > 0 ) {
		//We touched then slid. If we've held still long enough,
		//though, we want to start the timer again. How long of a delay
		//depends on how big of a move
		CGFloat timerDelay;
		if( isCloseWithin( touchResetLocation, fingerDownLocation, VERY_CLOSE ) ) {
			timerDelay = SHORT_TAP_TIME;
		}
		else {
			timerDelay = LONG_TAP_TIME;
		}
		fingerDownLocation = touchResetLocation;
		tapLocation = touchResetLocation;
		touchResetLocation.x = -1;
		touchResetLocation.y = -1;
		[self installTimer: timerDelay ];
	}
	else {
		contextualMenuTimer = nil;
		NSDictionary* coord = [NSDictionary dictionaryWithObjectsAndKeys:
							   [NSNumber numberWithFloat: tapLocation.x], @"x",
							   [NSNumber numberWithFloat: tapLocation.y], @"y",
							   nil];
		[[NSNotificationCenter defaultCenter]
		 postNotificationName: @"NTITapAndHoldNotification" 
		 object: self
		 userInfo: coord];
	}
}



- (void)sendEvent: (UIEvent*)event
{
	NSSet* touches = [event touchesForWindow: self];
	[touches retain];
	
	//Update the location /now/ so it can be used in event handling
	if( [touches count] == 1 ) {
		UITouch* touch = [touches anyObject];
		if( [touch phase] == UITouchPhaseBegan ) {
			tapLocation = [touch locationInView: self];
		}
	}
	
	[super sendEvent: event]; //Call super to make sure the event is processed as usual
	
	if( [touches count] == 1 ) { //We're only interested in one-finger events
		UITouch* touch = [touches anyObject];
		
		switch( [touch phase] ) {
			case UITouchPhaseBegan: 
				//A finger touched the screen
				fingerDownLocation = tapLocation;
				touchResetLocation.x = touchResetLocation.y = -1;
				[self installTimer: LONG_TAP_TIME];
			break;
			case UITouchPhaseStationary:
				//No-op
			break;
				
			case UITouchPhaseMoved:
				//There are some times when the system fires very
				//small move events even when the user is not
				//actually moving his finger. The system tap recognizers deal
				//with this in order to recognize a long press. We 
				//attempt to do the same: A move doesn't cancel an outstanding timer
				//if it's still close to the original location
				if( isCloseWithin( [touch locationInView: self], fingerDownLocation, VERY_CLOSE ) ) {
					break;
				}
				else { //if( isCloseWithin( [touch locationInView: self], fingerDownLocation, MEDIUM_CLOSE ) ) {
					touchResetLocation = [touch locationInView: self];
					break;
				}
			case UITouchPhaseEnded:
			case UITouchPhaseCancelled:
				[contextualMenuTimer invalidate];
				contextualMenuTimer = nil;
			break;
		}
	}
	else { //Multiple fingers are touching the screen
		[contextualMenuTimer invalidate];
		contextualMenuTimer = nil;
	}
	[touches release];
}

@end

@implementation NTISearchBar

- (void) setShowsScopeBar:(BOOL) show
{
	[super setShowsScopeBar: YES]; //always show!
}

@end
