//
//  NTINoteInspectorSlice.m
//  NextThoughtApp
//
//  Created by Christopher Utz on 8/11/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTISharingTargetsInspectorSlice.h"
#import "NTIUtilities.h"
#import "OmniUI/OUIEditableFrame.h"
#import "NTIRTFTextViewController.h"
#import "OmniUI/OUIDetailInspectorSlice.h"
#import "OmniUI/OUISingleViewInspectorPane.h"
#import "NTISharingController.h"
#import "NTISharingUtilities.h"
#import "NTIUserData.h"
#import "OmniUI/OUIInspector.h"
#import "NTISharingUtilities.h"
#import "NTIWebContextFriendController.h"
#import "NTIArraySubsetTableViewController.h"

#import "NSArray-NTIExtensions.h"

@implementation NTISharingTargetsInspectorModel
@synthesize sharingTargets, readOnly;

-(id)init 
{
    self = [super init];
    self.sharingTargets = [NSArray array];
	self.readOnly = NO;
    return self;
}

-(id)initWithTargets: (NSArray *)targets readOnly: (BOOL)rOnly
{
	self = [super init];
    self.sharingTargets = targets ? targets : [NSArray array];
	self.readOnly = rOnly;
    return self;
}

-(void)dealloc
{
	NTI_RELEASE(self->sharingTargets);
	[super dealloc];
}

@end


@class NTISharingTargetsInspectorSlice;

@interface NTISharingTargetsInspectorPane : OUISingleViewInspectorPane{
@private
	NTIArraySubsetTableViewController* sharingController;
}
@property (nonatomic, assign) NSString* title;
-(id)initWithSharingTargets: (NSArray*)targets;
@end

@implementation NTISharingTargetsInspectorPane
@synthesize title;
-(id)initWithSharingTargets:(NSArray *)targets
{
	self = [super init];
	self->sharingController = [[NTIArraySubsetTableViewController alloc] initWithAllObjects: targets];
	self->sharingController.delegate = self;
	[self configureTableViewBackground: self->sharingController.tableView];
	[self setView: [self->sharingController view]];
	self.title = @"Shared With";
	return self;
}

-(void)sharingTargetsChanged: (NSArray*)targets
{
	NTISharingTargetsInspectorSlice* slice = (NTISharingTargetsInspectorSlice*)[self parentSlice];
	[slice setSharingTargets: targets];
}

-(void)dealloc {
    NTI_RELEASE(self->sharingController);
    [super dealloc];
}

-(void)subset: (id)_ configureCell: (UITableViewCell*)cell forObject: (id)object
{
	[NTIWebContextFriendController configureCell: cell forSharingTarget: object];
}

-(UITableViewCellAccessoryType)subset: (id)_ accessoryTypeForObject: (NTISharingTarget*)target
{
	return UITableViewCellAccessoryCheckmark;
}
@end



@interface NTIEditSharingTargetsInspectorPane : OUISingleViewInspectorPane<NTISharingControllerDelegate>{
@private
	NTISharingController* sharingController;
}
@property (nonatomic, assign) NSString* title;
-(id)initWithSharingTargets: (NSArray*)targets;
@end

@implementation NTIEditSharingTargetsInspectorPane
@synthesize title;
-(id)initWithSharingTargets:(NSArray *)targets
{
	self = [super init];
	self->sharingController = [[NTISharingController alloc] initWithSharingTargets: targets];
	self->sharingController.delegate = self;
	self.title = @"Sharing";
	for( id o in self->sharingController.allSubviewControllers ) {
		if( [o respondsToSelector: @selector(tableView)] ) {
			[self configureTableViewBackground: [o tableView]];
		}
	}
	[self setView: [self->sharingController view]];
	return self;
}

-(void)sharingTargetsChanged: (NSArray*)targets
{
	NTISharingTargetsInspectorSlice* slice = (NTISharingTargetsInspectorSlice*)[self parentSlice];
	[slice setSharingTargets: targets];
}

-(void)dealloc {
    NTI_RELEASE(self->sharingController);
    [super dealloc];
}
@end

@interface NTISharingTargetsInspectorSlice()
//This is only valid when we have determined appropriate objects for inspection.
-(NTISharingTargetsInspectorModel*)modelForSlice;
@end

@implementation NTISharingTargetsInspectorSlice

-initWithTitle: (NSString*)title 
	 paneMaker: (OUIDetailInspectorSlicePaneMaker)paneMaker
{
	//We reset pane maker on update interface from objects
	self = [super initWithTitle: title
					  paneMaker: ^OUIInspectorPane* (OUIDetailInspectorSlice* slice) 
					  {
						  NTISharingTargetsInspectorModel* aModel = [self modelForSlice];
						  if( aModel.readOnly ) {
							  return [[[NTISharingTargetsInspectorPane alloc] 
									  initWithSharingTargets: aModel.sharingTargets]
									  autorelease];
						  }
						  return [[[NTIEditSharingTargetsInspectorPane alloc] 
								  initWithSharingTargets: aModel.sharingTargets] autorelease];
	}];
	self.textWell.style = OUIInspectorTextWellStyleSeparateLabelAndText;
	self.textWell.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	self.textWell.rounded = YES;
	self.textWell.label = @"Sharing";	
	
	return self;
}

-(BOOL)isAppropriateForInspectedObject: (id)object
{
	return [object isKindOfClass: [NTISharingTargetsInspectorModel class]];
}

-(NTISharingTargetsInspectorModel*)modelForSlice
{
	return [[self appropriateObjectsForInspection] lastObjectOrNil];
}

-(void)dealloc 
{
    [super dealloc];
}

-(void)updateInterfaceFromObjects
{
	NTISharingTargetsInspectorModel* aModel = [self modelForSlice];
	if( !aModel ) {
		//Hmm, nothing to inspect yet.
		return;
	}
	
	NTISharingType sharingType = NTISharingTypeForTargets( aModel.sharingTargets );
	
	self.textWell.text = NSStringFromNTISharingType( sharingType );
}


-(void)inspectorWillShow: (OUIInspector*)inspector
{
	//NOTE: On iOS 5, the ViewController has changed such that this
	//method doesn't get fired. Therefore, we also perform these updates in
	//viewWillAppear.
	[self updateInterfaceFromObjects];
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear: animated];
	[self updateInterfaceFromObjects];
}

-(void)setSharingTargets: (NSArray*)targets
{
    NSArray* objects = [self appropriateObjectsForInspection];
	
	for( NTISharingTargetsInspectorModel* model in objects) {
		model.sharingTargets = targets;
	}
	
	[self updateInterfaceFromObjects];
}

@end
