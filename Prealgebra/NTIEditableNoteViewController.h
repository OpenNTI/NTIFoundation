//
//  NTINoteController.h
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/12.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OmniUI/OUIInspectorDelegate.h"
#import "NTIViewController.h"
#import "NTIWebContextTableController.h"
//#import "NTIDnDEnabledTableViewController.h"
//#import "NTINoteView.h"
#import "NTINoteSavingDelegates.h"

@protocol NTIThreadedNoteViewControllerDelegate;
@class NTINoteInspector;
@class NTINote;
@class NTINoteController;

@interface NTIEditableNoteViewController : NTIViewController<NTINoteSaverDelegateView> { //Also acts as NTINoteToolbar delegate.
@protected 
	NSString* pageId;
	NSIndexPath* pathAt;
	NTINoteViewControllerManager* noteManager;
	id<NTIThreadedNoteViewControllerDelegate> nr_container;
}
@property (nonatomic,retain) id<NTIThreadedNoteViewControllerDelegate> noteDelegate;
@property (nonatomic,retain) WebAndToolController* web;
@property (nonatomic,readonly) NTINoteViewControllerManager* noteManager;

+(id)controllerForNewNote: (NTINoteViewControllerManager*)manager
				   inPage: (NSString*)page
				container: (id<NTIThreadedNoteViewControllerDelegate>)parent;

+(id)controllerForNewNote: (NTINoteViewControllerManager*)manager
				   inPage: (NSString*)page
				   atPath: (NSIndexPath*)path
				container: (id<NTIThreadedNoteViewControllerDelegate>)parent;
-(void)done: (id)s;
-(NTINote*)noteToSave;
-(NTINote*)noteToCreate;
@end

@interface NTIEditableNoteInPageViewController : NTIEditableNoteViewController<OUIInspectorDelegate,UINavigationControllerDelegate> {
@private
	NTINoteInspector* textInspector;
}
+(id)controllerForNewNote: (NTINoteViewControllerManager*)manager
				   inPage: (NSString*)page;

@end
