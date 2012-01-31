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

@end
