//
//  NTIGlobalInspectorAppTest.m
//  NTIFoundation
//
//  Created by Pacifique Mahoro on 3/15/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIGlobalInspectorAppTest.h"
#import <UIKit/UIKit.h>
#import "NTIGlobalInspectorMainPane.h"
#import "NTIGlobalInspector.h"
#import "NTIInspectorSliceObjectPair.h"
#import "NTIAppNavigationController.h"
#import "NTIFoundation/NTIFoundation.h"
#import "NTIAppDelegate.h"

@interface TestInspectorAppLayer : UIViewController<NTIAppNavigationApplicationLayer>
@property(nonatomic, strong) NSArray* objects;
@end

@implementation TestInspectorAppLayer
@synthesize objects;
-(NSArray *)inspectableObjects
{
	return self->objects;
}
@end

@interface TestInspectorTransLayer : UIViewController<NTIAppNavigationTransientLayer> {
	@private
	NSArray* inspObjects;
}
@property(nonatomic, strong) UITextField* textField;

@end

@implementation TestInspectorTransLayer
@synthesize textField;

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName: nibNameOrNil bundle: nibBundleOrNil];
	if (self) {
		self.textField = [[UITextField alloc] init];
	}
	return self;
}
-(void)viewDidLoad
{
	[self.view addSubview: self.textField];
}
-(void)setObjectToInspect: (NSArray *)objs
{
	self->inspObjects = objs;
}

-(NSArray *)inspectableObjects
{
	return self->inspObjects;
}
@end

@interface NTIAppNavigationController(GlobalInspectorTest)
-(void)searchHierachiesForInspector: (NTIGlobalInspector *)theInspector;
@end

@implementation NTIGlobalInspectorAppTest


-(void)setUp
{
	[super setUp];
	self->mainPane = [[NTIGlobalInspectorMainPane alloc] init];
	self->inspector = [[NTIGlobalInspector alloc] initWithMainPane: self->mainPane height: 400];
	self->appNavController = (NTIAppNavigationController *)[[[NTIAppDelegate sharedDelegate] window] rootViewController];
	self->inspector.delegate = self->appNavController;

}

-(void)testGlobalInspectorOnControllerHierarchy
{
	id transientToPush = [[TestInspectorTransLayer alloc] initWithNibName: nil bundle: nil];
	[transientToPush setObjectToInspect: [NSArray arrayWithObjects: @"Provider Content", @"Whitebaord", @"TextView", nil]];
	[self->appNavController pushLayer: transientToPush animated: NO];
	STAssertTrue([[self->mainPane inspectedObjects] count] == 0, @"No inspectableObjects");
	
	[self->appNavController searchHierachiesForInspector: self->inspector];
	STAssertTrue([[self->mainPane inspectedObjects] count] == 3, @"Expected to have 3 objects to inspect");	
}

-(void)testGlobalInspectorOnResponderChainAndVC
{
	TestInspectorTransLayer* transientToPush = [[TestInspectorTransLayer alloc] initWithNibName: nil bundle: nil];
	[transientToPush setObjectToInspect: [NSArray arrayWithObjects: @"Provider Content", @"Whitebaord", @"TextView", nil]];
	[transientToPush viewDidLoad];
	[self->appNavController pushLayer: transientToPush animated: NO];
	
	[transientToPush.textField becomeFirstResponder];
	STAssertTrue([[self->mainPane inspectedObjects] count] == 0, @"No inspectableObjects");
	
	[self->appNavController searchHierachiesForInspector: self->inspector];
	STAssertTrue([[self->mainPane inspectedObjects] count] == 3, @"Expected to have 3 objects to inspect");
}

-(void)testGlobalInspectorOnAppLayerAndTransLayer
{
	TestInspectorAppLayer* appLayer = [[TestInspectorAppLayer alloc] initWithNibName: nil bundle: nil];
	appLayer.objects = [NSArray arrayWithObjects: @"object1", @"object2", nil];
	
	[self->appNavController pushLayer: appLayer animated: NO];
	[self->appNavController searchHierachiesForInspector: self->inspector];
	STAssertTrue([[self->mainPane inspectedObjects] count] == 2, @"Expected to have 2 objects to inspect");
	STAssertEqualObjects([[self->mainPane inspectedObjects] objectAtIndex: 0], @"object1", @"Expect objects to be equal");
	
	TestInspectorTransLayer* transientToPush = [[TestInspectorTransLayer alloc] initWithNibName: nil bundle: nil];
	[transientToPush setObjectToInspect: [NSArray arrayWithObjects: @"Provider Content", @"Whitebaord", @"TextView", nil]];
		
	[self->appNavController pushLayer: transientToPush animated: YES];
	[self->appNavController searchHierachiesForInspector: self->inspector];
	STAssertTrue([[self->mainPane inspectedObjects] count] == 5, @"Expected to have 5 objects to inspect");
	STAssertEqualObjects([[self->mainPane inspectedObjects] objectAtIndex: 3], @"object1", @"Expect objects to be equal");
	
	//pop the transient layer 
	[self->appNavController popLayerAnimated: YES];
	//pop app layer
	[self->appNavController popLayerAnimated: YES];
}

-(void)testGlobalInspectorAvoidAddingDuplicates
{
	TestInspectorAppLayer* appLayer = [[TestInspectorAppLayer alloc] initWithNibName: nil bundle: nil];
	appLayer.objects = [NSArray arrayWithObjects: @"object1", @"object2", nil];
	[self->appNavController pushLayer: appLayer animated: NO];
	
	TestInspectorTransLayer* transientToPush = [[TestInspectorTransLayer alloc] initWithNibName: nil bundle: nil];
	[transientToPush setObjectToInspect: [NSArray arrayWithObjects: @"Provider Content", @"object1", @"TextView", nil]];
	
	[self->appNavController pushLayer: transientToPush animated: YES];
	[self->appNavController searchHierachiesForInspector: self->inspector];
	STAssertTrue([[self->mainPane inspectedObjects] count] == 4, @"Expected to have 4 objects to inspect");
	STAssertEqualObjects([[self->mainPane inspectedObjects] objectAtIndex: 1], @"object1", @"Expect objects to be equal");
	STAssertEqualObjects([[self->mainPane inspectedObjects] objectAtIndex: 3], @"object2", @"Expect objects to be equal");
	
	//pop the transient layer 
	[self->appNavController popLayerAnimated: YES];
	//pop app layer
	[self->appNavController popLayerAnimated: YES];
}


@end
