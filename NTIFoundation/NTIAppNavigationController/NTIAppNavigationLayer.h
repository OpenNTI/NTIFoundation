//
//  NTIAppNavigationLayer.h
//  NTIFoundation
//
//  Created by Christopher Utz on 2/1/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NTIAppNavigationController;
@protocol NTIAppNavigationLayer <NSObject>
@optional
//Messages for configuration of the title bar
-(NSString*)textForAppNavigationControllerDownButton: (NTIAppNavigationController*)controller;
-(NSString*)titleForAppNavigationController: (NTIAppNavigationController*)controller;
//Can this layer be moved to the front from somewhere down in the stack.
-(BOOL)canBringToFront;
-(BOOL)shouldAlwaysBringToFront;
//Messages around badging certain ui components to bring background changes to the users attention.
//layers must implement both or none.
-(NSUInteger)outstandingBadgeCount;
-(void)resetBadgeCount;
@end

@protocol NTIAppNavigationApplicationLayer <NTIAppNavigationLayer>
@end

@protocol NTIAppNavigationTransientLayer <NTIAppNavigationLayer>
@end
