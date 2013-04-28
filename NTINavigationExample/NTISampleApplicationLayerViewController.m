//
//  NTISampleApplicationLayerViewController.m
//  NTIFoundation
//
//  Created by Christopher Utz on 1/19/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTISampleApplicationLayerViewController.h"
#import "NTISampleTransientLayerViewController.h"

@implementation NTISampleApplicationLayerViewController
@synthesize popSelfButton;
@synthesize titleLabel;
@synthesize pushAppLayerButton;
@synthesize pushTransientLayerButton;
@synthesize nextTitleField;

-(id)initWithTitle: (NSString*)t;
{
    self = [super initWithNibName: @"NTISampleApplicationLayerViewController" bundle: nil];
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

-(void)viewWillDisappear:(BOOL)animated
{
	NSLog(@"View will disappear %@", self);
	[super viewWillDisappear: animated];
}

-(void)viewDidDisappear:(BOOL)animated
{
	NSLog(@"View did disappear %@", self);
	[super viewDidDisappear: animated];
}

-(void)viewDidAppear:(BOOL)animated
{
	NSLog(@"view did appear %@", self);
	[super viewDidAppear: animated];
}

-(void)viewWillAppear:(BOOL)animated
{
	NSLog(@"view will appear %@", self);
	[super viewWillAppear: animated];
}


@end
