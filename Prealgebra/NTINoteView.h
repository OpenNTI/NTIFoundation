//
//  NTINoteView.h
//  Prealgebra
//
//  Created by Jason Madden on 2011/06/13.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "NTIViewController.h"
#import <OmniFoundation/OmniFoundation.h>
#import "OmniUI/OUIInspector.h"
#import "NTINoteInspector.h"
#import "NTISharingTargetsInspectorSlice.h"
#import "NTINoteSavingDelegates.h"

@class NTIMiniNoteView;
@class NTINoteView;
@class NTINote;
@class NTIThreadedNoteContainer;
@class NTINoteViewControllerManager;

@interface NSObject(NTIActionRowExtension)
-(UITableViewCell*)actionCell: (id)sender;
-(BOOL)shouldShowActionCell: (id)sender;
@end

#pragma mark model
//Model for an in memory note.
@interface NTIUserAndNote : OFObject
@property (nonatomic,readonly) NSString* user;
@property (nonatomic,assign) NTINote* note;
@property (nonatomic,readonly) NTINoteViewControllerManager* noteManager;
@property (nonatomic,readonly) BOOL shared;
@property (nonatomic,retain) UITapGestureRecognizer* miniTapRecognizer;
+(NTIUserAndNote*)objectWithUser: (id)u andNote: (id)n;
+(NTIUserAndNote*)objectWithNote: (id)n;
-(NSDictionary*)asDictionary;
@end

@interface NTIThreadedNoteContainer : OFObject {
@private
    NTIUserAndNote* uan;
	NTIThreadedNoteContainer* parent;
	NSMutableArray* children;
}
@property (nonatomic, readonly) NTIThreadedNoteContainer* parent;
@property (nonatomic, readonly) NSArray* children;
@property (nonatomic, readonly) NSUInteger level;
@property (nonatomic, readonly) NSUInteger count;
@property (nonatomic, readonly) NTIUserAndNote* uan;
//The item we are "wrapping." This is the same as uan.note, but
//we may have been tricked into wrapping a non-Note. This is called
//Item for compatibility with NTIUserData messages.
@property (nonatomic, readonly) id Item; 
+(NTIThreadedNoteContainer*)pruneContainer: (NTIThreadedNoteContainer*)container;
//Given a set of NTINotes generate the threads and return the root set of NTIThreadedNoteContainer
+(NSArray*)threadNotes: (NSArray*)notesToThread;
//Search predicate for searching a threaded note
+(NSPredicate*)searchPredicate;
-(id)initWithNote: (NTINote*)note;
//Attempts to add the container has some child/subchild of us.  Returns the container
//it was added to or nil.
-(NTIThreadedNoteContainer*)addThreadedNote: (NTIThreadedNoteContainer*)note;
//Removes the threaded note tree from us or some child.  Returns the container it
//was removed from or nil.
-(NTIThreadedNoteContainer*)removeThreadedNote: (NTIThreadedNoteContainer*)note;
//Removes the threaded note tree from us or some child.  Returns the container it
//was updated from or nil.
-(NTIThreadedNoteContainer*)updateThreadedNote: (NTIThreadedNoteContainer*)note;
//Given an id recursively search for the with that OID.  Returns the container or nil
-(NTIThreadedNoteContainer*)findWithID: (NSString*)OID;
//Returns the creator/owner of the container.  Added so context item filtering works
-(NSString*)Creator;
//Determines if the container contains note at some level
-(BOOL)containsNote: (NTINote*)note;
//Determins if the container contains some container at some level
-(BOOL)containsThread: (NTIThreadedNoteContainer*)note;
//Determins if the container is root.  Root containers have no parent
-(BOOL)isRoot;
//Returns the container at the root of the tree containg us
-(NTIThreadedNoteContainer*)root;
//Returns an object at the specified index by way of a DFS
-(NTIThreadedNoteContainer*)objectAtIndex: (NSUInteger)index;
//Are we an empty container (no note) according to http://www.jwz.org/doc/threading.html
-(NSUInteger)indexOfObject: (NTIThreadedNoteContainer*)container;
-(BOOL)isEmptyContainer;
//Return the contained note that was most recently updated
-(NTIThreadedNoteContainer*)lastUpdatedContainer;
-(void)deleteNote;

@end

#pragma mark delegates
@protocol NTINoteActionDelegate<NSObject>
@optional
-(void)reply: (id)sender;
-(void)edit: (id)sender;
-(void)deleteNote: (id)sender;
@end

@protocol NTINoteToolbarDelegate<NSObject>
-(void)done: (id)sender;
-(void)cancel: (id)sender;
-(void)showInspector: (id)sender;
@end

//This delegate allows for ThreadedNoteContainer views such as
//NTIThreadedNoteViewController and NTINoteSummaryView controller
//to update their views when the contained objects change
@protocol NTIThreadedNoteViewControllerDelegate <NSObject>
-(void)removeObjectAtIndexPath: (NSIndexPath*)path;
-(void)updateObject: (id)toUpdate atIndexPath: (NSIndexPath*)path;
-(void)updateObject: (id)toUpdate;
-(void)removeObject: (id)toRemove;
-(void)addObject: (id)toAdd;
@end

