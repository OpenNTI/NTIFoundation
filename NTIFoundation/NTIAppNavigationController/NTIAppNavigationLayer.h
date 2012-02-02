//
//  NTIAppNavigationLayer.h
//  NTIFoundation
//
//  Created by Christopher Utz on 2/1/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import <Foundation/Foundation.h>

//FIXME terriblename
@protocol NTIChangeCountTracking <NSObject>
@optional
-(NSUInteger)changeCountSinceLastReset; //Should be kvo-able
-(void)resetChangeCount;
@end

@class NTIAppNavigationController;
@protocol NTIAppNavigationLayer <NTIChangeCountTracking>
@optional
//Messages for configuration of the title bar
-(NSString*)textForAppNavigationControllerDownButton: (NTIAppNavigationController*)controller;
-(NSString*)titleForAppNavigationController: (NTIAppNavigationController*)controller;
//Can this layer be moved to the front from somewhere down in the stack.
-(BOOL)canBringToFront;
-(BOOL)shouldAlwaysBringToFront;
@end

@protocol NTIAppNavigationApplicationLayer <NTIAppNavigationLayer>
@end

@protocol NTIAppNavigationTransientLayer <NTIAppNavigationLayer>
@end