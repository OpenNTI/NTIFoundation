//
//  NTISampleTransientLayerViewController.m
//  NTIFoundation
//
//  Created by Christopher Utz on 1/19/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTISampleTransientLayerViewController.h"
#import "NTISampleApplicationLayerViewController.h"

@implementation NTISampleTransientLayerViewController
@synthesize titleLabel;
@synthesize pushAppLayerButton;
@synthesize pushTransientLayerButton;
@synthesize popSelfButton;
@synthesize nextTitleField;

-(id)initWithTitle: (NSString*)t;
{
    self = [super initWithNibName: @"NTISampleTransientLayerViewController" bundle: nil];
    if (self) {
        self->title = t;		
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

-(CGFloat)suggestedWidth
{
	return 320;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
	
	titleLabel.text = self->title;
	
	[self->popSelfButton addGestureRecognizer: [[UITapGestureRecognizer alloc] initWithTarget: self
																					   action: @selector(buttonTapped:)]];
	[self->pushAppLayerButton addGestureRecognizer: [[UITapGestureRecognizer alloc] initWithTarget: self
																							action: @selector(buttonTapped:)]];
	[self->pushTransientLayerButton addGestureRecognizer: [[UITapGestureRecognizer alloc] initWithTarget: self
																								  action: @selector(buttonTapped:)]];
}

-(NTIAppNavigationController*)appNavController
{
	return (id)[[[[UIApplication sharedApplication] delegate] window] rootViewController];
}

-(void)buttonTapped: (UIGestureRecognizer*)recognizer
{
	if (recognizer.state == UIGestureRecognizerStateEnded){
		if(recognizer.view == self->popSelfButton){
			[self.ntiAppNavigationController popLayerAnimated: YES];
		}
		else if(recognizer.view == self->pushAppLayerButton){
			NTISampleApplicationLayerViewController* newController = [[NTISampleApplicationLayerViewController alloc] 
																	  initWithTitle: [NSString stringWithFormat: @"appLayer_%@", self.nextTitleField.text]];
			[self.ntiAppNavigationController pushLayer: newController animated: YES];
		}
		else if(recognizer.view == self->pushTransientLayerButton){
			NTISampleTransientLayerViewController* newController = [[NTISampleTransientLayerViewController alloc] 
																	initWithTitle: [NSString stringWithFormat: @"transient_%@", self.nextTitleField.text]];
			[self.ntiAppNavigationController pushLayer: newController animated: YES];
		}
	}
}

- (void)viewDidUnload
{
	[self setTitleLabel:nil];
	[self setPushAppLayerButton:nil];
	[self setPushTransientLayerButton:nil];
	[self setPopSelfButton:nil];
	[self setNextTitleField:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

@end
