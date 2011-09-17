//
//  NTIInspector.h
//  NextThoughtApp
//
//  Created by Christopher Utz on 8/12/11.
//  Copyright 2011 NextThought. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "OmniFoundation/OmniFoundation.h"

//A list of the common includes so that everyone doesn't have to 
//repeat them over and over.
#import "OmniUI/OUIInspector.h"
#import "OmniUI/OUIInspectorPane.h"
#import "OmniUI/OUIStackedSlicesInspectorPane.h"
#import "OmniUI/OUIInspectorSlice.h"
#import "OmniUI/OUIDetailInspectorSlice.h"
#import "OmniUI/OUIInspectorWell.h"
#import "OmniUI/OUIEditableTextWellInspectorSlice.h"
#import "OmniUI/OUISingleViewInspectorPane.h"

//An inspector that has a navigation controller to use.
@interface NTINavigableInspector : OUIInspector {
	
}
-(id)init;
-(id)initWithNavigationController: (UINavigationController*)nav;
-(id)initWithMainPane: (OUIInspectorPane*)mainPane
			   height: (CGFloat)height
  navgationController: (UINavigationController*)nav;

@property (nonatomic,readonly) UINavigationController* navigationController;
@end

