//
//  NTIWebContextTableController.h
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/04.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "OmniFoundation/OmniFoundation.h"
#import <UIKit/UIKit.h>
#import "NTITwoStateViewControllerProtocol.h"
#import "NTIStackedSubviewViewController.h"

@class WebAndToolController;

@interface NTIWebContextTableController : NTIStackedSubviewViewController {
	@private
	id nr_stuffcontroller;
	id nr_activitycontroller;
	NSTimer* timer;
}

@property(nonatomic,assign) IBOutlet WebAndToolController* webController;

@end
