//
//  NTINavigation.h
//  Prealgebra
//
//  Created by Jason Madden on 2011/06/02.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <dispatch/dispatch.h>

@class NTINavigationItem;
@class NTINavigationParser;
@class WebAndToolController;


//TODO: I don't like this being public
@interface NTINavigationTableViewController : UITableViewController {
	@package
    NTINavigationItem* item;
	WebAndToolController* controller;
}

+(void)configureTableViewCell: (UITableViewCell*)cell
			forNavigationItem: (id)navItem
				 actionTarget: (id)target;

@property(readonly,nonatomic) UITableViewCell* selectedCell;

- (id)initWithStyle: (UITableViewStyle)style 
			   item: (NTINavigationItem*)item
		 //Weak reference
		 controller: (WebAndToolController*)c;

-(id)navigateTo: (NSUInteger)row;
-(void)prepareToDisplayNavigationToPageID: (NSString*)page;

@end


@class NTINavigationRowTableViewController;
@class NTIHistoryController;
@class NTIScrubBarView;

@interface NTINavigationRowController : UIViewController {
@private
    NTINavigationItem* root;
	UIButton* backButton;
	UIButton* forwardButton;
	NTINavigationRowTableViewController* leftmost;
	
	NTIHistoryController* backForwardTVC;
	
	NTIScrubBarView* scrubBar;
	CGFloat percentThroughForNav;
}

@property(nonatomic, retain) NTINavigationItem* root;
@property(nonatomic, retain) IBOutlet UIButton* backButton;
@property(nonatomic, retain) IBOutlet UIButton* forwardButton;
@property(nonatomic, retain) IBOutlet NTIScrubBarView* scrubBar;
@property(nonatomic, assign) IBOutlet WebAndToolController* controller;

- (void)displayNavigationToPageID: (NSString*)page;

@end

