//
//  NTINoteController.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/12.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTIEditableNoteViewController.h"

#import "NTINoteLoader.h"
#import "NTINoteView.h"
#import "NTINoteSavingDelegates.h"
#import "NTINoteController.h"
#import "NTIAppPreferences.h"
#import "NTIDraggableTableViewCell.h"
#import "NTIUtilities.h"
#import "NTIWebView.h"
#import "WebAndToolController.h"
#import "OmniFoundation/OFNull.h"
#import "NTIWindow.h"
#import "NTIDraggingUtilities.h"
#import "NSArray-NTIExtensions.h"
#import "NSString-NTIJSON.h"
#import "NTIRTFDocument.h"
#import "NTIRTFTextViewController.h"
#import "OmniUI/OUIEditableFrame.h"
#import "OmniUI/OUIInspector.h"



@implementation NTIEditableNoteViewController
@synthesize noteManager, web, noteDelegate;

+(void)sharedInit: (NTIEditableNoteViewController*)cont
{
	//cont.navigationItem.titleView = cont->noteManager.noteViewController.noteToolBarView;
	cont.modalPresentationStyle = UIModalPresentationFormSheet;
	cont.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;

}


+(id)controllerForNewNote: (NTINoteViewControllerManager*)manager
				   inPage: (NSString*)page
				   atPath: (NSIndexPath*)path
				container: (id<NTIThreadedNoteViewControllerDelegate>)parent
{
	NTIEditableNoteViewController* result = [[[self alloc] init] autorelease];
	result->pageId = [page retain];
	result->nr_container = parent;
	result->pathAt = [path retain];
	result->noteManager = [manager retain];
	[self sharedInit: result];
	return result;
}

+(id)controllerForNewNote: (NTINoteViewControllerManager*)manager
				   inPage: (NSString*)page
				container: (id<NTIThreadedNoteViewControllerDelegate>)parent;
{
	return [NTIEditableNoteViewController controllerForNewNote: manager 
														inPage: page 
														atPath: nil 
													 container: parent];
}

-(void)loadView
{
	[super loadView];
	self.view = self.noteManager.noteViewController.noteView;
	self.noteManager.noteViewController.delegate = (id)self;
	self.view.hidden = NO;
	self.view.alpha = 1.0;
	
	
}

-(NSString*)ntiPageId
{
	return self->pageId;
}

-(UIWindow*)window
{
	return self.view.window;
}

#pragma mark -
#pragma mark UIViewController

-(BOOL)becomeFirstResponder
{
	return [self.view becomeFirstResponder];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return YES;
}


#pragma mark -
#pragma mark Subclass Delegate methods

/**
 * Subclasses may use this to place a value in origNote with
 * settings to propagate to the server.
 */
-(void)willCreateNote
{
	
}

-(void)didCreateNote: (NTINote*)note
{
	
}

-(void)willUpdateOrDeleteNote: (NTINote*)origNote
{
	
}

-(void)note: (NTINote*)origNote didDeleteNote: (NTINote*)note
{
	
}

-(void)note: (NTINote*)origNote didUpdateNote: (NTINote*)note
{
	
}

-(NTINote*)noteToSave
{
	NTINote* noteToSave = [[self.noteManager.note copy] autorelease];
	noteToSave.text = [self.noteManager externalString];
	noteToSave.sharedWith = [[self.noteManager sharingTargets] sharingTargets];
	noteToSave.inReplyTo = [self.noteManager inReplyTo];
	noteToSave.references = [self.noteManager references];
	return noteToSave;
}

-(NTINote*)noteToCreate
{
	NTINote* noteToCreate = [[[NTINote alloc] init] autorelease];
	noteToCreate.text = [self.noteManager externalString];
	noteToCreate.sharedWith = [[self.noteManager sharingTargets] sharingTargets];
	noteToCreate.inReplyTo = [self.noteManager inReplyTo];
	noteToCreate.references = [self.noteManager references];
	return noteToCreate;
}

-(CGPoint)htmlDocumentPointFromWindowPoint: (CGPoint)p
{
	return [self.web.webview htmlDocumentPointFromWindowPoint: p];
}

-(id<NTIThreadedNoteViewControllerDelegate>)parent
{
	return self->nr_container;
}


#pragma mark -
#pragma mark Delegate implementation

-(void)cancel: (id)sender
{
	[self.navigationController popViewControllerAnimated: YES];
}

