//
//  NTIInspector.h
//  NextThoughtApp
//
//  Created by Christopher Utz on 8/12/11.
//  Copyright 2011 NextThought. All rights reserved.
//
#import "NTIInspector.h"
#import "OmniUI/OUIInspector.h"
#import "OmniUI/OUIEditableFrame.h"
#import "OmniFoundation/OmniFoundation.h"

@class NTISharingTargetsInspectorModel;
@interface NTINoteInspector : NTINavigableInspector<OUIInspectorDelegate>

+(id)createNoteInspector;
+(id)createNoteInspectorForEmbeddingIn: (UINavigationController*) controller;
-(BOOL)inspectNoteEditor: (OUIEditableFrame*)editor 
			  andSharing: (NTISharingTargetsInspectorModel*)sharingTargets 
	   fromBarButtonItem: (UIBarButtonItem*)barButton;
@end

