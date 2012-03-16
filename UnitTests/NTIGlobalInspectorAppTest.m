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

@interface NTIMockupObj: UIViewController {
	@private
	NSArray* objs;
}
@property(nonatomic, strong) UITextField* textField;
@end

@implementation NTIMockupObj
@synthesize textField;
-(id)initWithObjects: (NSArray *)objects
{
	self = [super init];
	if (self) {
		self->objs = objects;
		self.textField = [[UITextField alloc] init];
	}
	return self;
}

-(void)viewDidLoad
{
	[self.view addSubview: self.textField];
}

-(NSArray *)inspectableObjects
{
	return [self->objs arrayByAddingObject:@"Mockup"];
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

-(void)testGlobalInspectorOnMultipleLayers
{
	TestInspectorTransLayer* transientToPush = [[TestInspectorTransLayer alloc] initWithNibName: nil bundle: nil];
	[transientToPush setObjectToInspect: [NSArray arrayWithObjects: @"Provider Content", @"Whitebaord", @"TextView", nil]];
	[self->appNavController pushLayer: transientToPush animated: NO];
	
	[self->appNavController searchHierachiesForInspector: self->inspector];
	STAssertTrue([[self->mainPane inspectedObjects] count] == 3, @"Expected to have 3 objects to inspect");
	
	TestInspectorTransLayer* transientToPush2 = [[TestInspectorTransLayer alloc] initWithNibName: nil bundle: nil];
	[transientToPush2 setObjectToInspect: [NSArray arrayWithObjects: @"Stream", @"Keyboard", nil]];
	[self->appNavController pushLayer: transientToPush2 animated: NO];
	[self->appNavController searchHierachiesForInspector: self->inspector];
	STAssertTrue([[self->mainPane inspectedObjects] count] == 2, @"Expected to have 2 objects to inspect");
	
}

-(void)testGlobalInspectorWithNestedObjects
{
	//TODO: test not finished yet. Still working on it. 
	TestInspectorTransLayer* transientToPush = [[TestInspectorTransLayer alloc] initWithNibName: nil bundle: nil];
	NTIMockupObj* obj = [[NTIMockupObj alloc] initWithObjects: [NSArray arrayWithObjects:@"Object1", @"object2", nil]];
	//Add a new VC
	[transientToPush addChildViewController: obj];
	[obj viewDidLoad];
	
	[transientToPush setObjectToInspect: [NSArray arrayWithObjects: @"Provider Content", @"Whitebaord", nil]];
	[self->appNavController pushLayer: transientToPush animated: NO];
	[obj.textField becomeFirstResponder];
	
	[self->appNavController searchHierachiesForInspector: self->inspector];
	//STAssertTrue([[self->mainPane inspectedObjects] count] == 5, @"Expected to have 5 objects to inspect");
}


@end