//TODO don't save new note if it's empty?
-(void)done:(id)_
{
	if( self.noteManager.shared ) {
		[self cancel: _];
	}
	else {
		//FIXME: The text changes, it goes left aligned.
		if(		self.noteManager.note
		   &&	[self->noteManager.externalString isEqual: self.noteManager.note.text] 
		   &&   [self->noteManager.sharingTargets.sharingTargets isEqual: self.noteManager.note.sharedWith] ) {
			[self cancel: _];
		}
		else {
			//Must capture the parent for the block before we pop the 
			//nav controller
			id<NTIThreadedNoteViewControllerDelegate> parent = [self parent];

			if( self.noteManager.note ) {
				[self willUpdateOrDeleteNote: self.noteManager.note];
				[[NTINoteSaverDelegate saverForNote: self.noteManager.note
											 inPage: self
										onCompleted: ^(NTINote* updated)
				  {
					if( updated.LastModified < 0 ) {
						[parent removeObjectAtIndexPath: self->pathAt];	
						[self note: self.noteManager.note didDeleteNote: updated];
					}
					else {
						[parent updateObject: updated atIndexPath: self->pathAt];
						[self note: self.noteManager.note didUpdateNote: updated];
					}
				  }
				  ] 
				 saveNote: [self noteToSave]];
			}
			else {
				[self willCreateNote];
				[[NTINoteSaverDelegate saverForNewNote: self 
											 onCreated: ^(NTINote* created)
				  {
					  [parent addObject: created];
					  [self didCreateNote: created];
				  }]
				 saveNote: [self noteToCreate]];
			}
			
			[self cancel: _];
		}
	}
}

-(void)willHideNote:(id)_
{
	[self done: _];
}

-(void)didDeleteNote:(id)_
{
	OBASSERT_NOT_REACHED( "New notes aren't deletable." );
}

-(void)deleteNote:(id)_
{
	if( !self.noteManager.shared ) {
		[[NTINoteSaverDelegate saverForNote: self.noteManager.note 
									 inPage: self] 
		 deleteNote: self.noteManager.note];
		//[[self parent] removeObjectAtIndexPath: self->pathAt];
	}
	[self cancel: _];
}


-(void)dealloc
{
	[self->pageId release];
	[self->noteManager release];
	[self->web release];
	[super dealloc];
}

@end

@implementation NTIEditableNoteInPageViewController


+(id)controllerForNewNote: (NTINoteViewControllerManager*)manager
				   inPage: (NSString*)page
{
	return [NTIEditableNoteInPageViewController controllerForNewNote: manager inPage: page container: nil];
}

+(id)controllerForNewNote: (NTINoteViewControllerManager*)manager
				   inPage: (NSString*)page
				container:(id<NTIThreadedNoteViewControllerDelegate>)parent
{
	NTIEditableNoteInPageViewController* result = [[[self alloc] init] autorelease];
	result->pageId = [page retain];
	result->noteManager = [manager retain];
	result->nr_container = parent;
	[self sharedInit: result];
	return result;
}

+(id)controllerForNewNote: (NTINoteViewControllerManager*)manager
				   inPage: (NSString*)page
				   atPath: (NSIndexPath*)path
				container: (id<NTIThreadedNoteViewControllerDelegate>)parent
{
	NTIEditableNoteInPageViewController* result = [[[self alloc] init] autorelease];
	result->pageId = [page retain];
	result->nr_container = parent;
	result->pathAt = [path retain];
	result->noteManager = [manager retain];
	[self sharedInit: result];
	return result;
}

- (void)navigationController: (UINavigationController*)navigationController 
	  willShowViewController: (UIViewController*)viewController 
					animated: (BOOL)animated;
{
    if( [viewController isKindOfClass: [OUIInspectorPane class]] ) {
        [(OUIInspectorPane *)viewController inspectorWillShow: self->textInspector];
	}
    
}

-(void)showInspector: (id)sender;
{
	if( !self->textInspector ) {
		self->textInspector = [[NTINoteInspector 
								createNoteInspectorForEmbeddingIn: self.navigationController]
							   retain];
	}
	
	id editor = self.noteManager.noteViewController.editViewController.editor;
	NTISharingTargetsInspectorModel* model = self.noteManager.sharingTargets;
	
	[self->textInspector inspectNoteEditor: editor andSharing: model fromBarButtonItem: nil];
	
	self.navigationController.delegate = self;
	
	[self.navigationController pushViewController: self->textInspector.mainPane
										 animated: YES];
	
}

-(void)dismiss
{
	//Force this because we're having weird issues with not being
	//able to get it back.
	//(TODO: This is probably fixed, verify).
	
	[UIMenuController sharedMenuController].menuVisible = NO;
	[self.web.webview becomeFirstResponder];
	NTI_RELEASE( self->textInspector );
	
}

-(void)done:(id)_
{
	[self->textInspector dismissAnimated: YES];
	[self dismiss];
	[super done: _];	
}

-(void)cancel: (id)sender
{
	[self dismiss];
	[super cancel: sender];
}

@end
