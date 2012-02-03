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
//For cell presentation
-(NSString*)titleForRecentLayerList;
-(UIImage*)imageForRecentLayerList;
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
@optional
-(BOOL)wantsFullScreenLayout;
@end
