
#import <UIKit/UIKit.h>
#import <OmniFoundation/OmniFoundation.h>
#import "NTIWebContextTableController.h"
#import "NTIArraySubsetTableViewController.h"

@class WebAndToolController;
@class NTINavigationItem;
@class MPMoviePlayerController;

@interface NTIWebContextRelatedController : NTIArraySubsetTableViewController<NTITwoStateViewControllerProtocol> {
	//Things for displaying a movie. Since by definition there can
	//only be one movie playing at a time, these are inherently thread-safe
	//They live and die as a group.
	@private
	MPMoviePlayerController* m;
	NSTimer* mtimer;
	UIToolbar* mtb;
	CGRect mendRect;
	NTINavigationItem* mitem;
}
@property (nonatomic,retain) WebAndToolController* webController;
@property (nonatomic,assign) BOOL miniViewHidden;

-(id)initWithStyle: (UITableViewStyle)style
			   web: (WebAndToolController*)web;
@end
