//
//  NTIKeyboardAdjustmentListener.h
//  NTIFoundation
//
//  Created by Pacifique Mahoro on 4/2/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol NTIKeyboardAdjustmentListener <NSObject>
@optional
-(void)adjustViewsForKeyboardToBeShown: (NSNotification *)notification at: (id)touchPointValue;
-(void)adjustViewsForKeyboardToBeHidden: (NSNotification *)notification from: (id)touchPointValue;
-(void)adjustViewsForKeyboardFrameChange: (NSNotification *)notification;
@end
