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
-(void)beginTrackingChanges;
-(void)endTrackingChanges;
@end

@class NTIAppNavigationController;
@protocol NTIAppNavigationLayer <NTIChangeCountTracking>
@optional
//So layers know when they are being shown/hidden in an app controller
-(void)willAppearInAppNavigationControllerAsResultOfPush: (BOOL)pushed;
-(void)didAppearInAppNavigationControllerAsResultOfPush: (BOOL)pushed;
-(void)willDisappearInAppNavigationControllerAsResultOfPush: (BOOL)pushed;
-(void)didDisappearInAppNavigationControllerAsResultOfPush: (BOOL)pushed;

//For cell presentation
-(NSString*)titleForRecentLayerList;
-(UIImage*)imageForRecentLayerList;
//Messages for configuration of the title bar
-(NSString*)textForAppNavigationControllerDownButton: (NTIAppNavigationController*)controller;
-(NSString*)titleForAppNavigationController: (NTIAppNavigationController*)controller;
//Can this layer be moved to the front from somewhere down in the stack.
-(BOOL)canBringToFront;
-(BOOL)shouldAlwaysBringToFront;
//If implemented and non nil an action sheet will be shown if the layer is popped
-(NSString*)poppingLayerWouldBeDestructive;
@end

@protocol NTIAppNavigationApplicationLayer <NTIAppNavigationLayer>
@end

@protocol NTIAppNavigationTransientLayer <NTIAppNavigationLayer>
@optional
-(BOOL)wantsFullScreenLayout;
@end
