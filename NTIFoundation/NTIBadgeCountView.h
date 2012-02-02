//
//  NTIBadgeCountView.h
//  NTIFoundation
//
//  Created by Christopher Utz on 2/2/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NTIBadgeCountView : UIView{
	@private
	NSUInteger count;
}

-(id)initWithCount: (NSUInteger)c andFrame: (CGRect)frame;

@end
