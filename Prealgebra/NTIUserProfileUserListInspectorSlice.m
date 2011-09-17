//
//  NTIUserProfileUserListInspectorPane.m
//  NextThoughtApp
//
//  Created by Jason Madden on 2011/09/04.
//  Copyright (c) 2011 NextThought. All rights reserved.
//

#import "NTIUserProfileUserListInspectorSlice.h"
#import "NTISelectedObjectsStackedSubviewViewController.h"
#import "NTIAppUser.h"


@interface NTIUserProfileUserListInspectorSlice()<NTISelectedObjectsStackedSubviewViewControllerDelegate>
@end

@implementation NTIUserProfileUserListInspectorSlice

+(OUIInspectorTextWellStyle)textWellStyle
{
	return OUIInspectorTextWellStyleSeparateLabelAndText;
}

-(id)initWithTitle: (NSString*)title key: (NSString*)_key
{
	return [self initWithTitle: title key: _key editable: YES];
}

-(id)initWithTitle: (NSString*)title 
			   key: (NSString*)_key 
			   editable: (BOOL)_editable
{
	[super initWithTitle: title
			   paneMaker: 
	^OUIInspectorPane* (OUIDetailInspectorSlice* slice)
	{
		NTIAppUser* appUser = [slice.containingPane inspectedObjects].firstObject;	
		OUISingleViewInspectorPane* pane = [[OUISingleViewInspectorPane alloc] init];
		NTISelectedObjectsStackedSubviewViewController* view 
		= [[NTISelectedObjectsStackedSubviewViewController alloc]
		   initWithSelectedObjects: [appUser valueForKey: self->key]
		   prefixControllers: nil
		   postfixControllers: nil];
		for( id o in view.allSubviewControllers ) {
			if( [o respondsToSelector: @selector(tableView)] ) {
				[pane configureTableViewBackground: [o tableView]];
				[[o tableView] setUserInteractionEnabled: self->editable];
			}
		}
		if( !self->editable ) {
			view.tableView.tableHeaderView = nil;
		}
		view.delegate = self;
		[pane setView: view.view];
		return pane;
	}];
	self->key = [_key copy];
	self->editable = _editable;
	return self;
}

-(BOOL)isAppropriateForInspectedObject: (id)o
{
	return [o isKindOfClass: [NTIAppUser class]];
}

-(void)updateInterfaceFromInspectedObjects:(OUIInspectorUpdateReason)reason
{
	NTIAppUser* appUser = [self.containingPane inspectedObjects].firstObject;
	NSArray* value = [appUser valueForKey: self->key];
	if( value.count == 1 ) {
		self.textWell.text = [value.firstObject prefDisplayName];
	}
	else if( value.count == 2 ) {
		self.textWell.text = [NSString stringWithFormat: @"%@ and %@ other",
							[value.firstObject prefDisplayName],
							  [NSNumber numberWithInteger: 
							  	[[appUser valueForKey: self->key] count] - 1]];
	}
	else if( value.count > 2 ) {
		self.textWell.text = [NSString stringWithFormat: @"%@ and %@ others",
							  [value.firstObject prefDisplayName],
							  [NSNumber numberWithInteger: 
							  	[[appUser valueForKey: self->key] count] - 1]];
	}
}

-(void)controller: (id)c selectedObjectsDidChange: (NSArray*)selected
{
	//we should never get here if we're not editable, but just to be sure
	if( !self->editable ) {
		return;
	}
	NTIAppUser* appUser = [self.containingPane inspectedObjects].firstObject;	
	[appUser setValue: selected forKey: self->key];
}

-(void)dealloc
{
	NTI_RELEASE( self->key );
	[super dealloc];	
}

@end
