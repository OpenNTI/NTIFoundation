//
//  NTIAppNavigationControllerTest.m
//  NTIFoundation
//
//  Created by Christopher Utz on 1/31/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIAppNavigationControllerTest.h"

@interface TestAppLayer : UIViewController<NTIAppNavigationApplicationLayer>
@end

@implementation TestAppLayer
@end

@interface TestTransLayer : UIViewController<NTIAppNavigationTransientLayer>
@end

@implementation TestTransLayer
@end

@interface NTIAppNavigationController(PrivateMessagesToTest)
-(void)bringLayerForward: (id<NTIAppNavigationLayer>)layer;
@end


@implementation NTIAppNavigationControllerTest

-(void)setUp
{
	self->rootLayer = [[TestAppLayer alloc] initWithNibName: nil bundle: nil];
	self->appNavController = [[NTIAppNavigationController alloc] 
								initWithRootLayer: (id)self->rootLayer];
}

-(void)testRootIsTopAndOnlyLayer
{
	STAssertEquals([self->appNavController topLayer], self->rootLayer, nil);
	STAssertEquals([self->appNavController topApplicationLayer], self->rootLayer, nil);
	
	STAssertEquals((int)[self->appNavController layers].count, 1, nil);
	
	STAssertEquals([[self->appNavController layers] lastObjectOrNil], self->rootLayer, nil);
}

-(void)testPushingTransientLayerLeavesTopAppLayer
{
	id currentTopAppLayer = [self->appNavController topApplicationLayer];
	
	id transientToPush = [[TestTransLayer alloc] initWithNibName: nil bundle: nil];
	[self->appNavController pushLayer: transientToPush animated: NO];
	
	STAssertEquals([self->appNavController topApplicationLayer], currentTopAppLayer, nil);
	STAssertEquals([self->appNavController topLayer], transientToPush, nil);
}

-(void)testPoppingRootIsIgnored
{
	NSArray* currentLayers = [self->appNavController layers];
	[self->appNavController popLayerAnimated: NO];
	STAssertEqualObjects([self->appNavController layers], currentLayers, nil);
}

//TODO this can't be run by logic tests.  It does view manipulation which triggers this error.  We may need to setup
//Application test for this project using the sample app?
// 
// 2012-01-31 14:16:57.229 otest[61963:7803] ERROR: System image table has not been initialized. 
// Do not ask for images or set up UI before UIApplicationMain() has been called.


//-(void)testMovingAppLayer
//{
//	id appLayer1 = [[TestAppLayer alloc] initWithNibName: nil bundle: nil];
//	id transLayer1 = [[TestTransLayer alloc] initWithNibName: nil bundle: nil];
//	id transLayer2 = [[TestTransLayer alloc] initWithNibName: nil bundle: nil];
//	id appLayer2 = [[TestAppLayer alloc] initWithNibName: nil bundle: nil];
//	
//	[self->appNavController pushLayer: appLayer1 animated: NO];
//	[self->appNavController pushLayer: transLayer1 animated: NO];
//	[self->appNavController pushLayer: transLayer2 animated: NO];
//	[self->appNavController pushLayer: appLayer2 animated: NO];
//	
//	NSArray* layers = [NSArray arrayWithObjects: self->rootLayer, 
//					   appLayer1, transLayer1, 
//					   transLayer2, appLayer2, nil];
//	
//	STAssertEqualObjects(self->appNavController.layers, 
//						 layers, nil);
//	
//	[self->appNavController bringLayerForward: appLayer1];
//	
//	STAssertEquals(self->appNavController.topApplicationLayer, appLayer1, nil);
//	
//	layers = [NSArray arrayWithObjects: self->rootLayer, 
//			  appLayer2, appLayer1, transLayer1, 
//			  transLayer2, nil];
//	
//	STAssertEqualObjects(self->appNavController.layers, 
//						 layers, nil);
//	
//}

@end
