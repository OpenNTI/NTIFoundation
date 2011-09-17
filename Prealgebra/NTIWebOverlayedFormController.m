//
//  NTIWebOverlayedFormController.m
//  Prealgebra
//
//  Created by Christopher Utz on 7/7/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "TestAppDelegate.h"
#import "NTIApplicationViewController.h"
#import "NTIWebOverlayedFormController.h"
#import "WebAndToolController.h"
#import "NTIWebView.h"
#import "UIWebView-NTIExtensions.h"
#import "NSArray-NTIExtensions.h"
#import "NSArray-NTIJSON.h"
#import "NSDictionary-NTIJSON.h"
#import "OmniFoundation/NSString-OFExtensions.h"
#import <QuartzCore/CATransform3D.h> 
#import <QuartzCore/CALayer.h>
#import <NTIMathKeyboardTouch/NTIMathKeyboardTouch.h>
#import "NTITapCatchingGestureRecognizer.h"
#import "NTIUtilities.h"

@interface NTIOverlayView: UIView
@end

@implementation NTIOverlayView

-(UIView*)hitTest: (CGPoint)point
		withEvent: (UIEvent*)event
{
	//For hit testing, we must add the scroll view's content offset.
	//Nobody knows why. -CUTZ Turns out its not actually needed anymore.
	//CGPoint hitPoint = [self.window convertPoint: point
	//									  toView: self];
	CGPoint hitPoint = point;
	//hitPoint.y -= [(UIScrollView*)self.superview contentOffset].y;
	UIView* result = [super hitTest: hitPoint
						  withEvent: event];
	
	if( [self.subviews indexOfObject: result] != NSNotFound ) {
		return result;
	}
	
	UIView* superView = [self superview];
	
	[self removeFromSuperview];
	
	result = [superView hitTest: point withEvent: event];
	
	[superView addSubview: self];
	
	return result;
}


@end


@interface NTIMathTextField : UITextField {
	@private
	BOOL hasBeenFirstResponder;
}
@property (nonatomic, retain) NSString* webId;
@property (nonatomic, retain) UIViewController* keyboardController;
@property (nonatomic, retain) NTIMathKeyboardAccessoryViewController* accController;
@property (nonatomic, retain) id numberBarController;

@end


@implementation NTIMathTextField
@synthesize keyboardController, accController, webId, numberBarController;
-(id)init
{
	self = [super init];
	self.numberBarController = [NTIMathAccessory keyboardAccessoryViewWithDelegate: self];
	self.inputAccessoryView = [self.numberBarController view];
	
	self.adjustsFontSizeToFitWidth = YES;
	self.minimumFontSize = 8.0;
	self.font = [UIFont systemFontOfSize: 24.0];
	
	return self;
}

-(BOOL)canBecomeFirstResponder
{
	return YES;	
}

#pragma mark -
#pragma mark Keyboard Delegate.

-(void)hideKeyboard
{
	[self resignFirstResponder];
}

-(void)keyPressed: (NSString*)keyValue
{
	if( self.inputAccessoryView ) {
		self.text = [self.text stringByAppendingString: keyValue];
	}
	else {
		[self.accController accessoryTextFieldShouldUpdate: keyValue];
	}
}

-(void)showRegularKeyboard
{
	self.inputView = nil;
	
	self.numberBarController = [NTIMathAccessory keyboardAccessoryViewWithDelegate: self];
	self.inputAccessoryView = [self.numberBarController view];
	[self reloadInputViews];
}

-(void)showMathKeyboard
{
	//Set back to the math keyboard
	self.inputView = self.keyboardController.view;
	self.inputAccessoryView = nil;
	[self reloadInputViews];
}

-(void)submitAccessoryInputs: (NSString*)inputs
{
	self.text = inputs;
}

-(void)dealloc
{
	self.numberBarController = nil;
	self.keyboardController = nil;
	self.accController = nil;
	[super dealloc];
}

@end

@interface NTIWebOverlayedFormController()
-(NTIWebView*)webview;
-(void)_fontDidChange: (id)notification;
-(void)_layoutWidgets;
-(void)_layoutInputWidgets: (NSArray*)inputs
			 submitWidgets: (NSArray*)submits
				  intoView: (UIView*)view;
@end

@implementation NTIWebOverlayedFormController

@synthesize inputsSelector;
@synthesize submitSelector;

-(id)initWithInputsSelector: (NSString*)_inputsSelector
			 submitSelector: (NSString*)_submitSelector
{
	self = [super init];
	self.inputsSelector = _inputsSelector;
	self.submitSelector = _submitSelector;
	
	return self;
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	self.inputsSelector = nil;
	self.submitSelector = nil;
	NTI_RELEASE( self->textFields );
	NTI_RELEASE( self->submitButton );
	[super dealloc];
}


-(NTIWebView*)webview
{
	return [[[[TestAppDelegate sharedDelegate] topViewController] webAndToolController] webview];
}

