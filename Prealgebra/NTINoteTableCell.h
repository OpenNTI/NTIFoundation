//
//  NTINoteTableCell.h
//  NextThoughtApp
//
//  Created by Christopher Utz on 8/29/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NTINoteTableCell : UITableViewCell {

	UIImageView *sharingImage;
}
@property (nonatomic, retain) IBOutlet UIImageView* sharingImage;
@property (nonatomic, retain) IBOutlet UIImageView* avatarImage;
@property (nonatomic, retain) IBOutlet UIView* textContainer;
@property (nonatomic, retain) IBOutlet UILabel* creatorLabel;
@property (nonatomic, retain) IBOutlet UILabel* lastModifiedLabel;
@end

@interface NTINoteActionTableCell : UITableViewCell {
	
}
@property (nonatomic, readonly) UIToolbar* toolBar;
-(void)setActionItems: (NSArray*)uibarbuttons;

@end
