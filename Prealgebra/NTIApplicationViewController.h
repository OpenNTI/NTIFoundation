//
//  NTIApplicationViewController.h
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/04.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NTIParentViewController.h"
#import "OmniBase/OmniBase.h"

@class WebAndToolController;
@class NTILibraryViewController;
@class NTINavigationItem;

@interface NTIApplicationViewController : NTIParentViewController {
	@private
	UISplitViewController* bookController;
	NTILibraryViewController* libraryController;
	UIViewController* topViewController;
}
@property (nonatomic,readonly) WebAndToolController* webAndToolController;
@property (nonatomic,readonly) UIViewController* topViewController;
-(void)goHome;
-(void)goWeb;
-(void)goToItem: (NTINavigationItem*)item;
-(void)goToUrl: (NSURL*)url;
@end
