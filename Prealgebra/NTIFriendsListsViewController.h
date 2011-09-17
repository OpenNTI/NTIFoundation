//
//  NTIFriendsListsViewController.h
//  NextThoughtApp
//
//  Created by Jason Madden on 2011/08/09.
//  Copyright (c) 2011 NextThought. All rights reserved.
//

#import "NTIViewController.h"
#import "NTILabeledGridListView.h"


//Should be displayed inside a UINavigationViewController
@interface NTIFriendsListsViewController : NTIViewController {
	@private 
	id nr_currentFriendsListsViewInActionSheet;
	CGRect currentFriendListViewFrame;
}
-(id)init;
@end

@interface NTIFriendsListsGridView : NTILabeledGridListView {
	@package
}
@end


@class NTIFriendsList;
@interface NTISharingTargetGridItemView : NTIGridItemView
@end

@interface NTIFriendsListGridItemView : NTISharingTargetGridItemView {
}

-(id)initWithFrame: (CGRect)frame
	   friendsList: (NTIFriendsList*)friendsList;
@end


@interface NTIFriendsListGridView : NTILabeledGridListView {
}
@end

@interface NTIFriendGridItemView : NTISharingTargetGridItemView {
}

-(id)initWithFrame: (CGRect)frame
			  user: (id)user;
@end


