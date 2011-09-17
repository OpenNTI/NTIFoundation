//
//  NTIWebContextFriendController.h
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/15.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

#import "NTIViewController.h"
#import "NTIWebContextTableController.h"
#import "NTIArraySubsetTableViewController.h"

@class NTISharingTarget;

/**
 * Anything that can be shared (NTIShareableUserData) can be dropped on us,
 * and we cause it to be shared with the drop target.
 */
@interface NTIWebContextFriendController : NTIArraySubsetTableViewController<NTITwoStateViewControllerProtocol> {
@private
	id maxView;
}

/**
 * Populates the cell with the correct image and text
 * for a sharing target.
 */
+(UITableViewCell*)configureCell: (UITableViewCell*)cell
				forSharingTarget: (NTISharingTarget*)target;

@end
