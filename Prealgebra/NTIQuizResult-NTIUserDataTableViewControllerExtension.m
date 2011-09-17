//
//  NTIQuizResult+NTIUserDataTableViewControllerExtension.m
//  NextThoughtApp
//
//  Created by Jason Madden on 2011/09/08.
//  Copyright (c) 2011 NextThought. All rights reserved.
//

#import "TestAppDelegate.h"
#import "NTIApplicationViewController.h"
#import "WebAndToolController.h"
#import "UIWebView-NTIExtensions.h"
#import "NTIWebView.h"
#import "NTIQuizResult-NTIUserDataTableViewControllerExtension.h"

@implementation NTIQuizResult(NTIUserDataTableViewControllerExtension)

//Return NO if not handled.
-(BOOL)didSelectObject: (id)sender
{
	WebAndToolController* webc = [[TestAppDelegate sharedDelegate] topViewController].webAndToolController;
	[webc.webview callFunction: @"NTIShowAnswers"
					withString: @""
					 andString: self.ID];
	//Take off the input layers, they look bad with our 
	//styling.
	[webc.webview clearOverlayedFormControllers];
	return YES;
}

@end