#pragma mark view controllers
@interface NTIThreadedNoteViewController: UITableViewController<UITableViewDataSource, UITableViewDelegate, NTINoteActionDelegate, NTINoteSaverDelegateView, NTIThreadedNoteViewControllerDelegate>{
@private
	NTIThreadedNoteContainer* threadedNote;
	NTIThreadedNoteContainer* selected;
	NSString* ntiPageId;
	id<NTIThreadedNoteViewControllerDelegate> nr_container;
}

-(id)initWithThreadedNote: (NTIThreadedNoteContainer*)noteTree onPage:(NSString*)pageId
			  inContainer: (id<NTIThreadedNoteViewControllerDelegate>) parent;
-(CGSize)sizeOfContent;
@property (nonatomic,readonly) NSString* ntiPageId;
@end

@interface NTIThreadedNoteInPageViewController : NTIThreadedNoteViewController {

}
@end

@class NTIRTFTextViewController;
@class NTIRTFDocument;

@interface NTIMiniNoteView : UIView {
	@package
}
@property (retain, nonatomic) IBOutlet UIImageView* backgroundImage;

@end

@interface NTINoteView : UIView {
	@package
	UITapGestureRecognizer* tap;
	UIImageView* background;
}
@property (nonatomic,readonly) UIView* textView;
@property (nonatomic,readonly) UILabel* dateLine;
@property (nonatomic,assign) CGRect prefFrame;
-(CGSize)preferredSize;
@end

@class NTINoteViewControllerManager;
@interface NTIMovableNoteView : NTINoteView {
	@package
	NTINoteViewControllerManager* nr_manager;
}

-(void)hideNote;
-(void)prepareForDragging;
-(void)moveBy: (CGPoint)diff;
@end

@interface NTIBasicNoteViewController : NTIViewController {
	@protected
	NTINote* note;
	id modDateOrNote;
	NTIRTFDocument* document;
	BOOL shared; //TODO: replace with owner
}
@end

@interface NTINoteViewController : NTIBasicNoteViewController {
	@private
	NTINoteInspector* inspector;
	@package
	NTIRTFTextViewController* editViewController;
	BOOL willShowInspector;
	NTINoteViewControllerManager* nr_manager;
	IBOutlet UILabel* dateLine;

	UIView *noteToolBarView;
}
@property (nonatomic, readonly) UIBarButtonItem* leftToolbarItem;
@property (nonatomic, readonly) UIBarButtonItem* rightToolbarItem;
@property (nonatomic, readonly) UIBarButtonItem* infoToolbarItem;
@property (nonatomic, assign) BOOL infoEnabled;
@property (nonatomic, retain) IBOutlet UIView *noteToolBarView;
@property (nonatomic, retain) IBOutlet UIToolbar* noteToolbar;
@property (nonatomic,readonly) NTIRTFTextViewController* editViewController;
@property (nonatomic,readonly) NTINoteView* noteView;
@property (nonatomic,retain) id<NTINoteToolbarDelegate> delegate;
@end

@interface NTIMovableNoteViewController : NTINoteViewController {

}
@property (nonatomic,readonly) NTIMovableNoteView* movableNoteView;
@end

@interface NTIMiniNoteViewController : NTIBasicNoteViewController
@property (nonatomic,readonly) NTIMiniNoteView* miniNoteView;
@end

@protocol NTINoteViewControllerDelegate<NTINoteToolbarDelegate>
@optional
-(void)noteViewControllerManagerWillHideFloatingNote: (NTINoteViewControllerManager*)manager;
@end

/**
 * For the convenience of subclasses, we default to
 * being our own NTIToolbarDelegate.
 */
@interface NTINoteViewControllerManager : OFObject<NTINoteToolbarDelegate> {
	@private
	NTINote* note;
	id modDateOrNote;
	NTIRTFDocument* document;
	NTISharingTargetsInspectorModel* sharingTargetsModel;

	NTIMiniNoteViewController* miniNoteViewController;
	NTIMovableNoteViewController* floatingNoteViewController;
	NTINoteViewController* noteViewController;

	id<NTINoteToolbarDelegate> delegate;
}

+(NTINoteViewControllerManager*)managerForNote: (NTINote*)note;
+(NTINoteViewControllerManager*)managerForNote: (NTINote*)note inReplyTo: (NTINote*) replyTo;


@property (nonatomic,readonly) NTIMiniNoteViewController* miniNoteViewController;
@property (nonatomic,readonly) NTIMovableNoteViewController* floatingNoteViewController;
@property (nonatomic,readonly) NTINoteViewController* noteViewController;

@property (nonatomic,readonly) NTISharingTargetsInspectorModel* sharingTargets;
@property (nonatomic,readonly) NTINote* note;
@property (nonatomic,readonly) NSString* owner;
@property (nonatomic,readonly) NSString* inReplyTo;
@property (nonatomic,readonly) NSArray* references;
@property (nonatomic,readonly) BOOL shared;
@property (nonatomic,readonly,retain) NTIRTFDocument* document;
@property (nonatomic,readonly) NSString* externalString;
@property (nonatomic,readonly) NSString* plainText;
@property (nonatomic,readonly) BOOL hasText;
@property (nonatomic,retain) id<NTINoteToolbarDelegate> delegate;


-(NTINoteViewControllerManager*)copyWithNote: (NTINote*)note;

//For subclasses
-(void)controllerDidLoad: (NTIBasicNoteViewController*)controller;
@end

