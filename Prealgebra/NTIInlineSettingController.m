//
//  NTIInlineSettingController.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/05/30.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTIInlineSettingController.h"
#import "NTIWebView.h"
#import "WebAndToolController.h"
#import <QuartzCore/QuartzCore.h>
#import "NTIAppPreferences.h"


#import <OmniUI/OUIColorAttributeInspectorSlice.h>

#import <OmniUI/OUIColorAttributeInspectorWell.h>
#import <OmniUI/OUIInspectorSelectionValue.h>
#import <OmniQuartz/OQColor.h>
#import <OmniUI/OUIColorInspectorPane.h>
#import "TestAppDelegate.h"
#import "NTIUtilities.h"


@implementation NTIInlineSettingController
@synthesize sizeControl;
@synthesize notesControl;
@synthesize highlightsControl;
@synthesize faceControl;

- (id)initWithNibName:(NSString *)nibNameOrNil
			   bundle:(NSBundle *)nibBundleOrNil
			  webView: (WebAndToolController*)web
{
    self = [super initWithNibName: nibNameOrNil bundle: nibBundleOrNil];
    if( self ) {
		webController = [web retain];
    }
	self.navigationItem.title = @"Settings";
    return self;
}



- (CGSize) contentSizeForViewInPopover
{
	return CGSizeMake( 320, 297 );
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	[sizeControl addTarget: self
					action: @selector(sizeControlChange:) 
		  forControlEvents: UIControlEventValueChanged];
	[notesControl addTarget: self 
					 action: @selector(notesControlChange:) 
		   forControlEvents: UIControlEventValueChanged];
	[highlightsControl addTarget: self 
						  action: @selector(highlightsControlChange:)
				forControlEvents: UIControlEventValueChanged];
	[faceControl addTarget: self 
					action: @selector(faceControlChange:)
		  forControlEvents: UIControlEventValueChanged];
	//FIXME: Assuming things	
	[faceControl setSelectedSegmentIndex:
	 ([@"Palatino" isEqualToString: [[NTIAppPreferences prefs] fontFace]]
	  ? NTI_ISC_TEXT_SERIF
	  : NTI_ISC_TEXT_SANS_SERIF)];

	[notesControl setOn: [[NTIAppPreferences prefs] notesEnabled]];
	[highlightsControl setOn: [[NTIAppPreferences prefs] highlightsEnabled]];
	
	
	CGRect textWellFrame = CGRectMake(90, 215, 195, 37);
    
	self->textWell 
	= [[[OUIColorAttributeInspectorWell alloc] initWithFrame: textWellFrame] autorelease];
	self->textWell.style = OUIInspectorTextWellStyleSeparateLabelAndText;
    self->textWell.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self->textWell.rounded = YES;
    self->textWell.label = @"Highlight Color";
    
    [self->textWell addTarget: nil //Up the responder chain
					   action: @selector(showDetails:)
			 forControlEvents: UIControlEventTouchUpInside];
    [[self.view viewWithTag: 1] addSubview: self->textWell];
	self->textWell.color = [NTIAppPreferences prefs].highlightColor;

	self->selectionValue = [[OUIInspectorSelectionValue alloc] initWithValue: self->textWell.color];
	
}

-(void)showDetails:(id)s
{
	OUIColorInspectorPane* pane = [[[OUIColorInspectorPane alloc] init] autorelease];
	pane.title = self.title;
	pane.parentSlice = (id)self;
	[self.navigationController pushViewController: pane
										 animated: YES];
}

#pragma mark -
#pragma mark Inspector Fake

-(BOOL)allowsNone
{
	return NO;
}

-(id)selectionValue
{
	return selectionValue;	
}

- (void)changeColor:(id)sender;
{
    OBPRECONDITION([sender conformsToProtocol:@protocol(OUIColorValue)]);
    id<OUIColorValue> colorValue = sender;
    
    OQColor* color = colorValue.color;
	[NTIAppPreferences prefs].highlightColor = color;
	NTI_RELEASE( self->selectionValue );
	self->selectionValue = [[OUIInspectorSelectionValue alloc] initWithValue: color];
	self->textWell.color = color;
	[webController.webview setHighlightColor: color];
	[(OUIColorInspectorPane*)self.navigationController.topViewController
	 updateInterfaceFromInspectedObjects: OUIInspectorUpdateReasonObjectsEdited];
}


-(void)segmentSelect: (id)sender
				when: (NSInteger)index
				then: (SEL)then
		   otherwise: (SEL)otherwise
			  saveAt: (NSString*)key
{
	NSString* valueToSave = nil;
	SEL perform =  [sender selectedSegmentIndex] == index
					? then
					: otherwise;

	valueToSave = [webController.webview performSelector: perform];

	if( valueToSave != nil ) {
		[[NTIAppPreferences prefs] setValue: valueToSave forKey: key];
	}
}

- (void)sizeControlChange: (id)sender
{
	[self segmentSelect: sender
				   when: NTI_ISC_TEXT_SMALLER
				   then: @selector(decreaseFontSize)
			  otherwise: @selector(increaseFontSize)
				 saveAt: @"fontSize"];
}

- (void)faceControlChange: (id)sender
{
	[self segmentSelect: sender
				   when: NTI_ISC_TEXT_SERIF
				   then: @selector(serifFont)
			  otherwise: @selector(sansSerifFont)
				 saveAt: @"fontFace"];
}

-(void)toggleString: (NSString*)key control: (UISwitch*)control on: (SEL)on off: (SEL)off
{
	BOOL isOn = [control isOn];
	[[NTIAppPreferences prefs] setValue: [NSNumber numberWithBool: isOn] forKey: key];
	[webController.webview performSelector: isOn ? on : off];
}

- (void)notesControlChange: (id)sender
{
	[self toggleString: @"notesEnabled"
			   control: notesControl
					on: @selector(showNotes)
				   off: @selector(hideNotes)];
}

- (void)highlightsControlChange: (id)sender
{
	[self toggleString: @"highlightsEnabled"
			   control: highlightsControl
					on: @selector(showHighlights)
				   off: @selector(hideHighlights)];
}

#pragma mark -
#pragma mark UIViewController subclass

-(void)viewDidUnload 
{
	NTI_RELEASE( self->sizeControl );
	NTI_RELEASE( self->notesControl );
	NTI_RELEASE( self->highlightsControl );
	NTI_RELEASE( self->faceControl );
	[super viewDidUnload];
}

-(BOOL)canBecomeFirstResponder
{
	return YES;	
}

-(void)viewDidAppear:(BOOL)animated
{
	[self becomeFirstResponder];	
}

-(void)viewWillDisappear: (BOOL)animated
{
	[self resignFirstResponder];
}


- (void)dealloc
{
	NTI_RELEASE( self->webController );
	NTI_RELEASE( self->sizeControl );
	NTI_RELEASE( self->notesControl );
	NTI_RELEASE( self->highlightsControl );
	NTI_RELEASE( self->faceControl );
	[super dealloc];
}

@end
