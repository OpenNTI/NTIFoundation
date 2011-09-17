//
//  NTIInlineSettingController.h
//  Prealgebra
//
//  Created by Jason Madden on 2011/05/30.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <UIKit/UIKit.h>
@class WebAndToolController;
@class OUIInspectorSelectionValue;
@class OUIColorAttributeInspectorWell;

#define NTI_ISC_TAG_TEXT 42
#define NTI_ISC_TEXT_SMALLER 0
#define NTI_ISC_TEXT_LARGER 1

#define NTI_ISC_TEXT_SERIF 1
#define NTI_ISC_TEXT_SANS_SERIF 0

@interface NTIInlineSettingController : UIViewController {
    @private
	WebAndToolController* webController;
	UISegmentedControl* sizeControl;
	UISwitch* notesControl;
	UISwitch* highlightsControl;
	UISegmentedControl *faceControl;
	
	OUIColorAttributeInspectorWell* textWell;
	OUIInspectorSelectionValue* selectionValue;
}

@property (nonatomic, retain) IBOutlet UISegmentedControl* sizeControl;
@property (nonatomic, retain) IBOutlet UISwitch* notesControl;
@property (nonatomic, retain) IBOutlet UISwitch* highlightsControl;
@property (nonatomic, retain) IBOutlet UISegmentedControl* faceControl;

- (id)initWithNibName: (NSString *)nibNameOrNil
			   bundle: (NSBundle *)nibBundleOrNil
			  webView: (WebAndToolController*)web;

@end
