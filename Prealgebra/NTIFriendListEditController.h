//
//  NTIFriendListEditController.h
//  NextThoughtApp
//
//  Created by Jason Madden on 2011/08/10.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NTISharingController.h"
@class NTIFriendsList;
@interface NTIFriendListEditController : NTIThreePaneSharingTargetEditor<UISearchBarDelegate> {
	@package
	NTIFriendsList* friendsList;
	id metaController;
}

-(id)initWithFriendsList: (NTIFriendsList*)list;

@end
