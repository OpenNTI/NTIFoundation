//
//  NTIRTFTextInspectorSlice.h
//  NextThoughtApp
//
//  Created by Christopher Utz on 8/11/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OmniUI/OUIDetailInspectorSlice.h>
#import <OmniUI/OUIEditableFrame.h>

@interface NTIRTFTextInspectorSlice : OUIDetailInspectorSlice
{

}
//We're not allowed to implement init directly. Must 
//use the designated initializer.
-(id)initWithNibName: (NSString*)nibNameOrNil
			  bundle: (NSBundle*)nibBundleOrNil;
@end
