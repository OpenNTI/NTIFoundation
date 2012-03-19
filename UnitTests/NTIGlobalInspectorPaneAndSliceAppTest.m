//
//  NTIGlobalInspectorPaneAndSliceAppTest.m
//  NTIFoundation
//
//  Created by Pacifique Mahoro on 3/18/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIGlobalInspectorPaneAndSliceAppTest.h"
#import "NTIGlobalInspectorMainPane.h"
#import "NTIGlobalInspector.h"
#import "NTIInspectorSliceObjectPair.h"
#import <UIKit/UIKit.h>
//#import "application_headers" as required

@interface NTIMockupObj: UIViewController {
@private
	NSArray* objs;
}
@end

@implementation NTIMockupObj
-(id)initWithObjects: (NSArray *)objects
{
	self = [super init];
	if (self) {
		self->objs = objects;
	}
	return self;
}
/*
-(NSArray *)inspectableObjects
{
	NSArray* inspectableTextSpansWrappers = [self->objs arrayByPerformingBlock:^id(id obj) {
		return [[NTIInspectableObjectWrapper alloc] initWithInspectableObject: obj	andOwner: self];
	}];
	
	return inspectableTextSpansWrappers;
}
*/
@end

@interface NTIMockupSlice : NSObject {
	@private
	NSString* title;
}
@end

@implementation NTIMockupSlice
-(id)initWithTitle: (NSString *)inspectorTitle
{
	self = [super init];
	if (self) {
		self->title = inspectorTitle;
	}
	return self;
}

-(BOOL)isAppropriateForInspectedObject:(id)object
{
	return [object isKindOfClass: [NTIMockupSlice class]];
}

@end

@class NTIMockupObj;
@interface NTIWBMockupSlice : NSObject {
@private
	NSString* title;
}
@end

@implementation NTIWBMockupSlice
-(id)initWithTitle: (NSString *)inspectorTitle
{
	self = [super init];
	if (self) {
		self->title = inspectorTitle;
	}
	return self;
}

-(BOOL)isAppropriateForInspectedObject:(id)object
{
	return [object isKindOfClass: [NTIMockupObj class]];
}
@end

@interface NTIGlobalInspectorMainPane(inspectorPaneTest)
-(NSArray *)objectSlicesPairs;
@end

@implementation NTIGlobalInspectorPaneAndSliceAppTest

-(void)setUp
{
	[super setUp];
	self->mainPane = [[NTIGlobalInspectorMainPane alloc] init];
	//Slices
	NTIMockupSlice* slice1 = [[NTIMockupSlice alloc] initWithTitle: @"Content"];
	NTIWBMockupSlice* slice2 = [[NTIWBMockupSlice alloc] initWithTitle: @"WB Content"];
	[NTIGlobalInspector addSliceToGlobalRegistry: slice1];
	[NTIGlobalInspector addSliceToGlobalRegistry: slice2];
}

-(void)testGroupingSlices
{
	NTIMockupObj* obj1 = [[NTIMockupObj alloc] init];
	NTIMockupObj* obj2 = [[NTIMockupObj alloc] init];
	NTIMockupObj* obj3 = [[NTIMockupObj alloc] init];
	
	self->mainPane.inspectedObjects = [NSArray arrayWithObjects: obj1, obj2, obj3, nil];
	//Update the model
	[self->mainPane updateInterfaceFromInspectedObjects: OUIInspectorUpdateReasonDefault];
	NSArray* pairs = [self->mainPane objectSlicesPairs];
	STAssertTrue( [pairs count] == 3, @"we should have 3 inspector pairs");
	STAssertEquals([[pairs objectAtIndex: 0] inspectableObject], obj1, @"Objects should be equal");
	STAssertEquals( [[NTIGlobalInspector globalSliceRegistry] objectAtIndex:1], [[(NTIInspectorSliceObjectPair *)[pairs objectAtIndex: 0] slices] objectAtIndex: 0], @"We should have the same slice");
}

@end
