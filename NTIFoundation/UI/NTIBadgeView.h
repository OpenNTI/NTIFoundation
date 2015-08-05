//
//  NTIBadgeView.h
//  NTIFoundation
//
//  Created by Christopher Utz on 2/2/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NTIBadgeView : UIView{
}


@property (nonatomic, strong) NSString* badgeText;

@property (nonatomic, strong) UIColor* badgeColor;
@property (nonatomic, strong) UIColor* borderColor;
@property (nonatomic, strong) UIFont* font;
@property (nonatomic, strong) UIColor* textColor;

@end
