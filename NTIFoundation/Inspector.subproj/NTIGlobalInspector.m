//
//  NTIGlobalInspector.m
//  NTIFoundation
//
//  Created by Christopher Utz on 1/27/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIGlobalInspector.h"
#import "OmniUI/OUIAppController.h"
#import "NTIInspectableController.h"

@implementation NTIGlobalInspector
@synthesize shownFrom;

static UIResponder* findFirstResponderBeneathView(UIView* startAt)
{
	if(startAt.isFirstResponder){
		return startAt;
	}
	
	UIResponder* firstResponder = nil;
	for(UIView* child in startAt.subviews){
		firstResponder = findFirstResponderBeneathView( child );
		if(firstResponder){
			break;
		}
	}
	return firstResponder;
}

static UIResponder* findFirstResponder()
{
	return findFirstResponderBeneathView([[OUIAppController controller] window]);
}

-(void)inspectObjectsFromBarButtonItem:(UIBarButtonItem *)item
{
	//Starting from the first responder look up the responder chain for people
	//implementing NTIInspectableController.  When/if we find them get the inspectable
	//objects from them.  
	
	//TODO what do we do if there is no first responder?  Maybe we hook this into the topNavLayer
	self->shownFrom = findFirstResponder();
	
	if(!self->shownFrom){
		NSLog(@"No first responder to start searching from");
		return;
	}
	
	NSMutableSet* objects = [[NSMutableSet alloc] initWithCapacity: 3];
	
	UIResponder* responder = self->shownFrom;
	do{
		if( [responder respondsToSelector: @selector(inspectableObjects)] ){
			[objects unionSet: [(id)responder inspectableObjects]];
		}
		
		responder = responder.nextResponder;
	}while(responder);
	
	[self->shownFrom resignFirstResponder];
	[self inspectObjects: [objects allObjects] fromBarButtonItem: item];
}

@end
