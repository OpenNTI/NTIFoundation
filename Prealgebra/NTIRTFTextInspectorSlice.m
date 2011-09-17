//
//  NTIRTFTextInspectorSlice.m
//  NextThoughtApp
//
//  Created by Christopher Utz on 8/11/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTIRTFTextInspectorSlice.h"
#import <OmniUI/OUIColorInspectorSlice.h>
#import <OmniUI/OUIFontAttributesInspectorSlice.h>
#import <OmniUI/OUIFontInspectorSlice.h>
#import <OmniUI/OUIParagraphStyleInspectorSlice.h>
#import <OmniUI/OUIStackedSlicesInspectorPane.h>
#import <OmniUI/OUITextColorAttributeInspectorSlice.h>
#import <OmniUI/OUITextExampleInspectorSlice.h>
#import <OmniAppKit/OATextAttributes.h>
#import "NTIUtilities.h"
#import "OmniUI/OUEFTextRange.h"
#import "OmniUI/OUIDetailInspectorSlice.h"
#import "OmniUI/OUIInspectorPane.h"
#import "OmniUI/OUIDetailInspectorSlice.h"



@implementation NTIRTFTextInspectorSlice

-(id)initWithNibName: (NSString*)nibNameOrNil
			  bundle: (NSBundle*)nibBundleOrNil
{
	self = [super initWithTitle: @"Text Decoration" paneMaker: ^OUIInspectorPane*(OUIDetailInspectorSlice* slice) {
		
		OUIStackedSlicesInspectorPane* pane = [[OUIStackedSlicesInspectorPane alloc] init];
		
		//From OUIEditableFrame
		NSMutableArray* slices = [[[NSMutableArray alloc] initWithCapacity: 5] autorelease];
		[slices addObject: [[[OUITextColorAttributeInspectorSlice alloc] 
							 initWithLabel: 
							 	NSLocalizedStringFromTableInBundle(@"Text color", @"OUIInspectors", OMNI_BUNDLE, @"Title above color swatch picker for the text color.")
							 attributeName: OAForegroundColorAttributeName]
							autorelease]];
		[slices addObject: [[[OUITextColorAttributeInspectorSlice alloc]
							 initWithLabel: 
							 	NSLocalizedStringFromTableInBundle(@"Background color", @"OUIInspectors", OMNI_BUNDLE, @"Title above color swatch picker for the text color.")
							 attributeName: OABackgroundColorAttributeName] autorelease]];
		[slices addObject: [[[OUIFontAttributesInspectorSlice alloc] init] autorelease]];
		[slices addObject: [[[OUIFontInspectorSlice alloc] init] autorelease]];
		[slices addObject: [[[OUIParagraphStyleInspectorSlice alloc] init] autorelease]];
		
		pane.availableSlices = slices;
		
		return [pane autorelease];
	}];
	
	return self;
}

-(BOOL)isAppropriateForInspectedObject:(id)object
{
	if( [object shouldBeInspectedByInspectorSlice: self
										 protocol: @protocol(OUIFontInspection)] ){
		return YES;
	}
	
	if(		[object isKindOfClass: [OUEFTextRange class]] 
		&&	[object respondsToSelector: @selector(frame)] ) {
		return YES;
	}
		
	if( [object shouldBeInspectedByInspectorSlice: self
										 protocol: @protocol(OUIParagraphInspection)] ) {
		return YES;
	}
	
	return NO;
}


@end
