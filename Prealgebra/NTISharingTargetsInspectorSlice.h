//
//  NTINoteInspectorSlice.h
//  NextThoughtApp
//
//  Created by Christopher Utz on 8/11/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "OmniUI/OUIInspector.h"
#import "NTINoteView.h"
#import "NTISharingController.h"
#import "OmniUI/OUIDetailInspectorSlice.h"
#import "OmniUI/OUIInspectorPane.h"
#import "OmniUI/OUIDetailInspectorSlice.h"
#import "OmniFoundation/OmniFoundation.h"

@interface NTISharingTargetsInspectorModel: OFObject{
	
}
-(id)init;
-(id)initWithTargets: (NSArray*)targets readOnly: (BOOL)rOnly;
@property (nonatomic, copy) NSArray* sharingTargets; 
@property (nonatomic, assign) BOOL readOnly;
@end

@interface NTISharingTargetsInspectorSlice : OUIDetailInspectorSlice
{
}
-initWithTitle:(NSString *)title paneMaker: (OUIDetailInspectorSlicePaneMaker)paneMaker;
-(void)setSharingTargets: (NSArray*)targets;
@end
