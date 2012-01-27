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
	//TODO what do we do if there is no first responder?
	UIResponder* firstResonder = findFirstResponder();
	
	if(!firstResonder){
		NSLog(@"No first responder to start searching from");
		return;
	}
	
	NSMutableSet* objects = [[NSMutableSet alloc] initWithCapacity: 3];
	
	do{
		if( [firstResonder respondsToSelector: @selector(inspectableObjects)] ){
			[objects unionSet: [(id)firstResonder inspectableObjects]];
		}
		
		firstResonder = firstResonder.nextResponder;
	}while(firstResonder);
	
	[self inspectObjects: [objects allObjects] fromBarButtonItem: item];
}

@end