-(void)loadView
{
	NTIWebView* webview = [self webview];
	
	NTI_RELEASE( self->textFields );
	NTI_RELEASE( self->submitButton );
	self->textFields = [[NSMutableArray arrayWithCapacity: 10] retain];
	
	NSArray* webInputs = [[self webview] htmlObjects: [self inputsSelector]];
	NSArray* webSubmitButtons = [webview htmlObjects: [self submitSelector]];
	
	UIView* view;
	
	//If we have no inputs or we have no submit button we return nil
	if( [NSArray isEmptyArray: webInputs] || [NSArray isEmptyArray: webSubmitButtons] ) {
		view = nil;
	}
	else {
		//We need to re-layout when fonts change, so register for that
		//notification
		[[NSNotificationCenter defaultCenter]
			addObserver: self
		 selector: @selector(_fontDidChange:)
		 name: NTINotificationWebViewFontDidChangeName
		 object: webview];
	
		CGRect frame;
		frame.origin = CGPointZero;
		frame.size = webview.scrollView.contentSize;
		view = [[[NTIOverlayView alloc] initWithFrame:
				 //[webview htmlContentRect]]
				 frame]
				autorelease];
		[view setClipsToBounds: YES];
		[self _layoutInputWidgets: webInputs
					submitWidgets: webSubmitButtons
						 intoView: view];
		
		[webview disableAndMakeTransparentObjects: self.inputsSelector];
		[webview disableAndHideSubmit: self.submitSelector];

	}
	
	self.view = view;
		
}

-(void)_layoutInputWidgets: (NSArray*)webInputs
			 submitWidgets: (NSArray*)webSubmitButtons
				  intoView: (UIView*)view
{
	NSUInteger webInputsCount = webInputs.count;
	if( [NSArray isEmptyArray: self->textFields] ) {
		//If we have none, pre-create.
		//Otherwise, we're re-laying out the ones we have, which means
		//that we want to preserve any existing inputs.
		NTI_RELEASE( self->textFields );
		self->textFields = [[NSMutableArray alloc] initWithCapacity: webInputsCount];
		for( id obj in webInputs ) {
			[self->textFields addObject: [[[NTIMathTextField alloc] init] autorelease]];
		}
	}
	
	for( NSUInteger i = 0; i < webInputsCount; i++ ) {
		NTIHTMLObject* obj = [webInputs objectAtIndex: i];
		NTIMathTextField* field = [self->textFields objectAtIndex: i];
		
		field.webId = obj.htmlId;
		
		CGRect frame = obj.frame;
		frame.origin.y -= 4;
		frame.size.height += 4;
		field.frame = frame;
		field.adjustsFontSizeToFitWidth = YES;
		field.font = [field.font fontWithSize: 12.0];
		field.borderStyle = UITextBorderStyleRoundedRect;

		if( !field.window ) {
			//Put in the view if necessary.
			[view addSubview: field];
		}
	}
	
	//On the mathcounts pages we expect one
	if( ![NSArray isEmptyArray: webSubmitButtons] ) {
		if( !self->submitButton ) {
			self->submitButton = [[UIButton buttonWithType: UIButtonTypeRoundedRect] retain];
		}
		
		NTIHTMLObject* webSubmitButton = webSubmitButtons.firstObject;
		CGRect frame = webSubmitButton.frame;
		NSLog(@"%@", NSStringFromCGRect(frame));
		
		self->submitButton.frame = frame;
		[self->submitButton setTitle: @"Submit" 
							forState: UIControlStateNormal];
		
		[submitButton addTarget: self
						 action: @selector(submitForm:)
			   forControlEvents: UIControlEventTouchUpInside];
		if( !self->submitButton.window ) {
			[view addSubview: self->submitButton];
		}
	}
}

-(void)_layoutWidgets
{
	NSArray* webInputs = [[self webview] htmlObjects: [self inputsSelector]];
	NSArray* webSubmitButtons = [[self webview] htmlObjects: [self submitSelector]];
	
	UIView* view = self.view;
	[self _layoutInputWidgets: webInputs
				submitWidgets: webSubmitButtons
					 intoView: view];
}

-(void)_fontDidChange: (id)notification
{
	[self _layoutWidgets];
}

-(void)submitForm: (id)sender
{

	NSMutableDictionary* answers = [[[NSMutableDictionary alloc] 
									 initWithCapacity: [self->textFields count]]
									autorelease];
	
	//Gather up all the answers by enumerating the textviews on the page
	for( NTIMathTextField* input in self->textFields ) {
		NSString* text = [input text];
		if( [NSString isEmptyString: text] ) {
			text = @"";
		}
		[answers setObject: text forKey:[input webId]];
	}
	NSString* result = [[self webview] callFunction: @"NTISubmitOverlayedForm"
										   withJson: [answers stringWithJsonRepresentation]
										  andString: [self inputsSelector]
										  andString: [self submitSelector]];
	if( ![result javascriptBoolValue] ) {
		//TODO: A dialog? How can we display an error?
		NSLog( @"Failed to submit form data." );
	}
	else {
		//On submission, we want to take out all the text fields that are now useless
		//so they don't clutter the page. Their layout may be wrong as well, now.
		
		for( NTIMathTextField* input in self->textFields ) {
			[input removeFromSuperview];
		}
		NTI_RELEASE( self->textFields );
		[[self webview] hideAndMakeZeroSizeObjects: self.inputsSelector];
		//Also disable the submit button, but leave it in place
		//so it is clearly disabled.
		//TODO: Make this a "reset" button?
		//[self->submitButton setEnabled: NO];
		//NOTE: We don't do the above because all our positions become invalid
		[self->submitButton removeFromSuperview];
		NTI_RELEASE( self->submitButton );
	}
}


#pragma mark - View lifecycle

-(BOOL)shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

-(void)didRotateFromInterfaceOrientation: (UIInterfaceOrientation)fromInterfaceOrientation
{
	[super didRotateFromInterfaceOrientation: fromInterfaceOrientation];
	[self _layoutWidgets];
}

@end
