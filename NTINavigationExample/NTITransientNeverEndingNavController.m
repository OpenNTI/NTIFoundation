//
//  NTITransientNeverEndingNavController.m
//  NTIFoundation
//
//  Created by Christopher Utz on 1/19/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTITransientNeverEndingNavController.h"


@implementation NTITransientNeverEndingNavController

-(void)loadView
{
	[super loadView];
	UIButton* button = [UIButton buttonWithType: UIButtonTypeRoundedRect];
	button.titleLabel.text = @"Click Me";
	[button addGestureRecognizer: [[UITapGestureRecognizer alloc] initWithTarget: self action: @selector(clicked:)]];
	button.frame = self.view.bounds;
	button.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	[self.view addSubview: button];
}

-(void)clicked: (UIGestureRecognizer*)rec
{
	if(rec.state == UIGestureRecognizerStateEnded){
		[self.navigationController pushViewController: 
		 [[NTITransientNeverEndingNavController alloc] initWithNibName: nil  
																bundle: nil] animated: YES];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

@end
