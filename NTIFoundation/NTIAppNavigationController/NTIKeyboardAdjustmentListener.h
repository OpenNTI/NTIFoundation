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

-(BOOL)adjustContentOffsetForKeyboardShowNotification: (NSNotification *)aNotification 
												   at: (id)touchPointValue;
-(BOOL)adjustContentOffsetForKeyboardHideNotification: (NSNotification *)aNotification 
												 from: (id)touchPointValue;
-(BOOL)adjustViewsForKeyboardFrameChange: (NSNotification *)notification 
									  at: (id)touchPointValue;
-(id)canHandleKeyboardNotificationsForResponder: (id)responder;
@end
