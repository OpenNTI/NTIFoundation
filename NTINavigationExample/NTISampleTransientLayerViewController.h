//
//  NTISampleTransientLayerViewController.h
//  NTIFoundation
//
//  Created by Christopher Utz on 1/19/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIFoundation/NTIFoundation.h"

@interface NTISampleTransientLayerViewController : UIViewController<NTIAppNavigationTransientLayer>{
	@private
	NSString* title;
}
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UIButton *pushAppLayerButton;
@property (strong, nonatomic) IBOutlet UIButton *pushTransientLayerButton;
@property (strong, nonatomic) IBOutlet UIButton *popSelfButton;
@property (strong, nonatomic) IBOutlet UITextField *nextTitleField;

-(id)initWithTitle: (NSString*)title;
@end
