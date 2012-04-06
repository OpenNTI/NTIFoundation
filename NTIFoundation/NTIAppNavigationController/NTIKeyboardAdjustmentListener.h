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

-(BOOL)adjustLayoutInResponseToKeyboardWillShow: (NSNotification *)aNotification 
								firstResponder: (UIResponder *)responder;
-(BOOL)adjustLayoutInResponseToKeyboardWillHide: (NSNotification *)aNotification 
								 firstResponder: (UIResponder *)responder;
-(BOOL)adjustLayoutInResponseToKeyboardWillChangeFrame: (NSNotification *)aNotification 
								 firstResponder: (UIResponder *)responder;
-(id)canHandleKeyboardNotificationsForResponder: (UIResponder *)responder;
@end
