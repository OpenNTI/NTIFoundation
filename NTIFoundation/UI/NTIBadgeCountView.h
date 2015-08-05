//
//  NTIBadgeCountView.h
//  NTIFoundation
//
//  Created by Christopher Utz on 2/2/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NTIBadgeCountView : UIView{
}

-(id)initWithCount: (NSUInteger)c andFrame: (CGRect)frame;

@property (nonatomic, assign) NSUInteger count;

@property (nonatomic, strong) UIColor* badgeColor;
@property (nonatomic, strong) UIColor* borderColor;
@property (nonatomic, strong) UIFont* font;
@property (nonatomic, strong) UIColor* textColor;

@end
