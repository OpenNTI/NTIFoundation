//
//  NTINoteController.h
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/12.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NTIViewController.h"
#import "NTIWebContextTableController.h"
#import "NTIEditableNoteViewController.h"
#import "NTIDnDEnabledTableViewController.h"
#import "NTIUserDataTableViewController.h"
#import "NTIUserDataTableModel.h"
#import "NTINoteView.h"
#import "NTINoteSavingDelegates.h"

typedef enum {
	NTINoteTypeContextual,
	NTINoteTypeAnchored,
} NTINoteType;


@interface NTINotesInPageIndicatorController : UIViewController {
@private
	UIView *indicator;
	UIImageView *image;
}
@property (nonatomic, retain) IBOutlet UIImageView *image;
@end

//Needs to be in a navigation controller
@interface NTINoteSummaryViewController : NTIUserDataTableViewController<NTINoteSaverDelegateView, NTIThreadedNoteViewControllerDelegate>
{
	@protected
	NTIThreadedNoteTableModel* model;
	id<NTIThreadedNoteViewControllerDelegate> nr_container;
}
@property (nonatomic,readonly) NSString* ntiPageId;
-(id)initWithModel: (NTIThreadedNoteTableModel*)theModel andParent: (id<NTIThreadedNoteViewControllerDelegate> )pc;
@end

@class WebAndToolController;
@protocol NTINoteSaverDelegateView;
/**
 * Controls three views, a table view that's meant as the "miniview" for 
 * the context column, a scrolling view that's meant as the gutter view
 * for the notes in portrait mode, and a button view used to represent all notes on the page.
 * The table view must be embedded in a navigation
 * controller.
 */
@interface NTINoteController : NTINoteSummaryViewController
			<NTIUserDataTableModelDelegate, NTINoteSaverDelegateView, NTINoteActionDelegate, NTIThreadedNoteViewControllerDelegate> {
	@private
	WebAndToolController* controller;
	NTINoteSummaryViewController* indicatorSummary;
	CGPoint contentOffset;
	UIInterfaceOrientation interfaceOrientation;
	UIPopoverController* miniNotePopoverController;
}

//@property(nonatomic,retain) NSArray* notes;
//@property(nonatomic,readonly) NSString* pageId OB_DEPRECATED_ATTRIBUTE;


-(id)initWithWebController: (WebAndToolController*)controller;

-(void)createNewNote: (id)sender;
-(void)createNewNoteOfType: (NTINoteType)type;
-(void)createNewNoteOfType: (NTINoteType)type inReplyTo: (NTINote*) note;
@end
