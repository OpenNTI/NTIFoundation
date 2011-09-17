//
//  NTIUserProfileInspectorSlice.h
//  NextThoughtApp
//
//  Created by Jason Madden on 2011/09/03.
//  Copyright (c) 2011 NextThought. All rights reserved.
//

#import "NTIInspector.h"

@interface NTIUserProfileInspectorSlice : OUIInspectorSlice {
	@private
	BOOL elideNavigation;
}
@property (retain, nonatomic) IBOutlet UILabel* realName;
@property (retain, nonatomic) IBOutlet UILabel* userName;
@property (retain, nonatomic) IBOutlet UILabel* lastLogin;
@property (retain, nonatomic) IBOutlet UIImageView* gravatar;
@property (retain, nonatomic) IBOutlet UIView* gravatarBorder;
@end

@interface NTIUserProfileInspectorWell : OUIInspectorWell
@end
