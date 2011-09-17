//
//  NTIInspector.m
//  NextThoughtApp
//
//  Created by Christopher Utz on 8/12/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTINoteInspector.h"
#import "OmniUI/OUIAppController.h"
#import "OmniUI/OUIInspectorPane.h"
#import "NTISharingTargetsInspectorSlice.h"
#import "NTIRTFTextInspectorSlice.h"

@implementation NTINoteInspector

+(id)createNoteInspector
{
	return [[[NTINoteInspector alloc] init] autorelease];
}

+(id)createNoteInspectorForEmbeddingIn: (UINavigationController*) controller
{
	NTINoteInspector* inspector = [[[NTINoteInspector alloc]
									initWithNavigationController: controller] autorelease];
	
	return inspector;
}

-(id)init
{
	self = [super init];
	self.delegate = self;
	return self;
}

-(id)initWithMainPane: (OUIInspectorPane *)mainPane
			   height: (CGFloat)height
{
	return [self initWithMainPane: mainPane height: height navgationController: nil];
}

-(id)initWithMainPane: (OUIInspectorPane*)mainPane
			   height: (CGFloat)height
  navgationController: (UINavigationController*)nav
{
	self = [super initWithMainPane: mainPane height: height navgationController: nav];
	self.delegate = self;
	return self;
}

-(BOOL)inspectNoteEditor: (OUIEditableFrame*)editor
			  andSharing: (NTISharingTargetsInspectorModel*)sharingTargets 
	   fromBarButtonItem: (UIBarButtonItem*)barButton
{
	NSMutableArray* toInspect = [NSMutableArray arrayWithObject: sharingTargets];
	
	NSArray* runs = [editor inspectableTextSpans];
    if( runs ){
		[toInspect addObjectsFromArray: runs];
	}
	
	NSLog(@"Inspecting: %@", toInspect);
	return [self inspectObjects: toInspect fromBarButtonItem: barButton];
}

#pragma mark -
#pragma mark OUIInspectorDelegate
// If this is not implemented or returns nil, and the inspector pane doesn't already have a title, an assertion will fire it will be given a title of "Inspector".
// Thus, you either need to implement this or the manually give titles to the panes.
-(NSString*)inspector: (OUIInspector*)inspector
		 titleForPane: (OUIInspectorPane*)pane
{
	return nil;
}

// If this is not implemented or returns nil, and the stacked inspector pane doesn't already have slices, an assertion will fire and the inspector dismissed.
// Thus, you either need to implement this or the manually give slices to the stacked slice panes. If you make slices this way, you must return all the possible slices and have the slices themselves decide whether they are appropriate for the inspected object set.
-(NSArray*)inspector: (OUIInspector*)insp
makeAvailableSlicesForStackedSlicesPane: (OUIStackedSlicesInspectorPane *)pane
{
	NSMutableArray* slices = [NSMutableArray arrayWithCapacity: 2];
	
	NTISharingTargetsInspectorSlice* sharingSlice = [[[NTISharingTargetsInspectorSlice alloc] 
													  initWithTitle: @"" paneMaker: nil] autorelease];
	
	[slices addObject: sharingSlice];
	
	NTIRTFTextInspectorSlice* rtfSlice = [[[NTIRTFTextInspectorSlice alloc] 
										   init] autorelease];
	
	[slices addObject: rtfSlice];
	
	[pane setTitle: @"Note Inspector"];
	
	return slices;
}

// Delegates should normally implement this method to restore the first responder.
- (void)inspectorDidDismiss:(OUIInspector *)inspector;
{
	//TODO Do anything here?
}


@end

