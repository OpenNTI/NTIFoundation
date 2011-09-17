//
//  NTIWebOverlayedFormController.h
//  Prealgebra
//
//  Created by Christopher Utz on 7/7/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NTIViewController.h"

@interface NTIWebOverlayedFormController : NTIViewController {
@private
	NSMutableArray* textFields;
	UIButton* submitButton;
}

@property (retain, nonatomic) NSString* inputsSelector;
@property (retain, nonatomic) NSString* submitSelector;

- (id)initWithInputsSelector: (NSString*)inputsSelector
			  submitSelector: (NSString*)submitSelector;
- (void)submitForm: (id)sender;
@end
