//
//  NTIAppNavigationControllerTest.m
//  NTIFoundation
//
//  Created by Christopher Utz on 1/31/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIAppNavigationControllerTest.h"
#import "NTIFoundation/NTIFoundation.h"

@interface TestAppLayer : UIViewController<NTIAppNavigationApplicationLayer>
@end

@implementation TestAppLayer
@end

@interface TestTransLayer : UIViewController<NTIAppNavigationTransientLayer>
@end

@implementation TestTransLayer
@end

@interface NTIAppNavigationController(PrivateMessagesToTest)
-(void)bringLayerForward: (id<NTIAppNavigationLayer>)layer animated:(BOOL)animated;
@end


@implementation NTIAppNavigationControllerTest

-(void)setUp
{
	self->rootLayer = [[TestAppLayer alloc] initWithNibName: nil bundle: nil];
	self->appNavController = [[NTIAppNavigationController alloc] 
								initWithRootLayer: (id)self->rootLayer];
}

-(void)testPushingNil
{
	NSArray* layers = self->appNavController.layers;
	[self->appNavController pushLayer: nil animated: NO];
	STAssertEqualObjects(self->appNavController.layers, layers, nil);
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

-(void)testMovingTopAppLayerDoesNothing
{
	id appLayer1 = [[TestAppLayer alloc] initWithNibName: nil bundle: nil];
	id transLayer1 = [[TestTransLayer alloc] initWithNibName: nil bundle: nil];
	id transLayer2 = [[TestTransLayer alloc] initWithNibName: nil bundle: nil];
	id appLayer2 = [[TestAppLayer alloc] initWithNibName: nil bundle: nil];
	
	[self->appNavController pushLayer: appLayer1 animated: NO];
	[self->appNavController pushLayer: transLayer1 animated: NO];
	[self->appNavController pushLayer: transLayer2 animated: NO];
	[self->appNavController pushLayer: appLayer2 animated: NO];
	
	NSArray* layers = [NSArray arrayWithObjects: self->rootLayer, 
					   appLayer1, transLayer1, 
					   transLayer2, appLayer2, nil];
	
	STAssertEqualObjects(self->appNavController.layers, 
						 layers, nil);
	
	[self->appNavController bringLayerForward: appLayer2 animated: YES];
	
	STAssertEqualObjects(self->appNavController.layers, 
						 layers, nil);

}

-(void)testMovingAppLayer
{
	id appLayer1 = [[TestAppLayer alloc] initWithNibName: nil bundle: nil];
	id transLayer1 = [[TestTransLayer alloc] initWithNibName: nil bundle: nil];
	id transLayer2 = [[TestTransLayer alloc] initWithNibName: nil bundle: nil];
	id appLayer2 = [[TestAppLayer alloc] initWithNibName: nil bundle: nil];
	
	[self->appNavController pushLayer: appLayer1 animated: NO];
	[self->appNavController pushLayer: transLayer1 animated: NO];
	[self->appNavController pushLayer: transLayer2 animated: NO];
	[self->appNavController pushLayer: appLayer2 animated: NO];
	
	NSArray* layers = [NSArray arrayWithObjects: self->rootLayer, 
					   appLayer1, transLayer1, 
					   transLayer2, appLayer2, nil];
	
	STAssertEqualObjects(self->appNavController.layers, 
						 layers, nil);
	
	[self->appNavController bringLayerForward: appLayer1 animated: YES];
	
	STAssertEquals(self->appNavController.topApplicationLayer, appLayer1, nil);
	
	layers = [NSArray arrayWithObjects: self->rootLayer, 
			  appLayer2, appLayer1, transLayer1, 
			  transLayer2, nil];
	
	STAssertEqualObjects(self->appNavController.layers, 
						 layers, nil);
	
}

-(void)testMovingTopTransientLayerFromTopAppLayerDoesNothing
{
	id appLayer1 = [[TestAppLayer alloc] initWithNibName: nil bundle: nil];
	id transLayer1B = [[TestTransLayer alloc] initWithNibName: nil bundle: nil];
	id transLayer1M = [[TestTransLayer alloc] initWithNibName: nil bundle: nil];
	id transLayer1T = [[TestTransLayer alloc] initWithNibName: nil bundle: nil];
	id appLayer2 = [[TestAppLayer alloc] initWithNibName: nil bundle: nil];
	id transLayer2B = [[TestTransLayer alloc] initWithNibName: nil bundle: nil];
	id transLayer2M = [[TestTransLayer alloc] initWithNibName: nil bundle: nil];
	id transLayer2T = [[TestTransLayer alloc] initWithNibName: nil bundle: nil];
	
	[self->appNavController pushLayer: appLayer1 animated: NO];
	[self->appNavController pushLayer: transLayer1B animated: NO];
	[self->appNavController pushLayer: transLayer1M animated: NO];
	[self->appNavController pushLayer: transLayer1T animated: NO];
	[self->appNavController pushLayer: appLayer2 animated: NO];
	[self->appNavController pushLayer: transLayer2B animated: NO];
	[self->appNavController pushLayer: transLayer2M animated: NO];
	[self->appNavController pushLayer: transLayer2T animated: NO];
	
	NSArray* layers = [NSArray arrayWithObjects: self->rootLayer, 
					   appLayer1, transLayer1B, transLayer1M, transLayer1T, 
					   appLayer2, transLayer2B, transLayer2M, transLayer2T, nil];
	
	STAssertEqualObjects(self->appNavController.layers, 
						 layers, nil);
	
	[self->appNavController bringLayerForward: transLayer2T animated: YES];
	
	STAssertEqualObjects(self->appNavController.layers, 
						 layers, nil);

}

-(void)testMovingTransientLayer
{
	id appLayer1 = [[TestAppLayer alloc] initWithNibName: nil bundle: nil];
	id transLayer1 = [[TestTransLayer alloc] initWithNibName: nil bundle: nil];
	id transLayer2 = [[TestTransLayer alloc] initWithNibName: nil bundle: nil];
	id appLayer2 = [[TestAppLayer alloc] initWithNibName: nil bundle: nil];
	id transLayer3 = [[TestTransLayer alloc] initWithNibName: nil bundle: nil];
	
	[self->appNavController pushLayer: appLayer1 animated: NO];
	[self->appNavController pushLayer: transLayer1 animated: NO];
	[self->appNavController pushLayer: transLayer2 animated: NO];
	[self->appNavController pushLayer: appLayer2 animated: NO];
	[self->appNavController pushLayer: transLayer3 animated: NO];
	
	NSArray* layers = [NSArray arrayWithObjects: self->rootLayer, 
					   appLayer1, transLayer1, 
					   transLayer2, appLayer2, transLayer3, nil];
	
	STAssertEqualObjects(self->appNavController.layers, 
						 layers, nil);
	
	[self->appNavController bringLayerForward: transLayer1 animated: YES];
	
	STAssertEquals(self->appNavController.topApplicationLayer, appLayer2, nil);
	
	STAssertEqualObjects(self->appNavController.topLayer, transLayer1, nil);
	
	layers = [NSArray arrayWithObjects: self->rootLayer, 
			  appLayer1, transLayer2, appLayer2, transLayer3, 
			  transLayer1, nil];
	
	STAssertEqualObjects(self->appNavController.layers, 
						 layers, nil);

}

@end
